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

  const ordersSnapshot = await ordersRef.where(
    "createdAt", ">=", weekAgo).get();

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
 * Scheduled function to roll up analytics weekly for all franchises.
 * Runs every Sunday at 3AM UTC.
 * @returns {Promise<null>}
 */
export const scheduledWeeklyAnalyticsRollup = functions
  .region("us-central1")
  .pubsub.schedule("0 3 * * 0")
  .timeZone("UTC")
  .onRun(async (): Promise<null> => {
    const franchisesSnapshot = await admin
      .firestore()
      .collection("franchises")
      .get();
    const franchiseIds = franchisesSnapshot.docs.map((doc) => doc.id);

    for (const franchiseId of franchiseIds) {
      try {
        await runAnalyticsRollupForFranchise(franchiseId);
      } catch (e) {
        console.error(`[Rollup] Error for franchise ${franchiseId}:`, e);
      }
    }
    return null;
  });

/**
 * Callable HTTPS function: roll up analytics for a franchise on demand.
 * Only accessible by owner, developer, or admin roles.
 * @param data.franchiseId - ID of franchise to roll up analytics for.
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
    const roles: string[] = context.auth.token.roles || [];
    if (!roles.some((r) => ["owner", "developer", "admin"].includes(r))) {
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

/**
 * Returns next monthly period string and start/end timestamps.
 * @return {{period: string, startDate: FirebaseFirestore.Timestamp,
 *  endDate: FirebaseFirestore.Timestamp}} Object with period,
 *  startDate, endDate properties.
 */
function getNextPeriod(): {
  period: string;
  startDate: FirebaseFirestore.Timestamp;
  endDate: FirebaseFirestore.Timestamp;
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
 * @param {string} franchiseId - Franchise to forecast.
 * @return {Promise<void>}
 */
async function runCashFlowForecastForFranchise(
  franchiseId: string
): Promise<void> {
  const {period, startDate, endDate} = getNextPeriod();

  const analyticsRef = admin
    .firestore()
    .collection("franchises")
    .doc(franchiseId)
    .collection("analytics_summaries");

  const summariesSnap = await analyticsRef
    .orderBy("period", "desc")
    .limit(3)
    .get();

  let totalInflow = 0;
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

  let openingBalance = 0;
  const lastForecastSnap = await admin
    .firestore()
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

  const forecastRef = admin
    .firestore()
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
 * Scheduled function to run cash flow forecast monthly.
 * Runs 1st of each month at 4AM UTC.
 * @returns {Promise<null>}
 */
export const scheduledMonthlyCashFlowForecast = functions
  .region("us-central1")
  .pubsub.schedule("0 4 1 * *")
  .timeZone("UTC")
  .onRun(async (): Promise<null> => {
    const franchisesSnapshot = await admin
      .firestore()
      .collection("franchises")
      .get();
    const franchiseIds = franchisesSnapshot.docs.map((doc) => doc.id);

    for (const franchiseId of franchiseIds) {
      try {
        await runCashFlowForecastForFranchise(franchiseId);
      } catch (e) {
        console.error(`[Forecast] Error for franchise ${franchiseId}:`, e);
      }
    }
    return null;
  });


/**
 * Callable HTTPS function for manual cash flow forecast runs.
 * Only accessible by owner, developer, or admin roles.
 * @param data.franchiseId - ID of franchise.
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
    const roles: string[] = context.auth.token.roles || [];
    if (!roles.some((r) => ["owner", "developer", "admin"].includes(r))) {
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

/**
 * Trigger: on user creation, sets custom claims based on Firestore roles.
 * Creates user profile if missing.
 */
export const setClaimsOnUserCreate = functions.auth.user().onCreate(
  async (user) => {
    const uid = user.uid;
    const email = user.email || "";
    let roles = ["customer"];

    // Try to fetch roles from Firestore profile
    let userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (userDoc.exists && userDoc.data()?.roles?.length > 0) {
      roles = userDoc.data()?.roles || ["customer"];
    }

    // Create user profile if missing
    if (!userDoc.exists) {
      await admin.firestore().collection("users").doc(uid).set(
        {
          email,
          roles,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
      userDoc = await admin.firestore().collection("users").doc(uid).get();
    }

    // Set custom user claims with roles array
    await admin.auth().setCustomUserClaims(uid, {roles});
    console.log(
      `[setClaimsOnUserCreate] Set custom claims
       and created profile for ${uid}:`,
      roles
    );
  }
);

/**
 * Callable function to set custom claims for all existing users.
 * Only callable by owner or developer roles.
 */
export const setClaimsForExistingUsers = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }
    const callerRoles: string[] = context.auth.token.roles || [];
    if (!callerRoles.some((r) => ["owner", "developer"].includes(r))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Must be owner or developer."
      );
    }

    let nextPageToken: string | undefined = undefined;
    do {
      const list = await admin.auth().listUsers(1000, nextPageToken);
      for (const user of list.users) {
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(user.uid)
          .get();
        let roles = ["customer"];
        if (userDoc.exists && userDoc.data()?.roles?.length > 0) {
          roles = userDoc.data()?.roles || ["customer"];
        }
        await admin.auth().setCustomUserClaims(user.uid, {roles});
        console.log(
          `[setClaimsForExistingUsers] Set claims for ${user.email}:`,
          roles
        );
      }
      nextPageToken = list.pageToken;
    } while (nextPageToken);

    return {status: "ok"};
  }
);

