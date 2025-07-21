import * as admin from "firebase-admin";

// *** REQUIRED: initialize the admin app ***
admin.initializeApp();

export {subscribeToPlan} from "../functions/subscriptions";
export {getFranchise, getPlatformPlan} from "../functions/subscriptions";
export {scheduledWeeklyAnalyticsRollup, rollupAnalyticsOnDemand,
} from "../functions/analytics";
export {
  scheduledMonthlyCashFlowForecast,
  forecastCashFlowOnDemand,
} from "../functions/forecast";
export {
  setClaimsOnUserCreate,
  setClaimsForExistingUsers,
  syncClaimsOnUserRoleChange,
  setUserRole,
  updateUserClaims,
  ensureUserProfile,
} from "../functions/userClaims";
export {
  inviteAndSetRole,
  acceptInvitation,
  revokeInvitation,
} from "../functions/invitations";
export {logAppError, logPublicError} from "../functions/errors";
export {
  scheduledGenerateMonthlyPlatformInvoices,
  generatePlatformInvoiceOnDemand,
} from "../functions/invoices";

