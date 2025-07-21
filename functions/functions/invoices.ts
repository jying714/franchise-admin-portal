import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import sgMail from "@sendgrid/mail";
const SENDGRID_API_KEY = functions.config().sendgrid.key;

/**
 * Scheduled Function: Generate monthly platform invoices from subscriptions.
 * Runs on the 1st of each month at 2AM UTC.
 */
export const scheduledGenerateMonthlyPlatformInvoices = functions
  .region("us-central1")
  .pubsub.schedule("0 5 1 * *") // 5AM UTC on the 1st of every month
  .timeZone("UTC")
  .onRun(async (): Promise<null> => {
    const firestore = admin.firestore();
    const subsSnap = await firestore.collection(
      "franchise_subscriptions").get();
    const timestamp = admin.firestore.Timestamp.now();
    const jsNow = new Date();

    for (const doc of subsSnap.docs) {
      const data = doc.data();
      const planId = data.platformPlanId;
      const franchiseId = data.franchiseId;
      const price = typeof data.price === "number" ? data.price : null;
      const discount = data.discountPercent || 0;
      const subId = doc.id;

      if (!planId || !franchiseId || !price) {
        console.warn(`[Invoice Skipped] Invalid data for sub ${subId}`);
        continue;
      }

      const discounted = price * (1 - discount / 100);

      // 1. Create invoice document
      const invoiceRef = firestore.collection("platform_invoices").doc();
      await invoiceRef.set({
        franchiseeId: franchiseId,
        invoiceNumber: `INV-${subId}-${Date.now()}`,
        amount: discounted,
        currency: "USD",
        createdAt: timestamp,
        dueDate: admin.firestore.Timestamp.fromDate(
          new Date(jsNow.getTime() + 1000 * 60 * 60 * 24 * 14) // +14 days
        ),
        status: "unpaid",
        issuedBy: "platform",
        planId,
        isTest: false,
      });

      // 2. Update the nextBillingDate in the subscription
      await doc.ref.update({
        nextBillingDate: admin.firestore.Timestamp.fromDate(
          new Date(jsNow.getTime() + 1000 * 60 * 60 * 24 * 30) // +30 days
        ),
      });

      // 3. Notify the franchise owner by email
      try {
        const usersSnap = await firestore
          .collection("users")
          .where("franchiseIds", "array-contains", franchiseId)
          .limit(1)
          .get();

        if (!usersSnap.empty) {
          const owner = usersSnap.docs[0].data();
          const email = owner.email;
          const name = owner.name || "Franchise Owner";

          const message = {
            to: email,
            from: {
              name: "FranchiseHQ Billing",
              email: "billing@franchisehq.io",
            },
            subject: "Your Monthly Platform Invoice is Ready",
            html: `
              <p>Hi ${name},</p>
              <p>Your invoice for <strong>${
  planId}</strong> has been generated on ${jsNow.toLocaleDateString()}.</p>
              <p><strong>Amount:</strong> $${discounted.toFixed(2)}<br/>
              <strong>Due Date:</strong> ${new Date(
    jsNow.getTime() + 1000 * 60 * 60 * 24 * 14).toLocaleDateString()}</p>
              <p>Please log in to your FranchiseHQ account
               to view or pay this invoice.</p>
              <p>Thank you,<br/>The FranchiseHQ Team</p>
            `,
          };

          sgMail.setApiKey(SENDGRID_API_KEY);
          await sgMail.send(message);
          console.log(`[Email ✅] Sent to ${email} for sub ${subId}`);
        } else {
          console.warn(
            `[Email ⚠️] No owner found for franchise ${franchiseId}`);
        }
      } catch (e) {
        console.error(`[Email ❌] Failed to send for sub ${subId}:`, e);
      }

      console.log(
        `[Invoice ✅] Franchise: ${franchiseId},
         Sub: ${subId}, Amount: $${discounted.toFixed(2)}`
      );
    }

    return null;
  });

export const generatePlatformInvoiceOnDemand = functions.https.onCall(
  async (
    data: { franchiseId?: string },
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "Must be signed in.");
    }

    const callerRoles: string[] = context.auth.token.roles || [];
    if (!callerRoles.some((r) =>
      ["platform_owner", "developer", "admin", "owner"].includes(r)
    )) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient privileges."
      );
    }

    const {franchiseId} = data;
    if (!franchiseId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId is required."
      );
    }

    const firestore = admin.firestore();
    const subsSnap = await firestore
      .collection("franchise_subscriptions")
      .where("franchiseId", "==", franchiseId)
      .get();

    if (subsSnap.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "No subscriptions found for this franchise."
      );
    }

    const timestamp = admin.firestore.Timestamp.now();
    const jsNow = new Date();
    const createdInvoiceIds: string[] = [];

    for (const doc of subsSnap.docs) {
      const data = doc.data();
      const planId = data.platformPlanId;
      const price = typeof data.price === "number" ? data.price : null;
      const discount = data.discountPercent || 0;
      const subId = doc.id;

      if (!planId || !price) continue;
      const discounted = price * (1 - discount / 100);

      const invoiceRef = firestore.collection("platform_invoices").doc();
      await invoiceRef.set({
        franchiseeId: franchiseId,
        invoiceNumber: `INV-${subId}-${Date.now()}`,
        amount: discounted,
        currency: "USD",
        createdAt: timestamp,
        dueDate: admin.firestore.Timestamp.fromDate(
          new Date(jsNow.getTime() + 1000 * 60 * 60 * 24 * 14)
        ),
        status: "unpaid",
        issuedBy: "platform",
        planId,
        isTest: false,
      });

      await doc.ref.update({
        nextBillingDate: admin.firestore.Timestamp.fromDate(
          new Date(jsNow.getTime() + 1000 * 60 * 60 * 24 * 30)
        ),
      });

      createdInvoiceIds.push(invoiceRef.id);
    }

    return {
      status: "ok",
      franchiseId,
      createdInvoices: createdInvoiceIds,
    };
  }
);
