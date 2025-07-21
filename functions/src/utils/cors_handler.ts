// src/utils/cors_handler.ts
import cors from "cors";

export const corsHandler = cors({
  origin: (origin, callback) => {
    const allowedOrigins = [
      "https://franchisehq.io",
      /^http:\/\/localhost(:\d+)?$/,
      /^http:\/\/127\.0\.0\.1(:\d+)?$/,
    ];
    if (
      !origin ||
      allowedOrigins.some((entry) =>
        typeof entry === "string" ? origin === entry : entry.test(origin)
      )
    ) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
});
