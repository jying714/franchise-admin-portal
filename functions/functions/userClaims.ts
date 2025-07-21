import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

type Claims = {
  defaultFranchise?: string;
  [key: string]: unknown;
};

type FirestoreUpdate = {
  roles: string[];
  franchiseIds: string[];
  updatedAt: FirebaseFirestore.FieldValue;
  defaultFranchise?: string;
};

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

export const updateUserClaims = functions.https.onCall(
  async (data, context) => {
    const {uid, roles, franchiseIds, additionalClaims} = data;

    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be signed in."
      );
    }

    const callerRoles = context.auth.token.roles || [];
    if (!hasPrivilegedRole(callerRoles)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient privileges."
      );
    }

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing uid."
      );
    }

    // ✅ Typed & sanitized additional claims
    const sanitizedClaims: Claims = {...(additionalClaims ?? {})};
    if ("franchiseId" in sanitizedClaims) {
      console.warn(
        `⚠️ Stripping out 'franchiseId' from additionalClaims for user: ${uid}`
      );
      delete sanitizedClaims.franchiseId;
    }

    // ✅ Safely resolve roles
    let rolesToUse = roles;
    if (!rolesToUse) {
      const userDoc = await admin.firestore().collection(
        "users").doc(uid).get();
      rolesToUse = userDoc.data()?.roles ?? [];
      console.log(
        `[updateUserClaims] No roles provided; using existing: ${
          JSON.stringify(rolesToUse)}`);
    } else {
      console.log(
        `[updateUserClaims] Using provided roles: ${
          JSON.stringify(rolesToUse)}`);
    }

    // ✅ Set custom user claims
    await admin.auth().setCustomUserClaims(uid, {
      roles: rolesToUse,
      franchiseIds: franchiseIds ?? [],
      ...sanitizedClaims,
    });

    // ✅ Build safe Firestore update object
    const firestoreUpdate: FirestoreUpdate = {
      roles: rolesToUse,
      franchiseIds: franchiseIds ?? [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (sanitizedClaims.defaultFranchise) {
      firestoreUpdate.defaultFranchise =
       sanitizedClaims.defaultFranchise as string;
    }

    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .set(firestoreUpdate, {merge: true});

    return {status: "ok", uid};
  }
);

/**
 * Checks whether the user has a privileged role.
 * @param {string[]} roles - Array of user roles.
 * @return {boolean} True if user has at least one privileged role.
 */
function hasPrivilegedRole(roles: string[]): boolean {
  const allowed = new Set([
    "platform_owner",
    "developer",
    "hq_owner",
    "hq_manager",
    "admin",
  ]);
  return roles.some((role) => allowed.has(role));
}
