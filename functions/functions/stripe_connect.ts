import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import Stripe from "stripe";

/** Returns a Stripe client using STRIPE_SECRET_KEY.
 * @return {Stripe} Configured Stripe client
 */
function getStripe(): Stripe {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "STRIPE_SECRET_KEY is not configured."
    );
  }
  return new Stripe(key, {apiVersion: "2025-02-24.acacia"});
}

/** Ensures the caller is authenticated with an HQ-capable role.
 * @param {functions.https.CallableContext} context Callable context
 * @return {void}
 */
function assertHqAccess(context: functions.https.CallableContext): void {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required."
    );
  }
  const roles: string[] = context.auth.token?.roles || [];
  const allowed = new Set(["hq_owner", "platform_owner", "developer"]);
  if (!roles.some((r) => allowed.has(r))) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Insufficient role."
    );
  }
}

/**
 * Creates (or reuses) a Stripe Connect Express account for the franchise,
 * writes stripeConnectAccountId on franchises/{id}, returns Account Link URL.
 * Does NOT set paymentsEnabled - refreshConnectAccountStatus owns that.
 */
export const createConnectAccountLink = functions
  .runWith({secrets: ["STRIPE_SECRET_KEY"]})
  .https.onCall(async (data, context) => {
    assertHqAccess(context);

    const franchiseId = data?.franchiseId as string | undefined;
    if (!franchiseId || typeof franchiseId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId is required."
      );
    }

    const franchiseRef = admin
      .firestore()
      .collection("franchises")
      .doc(franchiseId);
    const snap = await franchiseRef.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Franchise not found."
      );
    }

    const stripe = getStripe();
    const existing = snap.data()?.stripeConnectAccountId as
      | string
      | undefined;

    let accountId = existing;
    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        capabilities: {
          card_payments: {requested: true},
          transfers: {requested: true},
        },
        metadata: {franchiseId},
      });
      accountId = account.id;
      await franchiseRef.set(
        {
          stripeConnectAccountId: accountId,
          stripeConnectStatus: account.charges_enabled ?
            "enabled" :
            "pending",
          paymentsEnabled: false,
        },
        {merge: true}
      );
    }

    const returnUrl =
      (data?.returnUrl as string) ||
      "https://franchisehq.io/hq/payments/return";
    const refreshUrl =
      (data?.refreshUrl as string) ||
      "https://franchisehq.io/hq/payments/refresh";

    const link = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: "account_onboarding",
    });

    return {url: link.url, accountId};
  });

/**
 * Re-reads Connect account from Stripe and updates franchise doc:
 * stripeConnectStatus + paymentsEnabled (true only when charges_enabled).
 */
export const refreshConnectAccountStatus = functions
  .runWith({secrets: ["STRIPE_SECRET_KEY"]})
  .https.onCall(async (data, context) => {
    assertHqAccess(context);

    const franchiseId = data?.franchiseId as string | undefined;
    if (!franchiseId || typeof franchiseId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId is required."
      );
    }

    const franchiseRef = admin
      .firestore()
      .collection("franchises")
      .doc(franchiseId);
    const snap = await franchiseRef.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Franchise not found."
      );
    }

    const accountId = snap.data()?.stripeConnectAccountId as
      | string
      | undefined;
    if (!accountId) {
      await franchiseRef.set(
        {paymentsEnabled: false, stripeConnectStatus: null},
        {merge: true}
      );
      return {
        paymentsEnabled: false,
        stripeConnectStatus: null,
        stripeConnectAccountId: null,
      };
    }

    const stripe = getStripe();
    const account = await stripe.accounts.retrieve(accountId);
    const paymentsEnabled = account.charges_enabled === true;
    const stripeConnectStatus = paymentsEnabled ?
      "enabled" :
      account.details_submitted ?
        "restricted" :
        "pending";

    await franchiseRef.set(
      {
        paymentsEnabled,
        stripeConnectStatus,
        stripeConnectAccountId: accountId,
      },
      {merge: true}
    );

    return {
      paymentsEnabled,
      stripeConnectStatus,
      stripeConnectAccountId: accountId,
    };
  });

/**
 * Creates a PaymentIntent for a customer card order on the
 * franchise Connect account.
 * @param {Object} data franchiseId, amountCents, currency?,
 *   orderId?, applicationFeeCents?
 * @param {functions.https.CallableContext} context Auth required.
 * @return {Promise<{clientSecret: string,
 *   paymentIntentId: string}>}
 */
export const createOrderPaymentIntent = functions
  .runWith({secrets: ["STRIPE_SECRET_KEY"]})
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const franchiseId = data?.franchiseId as string | undefined;
    const amountCents = data?.amountCents as number | undefined;
    const currency = ((data?.currency as string) || "usd").toLowerCase();
    const orderId = data?.orderId as string | undefined;
    const applicationFeeCents = data?.applicationFeeCents as
      | number
      | undefined;

    if (!franchiseId || typeof franchiseId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId is required."
      );
    }
    if (
      typeof amountCents !== "number" ||
      !Number.isFinite(amountCents) ||
      amountCents < 50
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amountCents must be a number >= 50."
      );
    }

    const franchiseRef = admin
      .firestore()
      .collection("franchises")
      .doc(franchiseId);
    const snap = await franchiseRef.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Franchise not found."
      );
    }

    const doc = snap.data() || {};
    const paymentsEnabled = doc.paymentsEnabled === true;
    const accountId = doc.stripeConnectAccountId as string | undefined;
    if (!paymentsEnabled || !accountId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Payments not set up for this restaurant."
      );
    }

    const stripe = getStripe();
    // Default take-rate: 2.9% of amount if fee not provided (pilot).
    const fee =
      typeof applicationFeeCents === "number" &&
      Number.isFinite(applicationFeeCents) &&
      applicationFeeCents >= 0 ?
        Math.floor(applicationFeeCents) :
        Math.floor(amountCents * 0.029);

    const intent = await stripe.paymentIntents.create({
      amount: Math.floor(amountCents),
      currency,
      automatic_payment_methods: {enabled: true},
      application_fee_amount: fee,
      transfer_data: {destination: accountId},
      metadata: {
        franchiseId,
        orderId: orderId || "",
        uid: context.auth.uid,
      },
    });

    if (!intent.client_secret) {
      throw new functions.https.HttpsError(
        "internal",
        "PaymentIntent missing client_secret."
      );
    }

    return {
      clientSecret: intent.client_secret,
      paymentIntentId: intent.id,
      applicationFeeCents: fee,
    };
  });
