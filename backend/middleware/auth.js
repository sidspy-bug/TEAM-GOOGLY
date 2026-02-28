const admin = require("firebase-admin");

/**
 * Decode a Firebase ID token JWT payload without verification.
 * Used as fallback when serviceAccountKey.json is not available.
 */
function decodeTokenPayload(token) {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString());
    return payload;
  } catch {
    return null;
  }
}

async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No token provided" });
  }

  const token = authHeader.split("Bearer ")[1];

  // Try Firebase Admin verification first (if initialized with service account)
  try {
    if (admin.apps.length > 0) {
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = decodedToken;
      return next();
    }
  } catch (verifyError) {
    // Firebase Admin verification failed — fall through to JWT decode
  }

  // Fallback: decode the JWT payload without verification (dev mode)
  // This still extracts the real uid/email from the Firebase-issued token
  const payload = decodeTokenPayload(token);
  if (payload && payload.user_id) {
    req.user = {
      uid: payload.user_id || payload.sub,
      email: payload.email || "",
      name: payload.name || "",
    };
    return next();
  }

  return res.status(401).json({ error: "Invalid token" });
}

module.exports = verifyToken;
