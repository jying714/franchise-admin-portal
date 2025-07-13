import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// *** REQUIRED: initialize the admin app ***
admin.initializeApp();

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
    `[Rollup] Franchise ${franchiseId}: totalOrders=${totalOrders},` +
    ` totalRevenue=${totalRevenue}`
  );
}

/**
 * Scheduled: every Sunday at 3AM UTC for all franchises.
 */
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

/**
 * Callable HTTPS function: admin/dev/owner only.
 */
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

// -------------------- CASH FLOW FORECAST LOGIC -------------------------

/**
 * Gets the next period in YYYY-MM format and the start/end dates.
 * @return {{period: string, startDate: FirebaseFirestore.Timestamp,
 * endDate: FirebaseFirestore.Timestamp}}
 */
function getNextPeriod(): {
  period: string,
  startDate: FirebaseFirestore.Timestamp,
  endDate: FirebaseFirestore.Timestamp
  } {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = now.getUTCMonth();
  const nextMonth = month === 11 ? 0 : month + 1;
  const nextYear = month === 11 ? year + 1 : year;
  const periodStr = `${nextYear}-${String(nextMonth + 1).padStart(2, "0")}`;

  const startDate = admin.firestore.Timestamp.fromDate(
    new Date(Date.UTC(nextYear, nextMonth, 1))
  );
  const endDate = admin.firestore.Timestamp.fromDate(
    new Date(Date.UTC(nextYear, nextMonth + 1, 0, 23, 59, 59))
  );

  return {period: periodStr, startDate, endDate};
}

/**
 * Runs a cash flow forecast for a given franchise and writes to Firestore.
 * @param {string} franchiseId
 * @return {Promise<void>}
 */
async function runCashFlowForecastForFranchise(
  franchiseId: string
): Promise<void> {
  const {period, startDate, endDate} = getNextPeriod();

  // Get average inflow (revenue) from last 3 analytics summaries
  const analyticsRef = admin.firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("analytics_summaries");

  const summariesSnap = await analyticsRef
    .orderBy("period", "desc")
    .limit(3)
    .get();

  let totalInflow = 0;
  // Use const as totalOutflow is not reassigned
  const totalOutflow = 0;
  let count = 0;

  summariesSnap.forEach((doc) => {
    const data = doc.data();
    if (typeof data.totalRevenue === "number") {
      totalInflow += data.totalRevenue;
    }
    count += 1;
  });

  const avgInflow = count ? totalInflow / count : 0;
  const avgOutflow = count ? totalOutflow / count : 0;

  // Get latest closing balance from last forecast (or set to 0)
  let openingBalance = 0;
  const lastForecastSnap = await admin.firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("cash_flow_forecasts")
    .orderBy("period", "desc")
    .limit(1)
    .get();

  if (!lastForecastSnap.empty) {
    const lastData = lastForecastSnap.docs[0].data();
    if (typeof lastData.projectedClosingBalance === "number") {
      openingBalance = lastData.projectedClosingBalance;
    }
  }

  const projectedClosing = openingBalance + avgInflow - avgOutflow;

  // Write forecast doc
  const forecastRef = admin.firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("cash_flow_forecasts")
    .doc(period);

  await forecastRef.set({
    franchiseId,
    period,
    openingBalance,
    projectedInflow: avgInflow,
    projectedOutflow: avgOutflow,
    projectedClosingBalance: projectedClosing,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    forecastSource: "auto",
    note: "Auto-generated from analytics summaries.",
    forecastVersion: 1,
    startDate,
    endDate,
  });

  console.log(
    `[Forecast] Franchise ${franchiseId}, period ${period}: ` +
    `inflow=${avgInflow}, outflow=${avgOutflow}, ` +
    `opening=${openingBalance}, closing=${projectedClosing}`
  );
}

/**
 * Scheduled: every month at 4AM UTC for all franchises.
 */
