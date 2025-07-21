import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

export const subscribeToPlan = functions.https.onCall(
  async (data, context) => {
    const logErrorToFirestore = async (
      message: string,
      stack: string,
      contextData: Record<string, unknown> = {}
    ) => {
      try {
        await admin.firestore().collection("error_logs").add({
          message,
          stack,
          severity: "error",
          source: "subscribeToPlan",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          contextData: {
            ...contextData,
            userId: context.auth?.uid || null,
            userEmail: context.auth?.token?.email || null,
          },
        });
      } catch (logErr: unknown) {
        console.error("Failed to log error to error_logs:", logErr);
      }
    };

    if (!context.auth) {
      await logErrorToFirestore(
        "Unauthenticated access to subscribeToPlan",
        new Error().stack || ""
      );
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const roles = context.auth.token?.roles || [];
    const allowed = new Set(["hq_owner", "platform_owner", "developer"]);
    const hasAccess = roles.some((r: string) => allowed.has(r));
    if (!hasAccess) {
      await logErrorToFirestore(
        "Permission denied for role",
        new Error().stack || "",
        {roles}
      );
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient role."
      );
    }

    const {
      franchiseId,
      platformPlanId,
      paymentTokenId,
      cardBrand,
      cardLast4,
    } = data;

    if (
      !franchiseId || !platformPlanId || !paymentTokenId ||
      !cardBrand || !cardLast4
    ) {
      await logErrorToFirestore(
        "Missing fields in subscribeToPlan",
        new Error().stack || "",
        {data}
      );
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields."
      );
    }

    try {
      const planSnap = await admin
        .firestore()
        .collection("platform_plans")
        .doc(platformPlanId)
        .get();

      if (!planSnap.exists) {
        await logErrorToFirestore(
          `Plan not found: ${platformPlanId}`,
          new Error().stack || "",
          {platformPlanId}
        );
        throw new functions.https.HttpsError(
          "not-found",
          "Platform plan not found."
        );
      }

      const plan = planSnap.data();
      if (!plan) throw new Error("Plan document unexpectedly empty");

      const subsRef = admin.firestore().collection("franchise_subscriptions");
      const batch = admin.firestore().batch();

      const existing = await subsRef
        .where("franchiseId", "==", franchiseId)
        .where("active", "==", true)
        .get();

      for (const doc of existing.docs) {
        batch.update(doc.ref, {
          active: false,
          status: "cancelled",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      const now = admin.firestore.Timestamp.now();
      const billingDays = plan.billingInterval === "yearly" ? 365 : 30;

      const newSubRef = subsRef.doc();
      batch.set(newSubRef, {
        franchiseId,
        platformPlanId,
        subscribedAt: now,
        startDate: now,
        nextBillingDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + billingDays * 86400000)
        ),
        billingCycleInDays: billingDays,
        billingInterval: plan.billingInterval,
        autoRenew: true,
        priceAtSubscription: plan.price,
        active: true,
        status: "active",
        planSnapshot: {
          name: plan.name,
          description: plan.description,
          features: plan.includedFeatures,
          currency: plan.currency,
          price: plan.price,
          billingInterval: plan.billingInterval,
          isCustom: plan.isCustom,
          planVersion: plan.planVersion ?? "v1",
          maskedCardString: `**** **** **** ${cardLast4}`,
        },
        cardLast4,
        cardBrand,
        paymentTokenId,
      });

      await batch.commit();
      return {success: true};
    } catch (err: unknown) {
      const message =
        err instanceof Error ?
          err.message :
          "Unexpected error in subscribeToPlan";
      const stack = err instanceof Error ? err.stack || "" : "";

      await logErrorToFirestore(message, stack, {
        franchiseId,
        platformPlanId,
        userId: context.auth.uid,
      });

      throw new functions.https.HttpsError(
        "internal",
        "Subscription failed."
      );
    }
  }
);

export const getPlatformPlan = async (
  platformPlanId: string,
  contextMeta: Record<string, unknown> = {}
) => {
  try {
    const doc = await admin
      .firestore()
      .collection("platform_plans")
      .doc(platformPlanId)
      .get();

    if (!doc.exists) return null;
    return {id: doc.id, ...doc.data()};
  } catch (err: unknown) {
    const message =
      err instanceof Error ?
        err.message :
        "Unknown error in getPlatformPlan";
    const stack = err instanceof Error ? err.stack || "" : "";

    await admin.firestore().collection("error_logs").add({
      message,
      stack,
      source: "getPlatformPlan",
      severity: "error",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      contextData: {
        platformPlanId,
        ...contextMeta,
      },
    });
    throw err;
  }
};

export const getFranchise = async (
  franchiseId: string,
  contextMeta: Record<string, unknown> = {}
) => {
  try {
    const doc = await admin
      .firestore()
      .collection("franchises")
      .doc(franchiseId)
      .get();

    if (!doc.exists) return null;
    return {id: doc.id, ...doc.data()};
  } catch (err: unknown) {
    const message =
      err instanceof Error ?
        err.message :
        "Unknown error in getFranchise";
    const stack = err instanceof Error ? err.stack || "" : "";

    await admin.firestore().collection("error_logs").add({
      message,
      stack,
      source: "getFranchise",
      severity: "error",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      contextData: {
        franchiseId,
        ...contextMeta,
      },
    });
    throw err;
  }
};
