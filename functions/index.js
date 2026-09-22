
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Optional Twilio SMS Provider initialization from environment variables
const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID;
const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

let twilioClient = null;
if (twilioAccountSid && twilioAuthToken) {
  const twilio = require("twilio");
  twilioClient = twilio(twilioAccountSid, twilioAuthToken);
}

/**
 * Triggered whenever daily usage is written or updated for a user.
 * Evaluates high risk score (score >= 61), checks cooldown, and dispatches guardian alert.
 */
exports.onDailyUsageWritten = functions.firestore
  .document("users/{userId}/dailyUsage/{date}")
  .onWrite(async (change, context) => {
    const { userId, date } = context.params;
    const dataAfter = change.after.exists ? change.after.data() : null;

    if (!dataAfter) {
      // Document deleted
      return null;
    }

    const riskScore = dataAfter.riskScore || 0;
    const riskLevel = dataAfter.riskLevel || "LOW";
    const totalScreenTime = dataAfter.totalScreenTime || 0; // minutes

    // 1. Check if High-Risk threshold (61) is crossed
    if (riskScore < 61) {
      return null;
    }

    // 2. Fetch User Profile
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found.`);
      return null;
    }

    const userData = userDoc.data();
    const notificationEnabled = userData.notificationEnabled !== false;
    const guardianMobile = userData.guardianMobile;
    const guardianName = userData.guardianName || "Guardian";
    const userName = userData.name || "HabitGuard User";

    if (!notificationEnabled || !guardianMobile) {
      console.log(`Guardian notifications disabled or missing mobile for user ${userId}.`);
      return null;
    }

    // 3. Cooldown Check: 24h deduplication per date
    const recentAlertsSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("alerts")
      .orderBy("timestamp", "desc")
      .limit(1)
      .get();

    if (!recentAlertsSnapshot.empty) {
      const lastAlert = recentAlertsSnapshot.docs[0].data();
      const lastAlertTime = lastAlert.timestamp ? lastAlert.timestamp.toDate() : null;
      if (lastAlertTime) {
        const hoursSinceLastAlert = (Date.now() - lastAlertTime.getTime()) / (1000 * 60 * 60);
        if (hoursSinceLastAlert < 24 && riskScore < 81) {
          console.log(`Alert suppressed due to 24h cooldown for user ${userId}. Hours since last: ${hoursSinceLastAlert.toFixed(1)}`);
          return null;
        }
      }
    }

    // 4. Construct Alert Message
    const formattedHours = Math.floor(totalScreenTime / 60);
    const formattedMins = totalScreenTime % 60;
    const durationStr = `${formattedHours}h ${formattedMins}m`;

    const smsMessage = `HabitGuard Alert: ${userName}'s smartphone addiction risk is currently ${riskLevel} (Score: ${riskScore}/100, Screen Time: ${durationStr}). Please check in with them to encourage a healthy digital break.`;

    // 5. Send Guardian SMS via Twilio or Webhook
    let smsStatus = "SIMULATED_SUCCESS";
    if (twilioClient && twilioPhoneNumber) {
      try {
        const fullPhone = guardianMobile.startsWith("+") ? guardianMobile : `+91${guardianMobile}`;
        const messageResult = await twilioClient.messages.create({
          body: smsMessage,
          from: twilioPhoneNumber,
          to: fullPhone,
        });
        smsStatus = `SENT_TWILIO_${messageResult.sid}`;
        console.log(`SMS successfully dispatched to ${fullPhone}. SID: ${messageResult.sid}`);
      } catch (smsError) {
        console.error("Failed to send Twilio SMS:", smsError);
        smsStatus = `ERROR: ${smsError.message}`;
      }
    } else {
      console.log(`[DEVELOPMENT MODE] Twilio credentials not configured. Simulated SMS to ${guardianMobile}: "${smsMessage}"`);
    }

    // 6. Send FCM Push Notification to User's Active Devices
    const devicesSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("devices")
      .get();

    const pushTokens = [];
    devicesSnapshot.forEach((doc) => {
      const token = doc.data().token;
      if (token) pushTokens.push(token);
    });

    if (pushTokens.length > 0) {
      const pushPayload = {
        notification: {
          title: `⚠️ HabitGuard Alert: ${riskLevel} Addiction Risk`,
          body: `Today's screen time: ${durationStr}. Risk score: ${riskScore}/100. Take a break!`,
        },
        data: {
          riskScore: String(riskScore),
          riskLevel: riskLevel,
          date: date,
        },
      };

      try {
        await admin.messaging().sendEachForMulticast({
          tokens: pushTokens,
          ...pushPayload,
        });
        console.log(`Pushed high-risk alert notification to ${pushTokens.length} devices.`);
      } catch (pushError) {
        console.error("Failed to send FCM push notification:", pushError);
      }
    }

    // 7. Log Alert Document in Firestore
    await db.collection("users").doc(userId).collection("alerts").add({
      date: date,
      riskScore: riskScore,
      riskLevel: riskLevel,
      totalScreenTimeMinutes: totalScreenTime,
      guardianName: guardianName,
      guardianMobile: guardianMobile,
      message: smsMessage,
      smsStatus: smsStatus,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Guardian alert recorded in Firestore for user ${userId}.`);
    return { success: true, smsStatus };
  });
