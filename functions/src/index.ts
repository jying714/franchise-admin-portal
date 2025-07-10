import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Rolls up analytics for a given franchise (weekly summary).
 * @param {string} franchiseId - The franchise ID to roll up analytics for.
 * @return {Promise<void>}
 */
async function runAnalyticsRollupForFranchise(
  franchiseId: string
): Promise<void> {
  const ordersRef = admin
    .firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("orders");

  const now = admin.firestore.Timestamp.now();
  const weekAgo = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - 7 * 24 * 60 * 60 * 1000
  );

  const ordersSnapshot = await ordersRef
    .where("createdAt", ">=", weekAgo)
    .get();

  let totalRevenue = 0;
  let totalOrders = 0;

  ordersSnapshot.forEach((doc) => {
    const data = doc.data();
    if (typeof data.total === "number") {
      totalRevenue += data.total;
      totalOrders += 1;
    }
  });

  const analyticsRef = admin
    .firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("analytics_summaries")
    .doc("weekly");

  await analyticsRef.set({
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    totalRevenue,
    totalOrders,
    period: "weekly",
    startDate: weekAgo,
    endDate: now,
  });

  console.log(
    `[Rollup] Franchise ${franchiseId}: totalOrders=${totalOrders},
     totalRevenue=${totalRevenue}`
  );
}

// SCHEDULED: every Sunday at 3AM UTC for all franchises (classic v1 API)
export const scheduledWeeklyAnalyticsRollup = functions
  .region("us-central1")
  .pubsub.schedule("0 3 * * 0")
  .timeZone("UTC")
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  .onRun(async (_context) => {
    const franchisesSnapshot = await admin
      .firestore()
      .collection("franchises")
      .get();
    const franchiseIds = franchisesSnapshot.docs.map((doc) => doc.id);

    for (const franchiseId of franchiseIds) {
      try {
        await runAnalyticsRollupForFranchise(franchiseId);
      } catch (e) {
        console.error(
          `[Rollup] Error for franchise ${franchiseId}:`,
          e
        );
      }
    }
    return null;
  });

// Callable HTTPS function: admin/dev/owner only
export const rollupAnalyticsOnDemand = functions.https.onCall(
  async (
    data: { franchiseId?: string },
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }
    const role = context.auth.token.role;
    if (!["owner", "developer", "admin"].includes(role)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient privileges"
      );
    }

    const franchiseId = data.franchiseId;
    if (!franchiseId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId required"
      );
    }
    await runAnalyticsRollupForFranchise(franchiseId);
    return {status: "ok", franchiseId};
  }
);
