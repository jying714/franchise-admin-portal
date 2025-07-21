import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import cors from "cors";

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
