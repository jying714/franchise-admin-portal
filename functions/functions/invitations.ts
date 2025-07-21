import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import sgMail from "@sendgrid/mail";

const APP_BASE_URL = "https://franchisehq.io";
const SENDGRID_API_KEY = functions.config().sendgrid.key;

// eslint-disable-next-line @typescript-eslint/no-var-requires

const INVITATION_COLLECTION = "franchisee_invitations";

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

/**
 * Callable function to invite a new user by email,
 * send onboarding invite, and track status.
 * Sends both a password reset and onboarding link in one email.
 */
export const inviteAndSetRole = functions.https.onCall(
  async (data, context) => {
    console.log("inviteAndSetRole: called with data:", data);
    console.log(
      "inviteAndSetRole: context.auth:",
      JSON.stringify(context.auth)
    );

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
      console.error(
        "inviteAndSetRole: Permission denied for context.auth:",
        context.auth
      );
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only platform owners, admins, owners, or developers can invite users."
      );
    }

    // --- Input validation ---
    const {email, role, franchiseName, brandId, ...extraMeta} = data;

    if (!email || !role) {
      console.error(
        "inviteAndSetRole: Missing email or role", {email, role, data});
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and role are required."
      );
    }
    if (!VALID_ROLES.includes(role)) {
      console.error("inviteAndSetRole: Invalid role", {role, VALID_ROLES});
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Role "${role}" is not permitted.`
      );
    }

    // --- User creation/check ---
    let userRecord;
    let isNewUser = false;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      isNewUser = false;
      console.log(
        "inviteAndSetRole: Existing user found",
        {uid: userRecord.uid, email}
      );
    } catch (err) {
      console.warn(
        "inviteAndSetRole: getUserByEmail error", {error: err, email}
      );
      if (
        typeof err === "object" &&
        err !== null &&
        "code" in err &&
        err.code === "auth/user-not-found"
      ) {
        // Create user with no password. Password will be set via reset link.
        try {
          userRecord = await admin.auth().createUser({
            email,
            // DO NOT set password here; will force user to use reset link.
          });
          isNewUser = true;
          console.log("inviteAndSetRole: Created new user",
            {uid: userRecord.uid, email});
        } catch (createErr) {
          console.error("inviteAndSetRole: Failed to create user",
            {error: createErr, email});
          throw new functions.https.HttpsError(
            "internal",
            "Error creating new user: " +
              (typeof createErr === "object" &&
                createErr !== null && "message" in createErr ?
                createErr.message :
                String(createErr))
          );
        }
      } else {
        console.error(
          "inviteAndSetRole: Unexpected error fetching/creating user",
          {error: err}
        );
        throw new functions.https.HttpsError(
          "internal",
          "Error fetching or creating user: " +
            (typeof err === "object" && err !== null && "message" in err ?
              err.message :
              String(err))
        );
      }
    }

    // --- Generate password reset link (ALWAYS send this) ---
    let passwordResetLink: string | null = null;
    try {
      passwordResetLink = await admin.auth().generatePasswordResetLink(email);
      console.log(
        "inviteAndSetRole: Generated password reset link",
        {email, passwordResetLink}
      );
    } catch (emailErr) {
      console.error(
        "inviteAndSetRole: Failed to generate password reset link:",
        emailErr
      );
    }

    // --- Set custom claims ---
    try {
      await admin.auth().setCustomUserClaims(userRecord.uid, {roles: [role]});
      console.log("inviteAndSetRole: Set custom claims for user",
        {uid: userRecord.uid, role});
    } catch (claimsErr) {
      console.error("inviteAndSetRole: Failed to set custom claims",
        {error: claimsErr, uid: userRecord.uid});
      throw new functions.https.HttpsError(
        "internal",
        "Failed to set custom claims: " +
          (typeof claimsErr === "object" && claimsErr !== null &&
             "message" in claimsErr ?
            claimsErr.message :
            String(claimsErr))
      );
    }

    // --- Write/merge user doc in 'users' ---
    const userDocRef = admin.firestore().collection(
      "users").doc(userRecord.uid);
    let userDoc;
    try {
      userDoc = await userDocRef.get();
      console.log("inviteAndSetRole: Fetched user doc",
        {exists: userDoc.exists, uid: userRecord.uid});
    } catch (firestoreGetErr) {
      console.error("inviteAndSetRole: Error reading user doc",
        {error: firestoreGetErr, uid: userRecord.uid});
      throw new functions.https.HttpsError(
        "internal",
        "Error reading user doc: " +
          (typeof firestoreGetErr === "object" && firestoreGetErr !==
             null && "message" in firestoreGetErr ?
            firestoreGetErr.message :
            String(firestoreGetErr))
      );
    }

    if (!userDoc.exists) {
      try {
        await userDocRef.set(
          {
            email,
            roles: [role],
            status: "invited",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true}
        );
        console.log("inviteAndSetRole: Created new user doc",
          {uid: userRecord.uid});
      } catch (setUserDocErr) {
        console.error("inviteAndSetRole: Error creating user doc",
          {error: setUserDocErr, uid: userRecord.uid});
        throw new functions.https.HttpsError(
          "internal",
          "Error creating user doc: " +
            (typeof setUserDocErr === "object" && setUserDocErr !==
               null && "message" in setUserDocErr ?
              setUserDocErr.message :
              String(setUserDocErr))
        );
      }
    } else {
      const docData = userDoc.data() || {};
      const roles = Array.isArray(docData.roles) ? docData.roles : [];
      if (!roles.includes(role)) {
        roles.push(role);
      }
      try {
        await userDocRef.set(
          {
            roles,
            status: "invited",
          },
          {merge: true}
        );
        console.log("inviteAndSetRole: Updated roles/status in user doc",
          {uid: userRecord.uid, roles});
      } catch (updateUserDocErr) {
        console.error("inviteAndSetRole: Error updating user doc",
          {error: updateUserDocErr, uid: userRecord.uid});
        throw new functions.https.HttpsError(
          "internal",
          "Error updating user doc: " +
            (typeof updateUserDocErr === "object" && updateUserDocErr !==
               null && "message" in updateUserDocErr ?
              updateUserDocErr.message :
              String(updateUserDocErr))
        );
      }
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
    const inviteUrl = `${APP_BASE_URL}/#/invite-accept?token=${token}`;
    console.log("inviteAndSetRole: Prepared invitation URL",
      {inviteUrl, token});

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
      expiresAt,
      ...(franchiseName && {franchiseName}),
      ...(brandId && {brandId}),
      ...extraMeta,
      passwordResetLink, // ADDED for debugging/tracing
    };

    try {
      await admin
        .firestore()
        .collection(INVITATION_COLLECTION)
        .doc(token)
        .set(invitationDoc, {merge: true});
      console.log("inviteAndSetRole: Wrote invitation doc", {token, email});
    } catch (invitationDocErr) {
      console.error("inviteAndSetRole: Failed to create invitation doc",
        {error: invitationDocErr, token, email});
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create invitation doc: " +
          (typeof invitationDocErr === "object" &&
             invitationDocErr !== null && "message" in invitationDocErr ?
            invitationDocErr.message :
            String(invitationDocErr))
      );
    }

    // --- Send onboarding/invite email with BOTH links ---
    try {
      await sendOnboardingEmail({
        email,
        inviteUrl,
        franchiseName,
        isNewUser,
        token,
        passwordResetLink: passwordResetLink ?? undefined,
      });
      console.log(
        "inviteAndSetRole: Sent onboarding/invite email with links",
        {email, inviteUrl, passwordResetLink}
      );
    } catch (emailErr) {
      console.error(
        "inviteAndSetRole: Failed to send onboarding/invite email:",
        emailErr
      );
      // Optionally: Mark invite as failed-to-send in Firestore
    }

    // --- Return result ---
    console.log("inviteAndSetRole: SUCCESS", {
      status: "ok",
      uid: userRecord.uid,
      role,
      isNewUser,
      token,
      inviteUrl,
      passwordResetLink,
    });
    return {
      status: "ok",
      uid: userRecord.uid,
      role,
      isNewUser,
      token,
      inviteUrl,
      passwordResetLink,
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
    // OPTIONAL: Add franchiseId to user's profile and
    //  custom claims if available in invitation
    if (inviteData.franchiseId) {
      const franchiseId = inviteData.franchiseId;
      const userRef = admin.firestore().collection(
        "users").doc(context.auth.uid);

      // Update Firestore user doc
      await userRef.set(
        {
          franchiseIds: admin.firestore.FieldValue.arrayUnion(franchiseId),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      // Fetch current roles (preserve existing roles)
      const userDoc = await userRef.get();
      let roles = userDoc.data()?.roles ?? [];

      if (!Array.isArray(roles) || roles.length === 0) {
        if (typeof inviteData.role === "string" && inviteData.role.length > 0) {
          roles = [inviteData.role];
          console.log(
            "[acceptInvitation] No roles in user doc, using invite role:",
            roles);
        } else {
          roles = ["customer"]; // fallback only if inviteData.role is absent
          console.warn(
            "[acceptInvitation] No roles found. Defaulting to customer.");
        }

        // 🔄 Write roles back to Firestore immediately to sync
        await userRef.set({roles}, {merge: true});
      }

      // Set custom claims
      await admin.auth().setCustomUserClaims(context.auth.uid, {
        roles,
        franchiseIds: [franchiseId],
      });


      console.log(`[acceptInvitation] Finalized user setup:
  uid=${context.auth.uid},
  roles=${JSON.stringify(roles)},
  franchiseIds=[${franchiseId}]
`);
    }
    return {status: "ok", token};
  }
);

/**
 * Helper: Send onboarding/invite email via SendGrid.
 * Distinguishes new vs. existing users, and includes onboarding/password links.
 */
async function sendOnboardingEmail({
  email,
  inviteUrl,
  franchiseName,
  isNewUser,
  token,
  passwordResetLink,
}: {
  email: string;
  inviteUrl: string;
  franchiseName?: string;
  isNewUser: boolean;
  token: string;
  passwordResetLink?: string;
}) {
  sgMail.setApiKey(SENDGRID_API_KEY);

  let subject = "You're invited to join the Franchise Admin Portal";
  let instructions = "";

  if (isNewUser && passwordResetLink) {
    subject = "Set your password to activate your FranchiseHQ account";
    instructions += `
      <p>
        <b>Step 1:</b> 
        <a href="${passwordResetLink}" style="
          color: #008CBA; text-decoration: underline; font-weight: bold;">
          Set your password
        </a>
        (required for your first login).
      </p>
      <p>
        <b>Step 2:</b> 
        After setting your password, please
        <a href="${inviteUrl}" style="
          color: #008CBA; text-decoration: underline; font-weight: bold;">
          accept your invitation here
        </a>
        to begin onboarding.
      </p>
    `;
  } else {
    subject = "Access granted: Franchise Admin Portal";
    instructions += `
      <p>
        Click the button below to accept your invitation:
      </p>
      <a href="${inviteUrl}" style="
        display:inline-block;background:#008CBA;color:#fff;
        padding:12px 30px;margin:18px 0;border-radius:5px;
        text-decoration:none;font-weight:bold;">
        Accept Invitation
      </a>
    `;
  }

  const html = `
    <div style="font-family: Arial, sans-serif;
      max-width: 500px; margin: 0 auto;">
      <h2>Welcome to the Franchise Admin Portal!</h2>
      <p>
        You've been invited to join ${
  franchiseName ?
    `as the owner of <b>${franchiseName}</b>` :
    "the Franchise Admin Portal"
}.
      </p>
      ${instructions}
      <p>
        If a link above doesn't work, copy and paste it into your browser.
      </p>
      <p>
        <b>Onboarding Link:</b><br/>
        <span style="word-break:break-all;">${inviteUrl}</span>
      </p>
      ${
  isNewUser && passwordResetLink ?
    `<p>
              <b>Password Setup Link:</b><br/>
              <span style="word-break:break-all;">
                ${passwordResetLink}
              </span>
            </p>` :
    ""
}
      <p>
        For help, reply to this email or contact support.
      </p>
      <p style="color: #888;">
        This invite was intended for ${email}.
        If you did not expect it, you can ignore it.
      </p>
      <hr/>
      <small>Invite code: ${token}</small>
    </div>
  `;

  await sgMail.send({
    to: email,
    from: {
      name: "Joshua Yingling",
      email: "JoshuaYingling@FranchiseHQ.io",
    },
    subject,
    html,
  });
}
