const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword } = require("firebase/auth");
const { getFunctions, httpsCallable } = require("firebase/functions");

// 1. Replace with your actual Firebase config (from project settings)
const firebaseConfig = {
  apiKey: "AIzaSyBBlWVSua4QfPefy4TRPmOT_7ErfgAuZZ4",
  authDomain: "doughboyspizzeria-2b3d2.firebaseapp.com",
  projectId: "doughboyspizzeria-2b3d2",
  storageBucket: "doughboyspizzeria-2b3d2.firebasestorage.app",
  messagingSenderId: "739021537990",
  appId: "1:739021537990:web:2e5cd605ce92e912fe0dc7",
  measurementId: "G-YLJEF3MQYE"
};

const app = initializeApp(firebaseConfig);

const auth = getAuth(app);

async function main() {
  // 2. Sign in as a user with owner/developer role
  await signInWithEmailAndPassword(auth, "YOUR_EMAIL", "YOUR_PASSWORD");

  // 3. Initialize Functions client for the correct region
  const functions = getFunctions(app, "us-central1");

  // 4. Call the callable function
  const setClaimsForExistingUsers = httpsCallable(functions, "setClaimsForExistingUsers");

  try {
    const result = await setClaimsForExistingUsers({});
    console.log("Result:", result.data);
  } catch (err) {
    console.error("Error:", err);
  }
}

main();
