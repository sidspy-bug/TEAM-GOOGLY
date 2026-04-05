const admin = require("firebase-admin");

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return true;
  }

  try {
    const serviceAccount = require("../../serviceAccountKey.json");
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log("Firebase Admin initialized (auth verification enabled)");
    return true;
  } catch (error) {
    console.warn("No serviceAccountKey.json found. Running without Firebase token verification.");
    console.warn("Auth endpoints will accept decoded JWT payload only. Add the key for production.");
    return false;
  }
}

module.exports = {
  initializeFirebaseAdmin,
};
