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

exports.handler = async function(event, context) {
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const { targetUserId, title, body, data } = JSON.parse(event.body);

    if (!targetUserId || !title || !body) {
      return { statusCode: 400, body: 'Missing required fields: targetUserId, title, body' };
    }

    console.log(`Sending notification to user: ${targetUserId}`);

    // 1. Get the user's FCM token from Firestore
    // Path: users/{uid}/fcm_tokens/token
    // Note: A user might have multiple devices. For simplicity, we'll fetch one or all.
    // Let's assume we store the main token in the user document or a subcollection.
    // Best practice: Subcollection 'fcm_tokens' where document ID is the token.
    
    const db = admin.firestore();
    const tokensSnapshot = await db
      .collection('users')
      .doc(targetUserId)
      .collection('fcm_tokens')
      .get();

    if (tokensSnapshot.empty) {
        console.log(`No tokens found for user: ${targetUserId}`);
        return { statusCode: 200, body: 'User has no registered devices.' };
    }

    const tokens = tokensSnapshot.docs.map(doc => doc.id); // Assuming doc ID is the token

    // 2. Construct the message payload
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data || {}, // Optional data payload (e.g., click_action, orderId)
      tokens: tokens,
    };

    // 3. Send via FCM Multicast (to all user's devices)
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
        // Logic to delete failedTokens from Firestore could go here
        console.log('Failed tokens:', failedTokens);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, sentCount: response.successCount }),
    };

  } catch (error) {
    console.error('Notification Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
