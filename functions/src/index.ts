import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import cors from "cors";
import * as sgMail from "@sendgrid/mail";

// *** REQUIRED: initialize the admin app ***
admin.initializeApp();

const SENDGRID_API_KEY = functions.config().sendgrid.key;
const APP_BASE_URL = "https://franchisehq.io";

const corsHandler = cors({
  origin: (origin, callback) => {
    if (
      !origin ||
      origin === "https://franchisehq.io" ||
      /^http:\/\/localhost(:\d+)?$/.test(origin) ||
      /^http:\/\/127\.0\.0\.1(:\d+)?$/.test(origin)
    ) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
});


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
    if (!roles.some((r) => [
      "platform_owner", "owner", "developer", "admin"].includes(r))) {
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
    if (!roles.some((r) => [
      "platform_owner", "owner", "developer", "admin"].includes(r))) {
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
    if (!callerRoles.some((r) => [
      "platform_owner", "owner", "developer"].includes(r))) {
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
    if (!callerRoles.some((r) => [
      "platform_owner", "owner", "developer", "admin"].includes(r))) {
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

const VALID_ROLES = [
  "platform_owner",
  "hq_owner",
  "owner",
  "developer",
  "admin",
  "manager",
  "staff",
  "customer",
];

const INVITATION_COLLECTION = "franchisee_invitations";

/**
 * Helper: Send onboarding/invite email via SendGrid.
 */
async function sendOnboardingEmail({
  email,
  inviteUrl,
  franchiseName,
  isNewUser,
  token,
}: {
  email: string;
  inviteUrl: string;
  franchiseName?: string;
  isNewUser: boolean;
  token: string;
}) {
  sgMail.setApiKey(SENDGRID_API_KEY);

  const subject = isNewUser ?
    "You're invited to join the Franchise Portal" :
    "Access granted: Franchise Admin Portal";

  const html = `
  <div style="font-family: Arial, sans-serif;
   max-width: 500px; margin: 0 auto;">
    <h2>Welcome to the Franchise Admin Portal!</h2>
    <p>
      You've been invited to join as ${
  franchiseName ?
    `the owner of <b>${franchiseName}</b>` :
    "a franchisee"
}.
    </p>
    <p>
      Click the button below to ${
  isNewUser ? "set your password and " : ""
}accept your invitation and get started:
    </p>
    <a href="${inviteUrl}"
      style="display:inline-block;background:#008CBA;color:#fff;
      padding:12px 30px;margin:18px 0;border-radius:5px;
      text-decoration:none;font-weight:bold;">
      Accept Invitation
    </a>
    <p>
      If the button above doesn't work, copy and
       paste this link into your browser:
    </p>
    <p style="word-break:break-all;">${inviteUrl}</p>
    <p>
      If you have questions, reply to this email or contact our support team.
    </p>
    <p style="color: #888;">
      This invite was intended for ${email}. If you didn't expect this,
      you can safely ignore it.
    </p>
    <hr/>
    <small>Invite code: ${token}</small>
  </div>
`;


  await sgMail.send({
    to: email,
    from: {
      name: "Joshua Yingling",
      email: "JoshuaYingling@FranchiseHQ.io", // <-- Change this!
    },
    subject,
    html,
  });
}

/**
 * Callable function to invite a new user by email,
 *  send onboarding invite, and track status.
 */
export const inviteAndSetRole = functions.https.onCall(
  async (data, context) => {
    // --- Permission check ---
    if (
      !context.auth ||
      !context.auth.token ||
      !(
        context.auth.token.roles &&
        Array.isArray(context.auth.token.roles) &&
        context.auth.token.roles.some((r) =>
          ["platform_owner", "owner", "developer", "admin"].includes(r)
        )
      )
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only platform owners, admins, owners, or developers can invite users."
      );
    }

    // --- Input validation ---
    const {email, password, role, franchiseName, brandId, ...extraMeta} = data;

    if (!email || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Email and role are required."
      );
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
        (err).code === "auth/user-not-found"
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

        // (Optional) Send password reset link for onboarding
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
              (err).message :
              String(err))
        );
      }
    }

    // --- Set custom claims ---
    await admin.auth().setCustomUserClaims(userRecord.uid, {roles: [role]});

    // --- Write/merge user doc in 'users' ---
    const userDocRef = admin.firestore().collection("users")
      .doc(userRecord.uid);
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
      const docData = userDoc.data() || {};
      const roles = Array.isArray(docData.roles) ? docData.roles : [];
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

    // --- Generate a secure invite token ---
    const token = admin.firestore().collection(INVITATION_COLLECTION).doc().id;
    const inviterUserId = context.auth.uid;
    const now = admin.firestore.FieldValue.serverTimestamp();
    // Add expiresAt (7 days from now)
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 1000 * 60 * 60 * 24 * 7)
    );

    // --- Build onboarding invite link (front-end route must handle this) ---
    const inviteUrl = `${APP_BASE_URL}/invite-accept?token=${token}`;

    // --- Create invitation record in Firestore ---
    const invitationDoc = {
      email,
      role,
      inviterUserId,
      invitedUserId: userRecord.uid,
      status: "pending",
      token,
      createdAt: now,
      lastSentAt: now,
      isNewUser,
      inviteUrl,
      expiresAt, // <-- Added expiry here
      ...(franchiseName && {franchiseName}),
      ...(brandId && {brandId}),
      ...extraMeta,
    };

    await admin
      .firestore()
      .collection(INVITATION_COLLECTION)
      .doc(token)
      .set(invitationDoc, {merge: true});

    // --- Send onboarding/invite email ---
    try {
      await sendOnboardingEmail({
        email,
        inviteUrl,
        franchiseName,
        isNewUser,
        token,
      });
    } catch (emailErr) {
      console.error("Failed to send onboarding/invite email:", emailErr);
      // Optionally: Mark invite as failed-to-send in Firestore
    }

    // --- Return result ---
    return {
      status: "ok",
      uid: userRecord.uid,
      role,
      isNewUser,
      token,
      inviteUrl,
    };
  }
);


