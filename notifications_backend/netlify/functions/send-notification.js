const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// We check if it's already initialized to avoid hot-reload errors in Netlify
if (!admin.apps.length) {
  // We expect the service account JSON to be stringified in the ENV variable
  // named 'FIREBASE_SERVICE_ACCOUNT'
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } catch (error) {
    console.error('Firebase Admin Initialization Error:', error);
  }
}

exports.handler = async function (event, context) {
  // CORS Headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Accept',
    'Access-Control-Allow-Methods': 'OPTIONS, POST',
  };

  // Handle preflight OPTIONS request
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }

  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: 'Method Not Allowed' };
  }

  try {
    const { targetUserId, title, body, data } = JSON.parse(event.body);

    if (!targetUserId || !title || !body) {
      return { statusCode: 400, headers, body: 'Missing required fields: targetUserId, title, body' };
    }

    console.log(`Sending notification to user: ${targetUserId}`);

    const db = admin.firestore();
    let tokens = [];

    // 1. Check the fcm_tokens subcollection (used by bazaar_owner_app & super_admin_panel)
    const tokensSnapshot = await db
      .collection('users')
      .doc(targetUserId)
      .collection('fcm_tokens')
      .get();

    if (!tokensSnapshot.empty) {
      tokens = tokensSnapshot.docs.map(doc => doc.id);
    } else {
      // 2. Fall back to checking the user document (used by egyptian_tourism_app)
      console.log(`No tokens in subcollection for user ${targetUserId}, checking user document...`);
      const userDoc = await db.collection('users').doc(targetUserId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          tokens = [userData.fcmToken];
        }
      }
    }

    if (tokens.length === 0) {
      console.log(`No tokens found for user: ${targetUserId}`);
      return { statusCode: 200, headers, body: JSON.stringify({ success: false, message: 'User has no registered devices.' }) };
    }

    // Construct the message payload
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data || {}, // Optional data payload (e.g., click_action, orderId)
      tokens: tokens,
    };

    // Send via FCM Multicast (to all user's devices)
    const response = await admin.messaging().sendEachForMulticast(message);

    console.log(`${response.successCount} messages were sent successfully`);

    // Cleanup invalid tokens (optional but recommended)
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      console.log('Failed tokens (should be investigated or deleted):', failedTokens);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ success: true, sentCount: response.successCount }),
    };

  } catch (error) {
    console.error('Notification Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
