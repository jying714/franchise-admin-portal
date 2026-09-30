import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

type RangeMode = "radius" | "driveTime";

interface StoreOpsRange {
  deliveryEnabled?: boolean;
  deliveryRangeMode?: string;
  deliveryRadiusMiles?: number;
  deliveryMaxDriveMinutes?: number;
  storeLatitude?: number;
  storeLongitude?: number;
  storeAddress?: string;
}

/**
 * Callable: estimate drive time / distance for delivery gate.
 * Auth required. Key never leaves the function.
 *
 * data: {
 *   franchiseId: string,
 *   destinationAddress: string,  // full street, city, state zip
 * }
 */
export const estimateDeliveryRange = functions
  .runWith({secrets: ["GOOGLE_MAPS_API_KEY"]})
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const franchiseId = data?.franchiseId as string | undefined;
    const destinationAddress =
      (data?.destinationAddress as string | undefined)?.trim() || "";

    if (!franchiseId || typeof franchiseId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "franchiseId is required."
      );
    }
    if (!destinationAddress) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "destinationAddress is required."
      );
    }

    const key = process.env.GOOGLE_MAPS_API_KEY;
    if (!key) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "GOOGLE_MAPS_API_KEY is not configured."
      );
    }

    const opsSnap = await admin
      .firestore()
      .collection("franchises")
      .doc(franchiseId)
      .collection("config")
      .doc("store_ops")
      .get();
    const ops = (opsSnap.data() || {}) as StoreOpsRange;

    if (ops.deliveryEnabled !== true) {
      return {
        deliveryEnabled: false,
        withinRange: false,
        reason: "delivery_disabled",
      };
    }

    const mode: RangeMode =
      ops.deliveryRangeMode === "driveTime" ? "driveTime" : "radius";
    const maxMiles =
      typeof ops.deliveryRadiusMiles === "number" ?
        ops.deliveryRadiusMiles :
        0;
    const maxMinutes =
      typeof ops.deliveryMaxDriveMinutes === "number" ?
        ops.deliveryMaxDriveMinutes :
        0;

    // Origin: explicit lat/lng on store_ops, else storeAddress,
    // else franchise doc fields.
    let originParam = "";
    if (
      typeof ops.storeLatitude === "number" &&
      typeof ops.storeLongitude === "number"
    ) {
      originParam = `${ops.storeLatitude},${ops.storeLongitude}`;
    } else if (
      typeof ops.storeAddress === "string" &&
      ops.storeAddress.trim()
    ) {
      originParam = ops.storeAddress.trim();
    } else {
      const frSnap = await admin
        .firestore()
        .collection("franchises")
        .doc(franchiseId)
        .get();
      const fr = frSnap.data() || {};
      // HQ Contact tab: address is a map { street, city, state, zip }.
      const addr =
        fr.address && typeof fr.address === "object" ?
          (fr.address as Record<string, unknown>) :
          null;
      const parts = [
        addr?.street ?? fr.street ?? fr.publicAddress,
        addr?.city ?? fr.city,
        addr?.state ?? fr.state,
        addr?.zip ?? addr?.postalCode ?? fr.zip ?? fr.postalCode,
      ]
        .filter((p) => typeof p === "string" && (p as string).trim())
        .map((p) => (p as string).trim());
      originParam = parts.join(", ");
    }

    if (!originParam) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Store origin address is not configured."
      );
    }

    // 0 = not enforced for that mode.
    if (mode === "radius" && maxMiles <= 0) {
      return {
        deliveryEnabled: true,
        mode,
        withinRange: true,
        reason: "not_enforced",
      };
    }
    if (mode === "driveTime" && maxMinutes <= 0) {
      return {
        deliveryEnabled: true,
        mode,
        withinRange: true,
        reason: "not_enforced",
      };
    }

    const url = new URL(
      "https://maps.googleapis.com/maps/api/distancematrix/json"
    );
    url.searchParams.set("origins", originParam);
    url.searchParams.set("destinations", destinationAddress);
    url.searchParams.set("mode", "driving");
    url.searchParams.set("units", "imperial");
    url.searchParams.set("key", key);

    const resp = await fetch(url.toString());
    if (!resp.ok) {
      throw new functions.https.HttpsError(
        "internal",
        `Distance Matrix HTTP ${resp.status}`
      );
    }
    const body = await resp.json() as {
      status: string;
      error_message?: string;
      rows?: Array<{
        elements: Array<{
          status: string;
          duration?: {value: number; text: string};
          distance?: {value: number; text: string};
        }>;
      }>;
    };

    if (body.status !== "OK") {
      throw new functions.https.HttpsError(
        "internal",
        body.error_message || `Distance Matrix status ${body.status}`
      );
    }

    const el = body.rows?.[0]?.elements?.[0];
    if (!el || el.status !== "OK") {
      return {
        deliveryEnabled: true,
        mode,
        withinRange: false,
        reason: "route_unavailable",
        elementStatus: el?.status || "missing",
      };
    }

    const durationSeconds = el.duration?.value ?? 0;
    const distanceMeters = el.distance?.value ?? 0;
    const durationMinutes = Math.ceil(durationSeconds / 60);
    const distanceMiles = distanceMeters / 1609.344;

    let withinRange = true;
    if (mode === "radius") {
      withinRange = distanceMiles <= maxMiles;
    } else {
      withinRange = durationMinutes <= maxMinutes;
    }

    return {
      deliveryEnabled: true,
      mode,
      withinRange,
      durationMinutes,
      distanceMiles: Math.round(distanceMiles * 10) / 10,
      durationText: el.duration?.text || null,
      distanceText: el.distance?.text || null,
      maxMiles,
      maxMinutes,
    };
  });