// === Revocation Function ===
/**
 * Callable function to revoke an invitation (by token).
 * Sets status to 'revoked'. Only privileged roles can revoke.
 */
export const revokeInvitation = functions.https.onCall(
  async (data, context) => {
    if (
      !context.auth ||
      !context.auth.token ||
      !(
        context.auth.token.roles &&
        Array.isArray(context.auth.token.roles) &&
        context.auth.token.roles.some((r) =>
          ["platform_owner", "owner", "developer", "admin"].includes(r)
        )
      )
    ) {
      throw new functions.https.HttpsError(
        "permission-denied", "Insufficient privileges");
    }
    const {token} = data;
    if (!token) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Token required.");
    }
    await admin.firestore().collection(INVITATION_COLLECTION).doc(
      token).update({
      status: "revoked",
      revokedAt: admin.firestore.FieldValue.serverTimestamp(),
      revokedBy: context.auth.uid,
    });
    return {status: "ok", token};
  }
);

// === Acceptance Function ===
/**
 * Callable function to accept an invitation by token.
 * Sets status to 'accepted', updates user doc.
 */
export const acceptInvitation = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "Authentication required."
      );
    }
    const {token} = data;
    if (!token) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Token required."
      );
    }
    // Fetch invite doc
    const inviteDocRef = admin.firestore()
      .collection(INVITATION_COLLECTION)
      .doc(token);
    const inviteDoc = await inviteDocRef.get();
    if (!inviteDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found", "Invitation not found."
      );
    }
    const inviteData = inviteDoc.data();
    if (!inviteData) {
      throw new functions.https.HttpsError(
        "not-found", "Invitation not found."
      );
    }
    // --- Expiry logic ---
    if (
      inviteData.expiresAt &&
      inviteData.expiresAt.toDate() < new Date()
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition", "Invitation has expired."
      );
    }
    if (inviteData.status === "revoked") {
      throw new functions.https.HttpsError(
        "failed-precondition", "Invitation has been revoked."
      );
    }
    if (inviteData.status === "accepted") {
      throw new functions.https.HttpsError(
        "already-exists", "Invitation has already been accepted."
      );
    }
    // Mark invitation as accepted
    await inviteDocRef.update({
      status: "accepted",
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedBy: context.auth.uid,
    });
    // Update user doc
    const userDocRef = admin.firestore()
      .collection("users")
      .doc(context.auth.uid);
    await userDocRef.set(
      {
        status: "active",
        invitationAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    return {status: "ok", token};
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
          ["platform_owner", "owner", "developer", "admin"].includes(r)
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

interface ErrorLogEntry {
  message: string;
  stack?: string;
  contextData?: Record<string, unknown>;
  source?: string;
  severity?: string;
  screen?: string;
  userId?: string | null;
  userEmail?: string | null;
  createdAt?: FirebaseFirestore.FieldValue;
  env?: string;
}

export const logPublicError = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
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
});

export const logAppError = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const {
      message,
      stack,
      contextData,
      source,
      severity,
      screen,
      userId,
      userEmail,
    } = req.body;

    if (!message || typeof message !== "string") {
      res.status(400).send("Bad Request: Missing or invalid \"message\"");
      return;
    }

    // Optional: severity and source validation
    const allowedSeverities = new Set(["info", "warning", "error", "fatal"]);
    const allowedSources = new Set(
      ["FlutterError", "runZonedGuarded", "UI", "Network", "BusinessLogic"]);

    const entry: ErrorLogEntry = {
      message,
      stack: typeof stack === "string" ? stack : "",
      contextData:
        contextData && typeof contextData === "object" ? contextData : {},
      source: allowedSources.has(source) ? source : "unknown",
      severity: allowedSeverities.has(severity) ? severity : "error",
      screen: typeof screen === "string" ? screen : "",
      userId: typeof userId === "string" ? userId : null,
      userEmail: typeof userEmail === "string" ? userEmail : null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      env: process.env.FUNCTIONS_EMULATOR ? "emulator" : "production",
    };

    try {
      await admin.firestore().collection("error_logs").add(entry);
      res.status(200).send("Logged");
    } catch (err) {
      console.error("Failed to write to error_logs:", err);
      res.status(500).send("Internal Server Error");
    }
  });
});
