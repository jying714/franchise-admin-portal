import { initializeApp } from "firebase/app";
import { getFunctions, httpsCallable } from "firebase/functions";
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";

// Your Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyBBlWVSua4QfPefy4TRPmOT_7ErfgAuZZ4",
  authDomain: "doughboyspizzeria-2b3d2.firebaseapp.com",
  projectId: "doughboyspizzeria-2b3d2",
  storageBucket: "doughboyspizzeria-2b3d2.firebasestorage.app",
  messagingSenderId: "739021537990",
  appId: "1:739021537990:web:2e5cd605ce92e912fe0dc7",
  measurementId: "G-YLJEF3MQYE"
};

// Initialize Firebase app, auth, and functions
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app);

// Sign in user
signInWithEmailAndPassword(auth, "your-test-email@example.com", "your-password")
  .then(userCredential => {
    console.log("Signed in as:", userCredential.user.email);

    const rollupAnalyticsOnDemand = httpsCallable(functions, "rollupAnalyticsOnDemand");

    // Call your cloud function with franchiseId
    return rollupAnalyticsOnDemand({ franchiseId: "your-franchise-id" });
  })
  .then(result => {
    console.log("Rollup success:", result.data);
  })
  .catch(error => {
    console.error("Rollup error:", error);
  });