export const scheduledMonthlyCashFlowForecast = functions
  .region("us-central1")
  .pubsub.schedule("0 4 1 * *") // 1st of every month at 4AM UTC
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
        await runCashFlowForecastForFranchise(franchiseId);
      } catch (e) {
        console.error(
          `[Forecast] Error for franchise ${franchiseId}:`, e
        );
      }
    }
    return null;
  });

/**
 * Callable HTTPS function for manual/QA runs.
 */
export const forecastCashFlowOnDemand = functions.https.onCall(
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
    await runCashFlowForecastForFranchise(franchiseId);
    return {status: "ok", franchiseId};
  }
);

export const setRoleOnUserCreate = functions.auth.user()
  .onCreate(async (user) => {
  // Look up user profile in Firestore (top-level users collection)
    const userDoc = await admin.firestore()
      .collection("users").doc(user.uid).get();
    let role: string | undefined = undefined;

    // Try franchise-based user if not found at top level
    if (!userDoc.exists) {
    // Optionally: scan franchise subcollections if needed
      const franchisesSnap = await admin.firestore()
        .collection("franchises").get();
      for (const franchise of franchisesSnap.docs) {
        const subUserDoc = await admin
          .firestore()
          .collection("franchises")
          .doc(franchise.id)
          .collection("users")
          .doc(user.uid)
          .get();
        if (subUserDoc.exists) {
        // If found, use this role
          const data = subUserDoc.data();
          if (data?.roles?.length) role = data.roles[0];
          else if (data?.role) role = data.role;
          break;
        }
      }
    } else {
    // Use top-level user
      const data = userDoc.data();
      if (data?.roles?.length) role = data.roles[0];
      else if (data?.role) role = data.role;
    }

    // Default fallback (if not set, make them 'admin'
    // or something else appropriate)
    if (!role) {
      role = "admin";
    }

    // Set the custom claim
    await admin.auth().setCustomUserClaims(user.uid, {role});

    console.log(`Set custom claim for user ${user.email}: role=${role}`);
  });

export const setClaimsOnUserCreate = functions.auth.user()
  .onCreate(async (user) => {
    const uid = user.uid;
    const email = user.email || "";
    let role = "customer";

    // 1. Try to fetch role from Firestore profile
    let userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (userDoc.exists && userDoc.data()?.roles?.length > 0) {
      role = userDoc.data()?.roles[0] || "customer";
    }

    // 2. If no Firestore user profile, CREATE IT
    if (!userDoc.exists) {
      await admin.firestore().collection("users").doc(uid).set({
        email,
        roles: [role],
        status: "active", // or "invited" or whatever is default
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      // Immediately set userDoc for further steps
      userDoc = await admin.firestore().collection("users").doc(uid).get();
    }

    // 3. Set custom user claims
    await admin.auth().setCustomUserClaims(uid, {role});
    console.log(`[setClaimsOnUserCreate] Set custom claims
       and created profile for ${uid}:`, role);
  });


export const setClaimsForExistingUsers = functions.https.onCall(
  async (data, context) => {
    if (!context.auth || !["owner", "developer"]
      .includes(context.auth.token.role)) {
      throw new functions.https.HttpsError(
        "permission-denied", "Must be owner or developer.");
    }

    let nextPageToken: string | undefined = undefined;
    do {
      const list = await admin.auth().listUsers(1000, nextPageToken);
      for (const user of list.users) {
        const userDoc = await admin.firestore()
          .collection("users").doc(user.uid).get();
        let role = "customer";
        if (userDoc.exists && userDoc.data()?.roles?.length > 0) {
          role = userDoc.data()?.roles[0];
        }
        await admin.auth().setCustomUserClaims(user.uid, {role});
        console.log(
          `[setClaimsForExistingUsers] Set claims for ${user.email}: ${role}`);
      }
      nextPageToken = list.pageToken;
    } while (nextPageToken);

    return {status: "ok"};
  });

export const syncClaimsOnUserRoleChange = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const after = change.after.data();
    if (!after) return;
    // Use first role, or adjust for your logic
    const role =
    (after.roles && after.roles.length > 0) ? after.roles[0] : "customer";
    await admin.auth().setCustomUserClaims(userId, {role});
    console.log(`[syncClaimsOnUserRoleChange] Synced claims
       for ${userId}: ${role}`);
  });

