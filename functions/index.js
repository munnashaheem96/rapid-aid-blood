const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Calculate distance between two coordinates in KM using Haversine formula
 */
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in KM

  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Triggered when a new blood request is created
 * Sends notifications to nearby matching users
 */
exports.sendEmergencyAlert = functions.firestore
  .document("blood_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const request = snap.data();

    console.log("🔥 New request received:", request);

    // 🔍 Validate request data
    if (!request.lat || !request.lng || !request.bloodGroup) {
      console.log("❌ Invalid request data");
      return null;
    }

    try {
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

      const tasks = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();

        // ❌ Skip invalid users
        if (!user.fcmToken || !user.lat || !user.lng) return;

        // 🩸 Blood group match
        if (user.bloodGroup !== request.bloodGroup) return;

        // 📍 Distance check
        const distance = getDistance(
          user.lat,
          user.lng,
          request.lat,
          request.lng
        );

        if (distance > 20) return;

        console.log(
          `📤 Sending alert to ${doc.id} (${distance.toFixed(2)} km)`
        );

        // 🔔 Notification payload
        const message = {
          token: user.fcmToken,
          notification: {
            title: "🚨 Emergency Blood Request",
            body: `${request.bloodGroup} needed near ${request.location}`,
          },
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
            },
          },
        };

        tasks.push(admin.messaging().send(message));
      });

      // 🚀 Send all notifications
      await Promise.all(tasks);

      console.log("✅ All notifications sent successfully");

      return null;
    } catch (error) {
      console.error("❌ Error sending notifications:", error);
      return null;
    }
  });