/**
 * Firestore trigger: syncs custom claims on user role update.
 */
export const syncClaimsOnUserRoleChange = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const after = change.after.data();
    if (!after) return;

    const roles = after.roles && after.roles.length > 0 ? after.roles : [
      "customer"];
    await admin.auth().setCustomUserClaims(userId, {roles});
    console.log(
      `[syncClaimsOnUserRoleChange] Synced claims for ${userId}:`, roles);
  });

/**
 * Callable function to set a user's roles.
 * Can accept single role string or array of roles.
 * Only callable by owner, developer, or admin.
 */
export const setUserRole = functions.https.onCall(
  async (
    data: { uid?: string; roles?: string[]; role?: string },
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "Must be signed in.");
    }
    const callerRoles: string[] = context.auth.token.roles || [];
    if (!callerRoles.some((r) => ["owner", "developer", "admin"].includes(r))) {
      throw new functions.https.HttpsError(
        "permission-denied", "Insufficient privileges.");
    }

    const {uid, roles, role} = data;

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument", "uid is required.");
    }

    let rolesToSet: string[];
    if (roles && Array.isArray(roles) && roles.length > 0) {
      rolesToSet = roles;
    } else if (role && typeof role === "string") {
      rolesToSet = [role];
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument", "role or roles array required.");
    }

    await admin.auth().setCustomUserClaims(uid, {roles: rolesToSet});
    await admin.firestore().collection("users")
      .doc(uid).set({roles: rolesToSet}, {merge: true});

    return {status: "ok", uid, roles: rolesToSet};
  }
);

/**
 * Callable function to invite a new user by email.
 * Creates the user if they don't exist, sets role and sends invite.
 * Only callable by owner, developer, or admin.
 */
const VALID_ROLES = [
  "owner",
  "developer",
  "admin",
  "manager",
  "staff",
  "customer",
];

export const inviteAndSetRole = functions.https.onCall(
  async (data, context) => {
    if (
      !context.auth ||
      !context.auth.token ||
      !(
        context.auth.token.roles &&
        Array.isArray(context.auth.token.roles) &&
        context.auth.token.roles.some((r) =>
          ["owner", "developer", "admin"].includes(r)
        )
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
        "invalid-argument", "Email and role are required.");
    }

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
      if (
        typeof err === "object" &&
        err !== null &&
        "code" in err &&
        (err as { code?: string }).code === "auth/user-not-found"
      ) {
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
              (err as { message?: string }).message :
              String(err))
        );
      }
    }

    await admin.auth().setCustomUserClaims(userRecord.uid, {roles: [role]});

    const userDocRef = admin.firestore().collection(
      "users").doc(userRecord.uid);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      await userDocRef.set(
        {
          email,
          roles: [role],
          status: "invited",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    } else {
      const data = userDoc.data() || {};
      const roles = Array.isArray(data.roles) ? data.roles : [];
      if (!roles.includes(role)) {
        roles.push(role);
      }
      await userDocRef.set(
        {
          roles,
          status: "invited",
        },
        {merge: true}
      );
    }

    return {
      status: "ok",
      uid: userRecord.uid,
      role,
      isNewUser,
    };
  }
);

/**
 * Callable function to ensure user profile exists.
 * Only callable by owner, developer, or admin.
 * @param data.uid - User ID
 * @param data.email - User email
 * @param data.role - Optional role (defaults to customer)
 */
export const ensureUserProfile = functions.https.onCall(
  async (data, context) => {
    if (
      !context.auth ||
      !context.auth.token ||
      !(
        context.auth.token.roles &&
        Array.isArray(context.auth.token.roles) &&
        context.auth.token.roles.some((r) =>
          ["owner", "developer", "admin"].includes(r)
        )
      )
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Must be owner, developer, or admin."
      );
    }
    const {uid, email, role} = data;
    if (!uid || !email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid and email are required."
      );
    }
    const userDocRef = admin.firestore().collection("users").doc(uid);
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
      await userDocRef.set(
        {
          email,
          roles: [role || "customer"],
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
      return {created: true};
    }
    return {created: false};
  }
);

export const logPublicError = functions.https.onRequest(
  async (req, res): Promise<void> => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const {message, stack, contextData} = req.body;

    if (!message) {
      res.status(400).send("Bad Request: Missing message");
      return;
    }

    try {
      await admin.firestore().collection("public_error_logs").add({
        message,
        stack: stack || "",
        contextData: contextData || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "landing_page",
      });
      res.status(200).send("Logged");
    } catch (e) {
      console.error("Failed to log public error:", e);
      res.status(500).send("Internal Server Error");
    }
  });