export const setUserRole = functions.https.onCall(
  async (
    data: { uid?: string; role?: string },
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "Must be signed in.");
    }
    const callerRole = context.auth.token.role;
    if (!["owner", "developer", "admin"].includes(callerRole)) {
      throw new functions.https.HttpsError(
        "permission-denied", "Insufficient privileges.");
    }
    const {uid, role} = data;
    if (!uid || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument", "uid and role required.");
    }
    await admin.auth().setCustomUserClaims(uid, {role});
    await admin.firestore().collection("users")
      .doc(uid).set({role}, {merge: true});
    return {status: "ok", uid, role};
  }
);

/**
 * Callable Function: Invite a user
 * (create user by email if not exists) and set their role.
 * Only callable by an owner, developer, or admin.
 */
const VALID_ROLES = ["owner", "developer", "admin",
  "manager", "staff", "customer"];

export const inviteAndSetRole = functions.https.onCall(
  async (data, context) => {
    // Security: Only allow privileged users to invite
    if (
      !context.auth ||
      !context.auth.token ||
      !(
        context.auth.token.role === "owner" ||
        context.auth.token.role === "developer" ||
        context.auth.token.role === "admin"
      )
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins, owners, or developers can invite users."
      );
    }

    const {email, password, role} = data;
    if (!email || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and role are required."
      );
    }

    // Validate that the passed role is in the allowed list
    if (!VALID_ROLES.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Role "${role}" is not permitted.`
      );
    }

    let userRecord;
    let isNewUser = false;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (err) {
      if (typeof err === "object" && err !== null && "code" in err && (
        err as { code?: string }).code === "auth/user-not-found") {
        if (!password) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Password required for new user invite."
          );
        }
        userRecord = await admin.auth().createUser({
          email,
          password,
        });
        isNewUser = true;

        // Send password reset link (invite email)
        try {
          await admin.auth().generatePasswordResetLink(email);
        } catch (emailErr) {
          console.error("Failed to send password reset link:", emailErr);
        }
      } else {
        throw new functions.https.HttpsError(
          "internal",
          "Error fetching or creating user: " +
            (typeof err === "object" && err !== null && "message" in err ?
              (err as { message?: string }).message : String(err))
        );
      }
    }

    // Set custom user claims
    await admin.auth().setCustomUserClaims(userRecord.uid, {role});

    // Create/update Firestore user profile
    const userDocRef = admin.firestore()
      .collection("users").doc(userRecord.uid);
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
      await userDocRef.set({
        email,
        roles: [role],
        status: "invited",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    } else {
      // Ensure 'invited' status and role is present in roles array
      const data = userDoc.data() || {};
      const roles = Array.isArray(data.roles) ? data.roles : [];
      if (!roles.includes(role)) {
        roles.push(role);
      }
      await userDocRef.set({
        roles,
        status: "invited",
      }, {merge: true});
    }

    return {
      status: "ok",
      uid: userRecord.uid,
      role,
      isNewUser,
    };
  }
);

export const ensureUserProfile = functions.https.onCall(
  async (data, context) => {
    if (!context.auth || !["owner", "developer", "admin"]
      .includes(context.auth.token.role)) {
      throw new functions.https.HttpsError(
        "permission-denied", "Must be owner, developer, or admin.");
    }
    const {uid, email, role} = data;
    if (!uid || !email) {
      throw new functions.https.HttpsError(
        "invalid-argument", "uid and email are required.");
    }
    const userDocRef = admin.firestore().collection("users").doc(uid);
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
      await userDocRef.set({
        email,
        roles: [role || "customer"],
        status: "active",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return {created: true};
    }
    return {created: false};
  }
);
