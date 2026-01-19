import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class DatabaseService {
  final FirebaseFirestore dataBase = FirebaseFirestore.instance;


  //topics collection
  Stream<QuerySnapshot> getTopicsStream() {
    return dataBase.collection('topics').orderBy('createdAt', descending: true).snapshots();
  }

  // Single topic stream
  Stream<DocumentSnapshot> getSingleTopicStream(String topicId) {
    return dataBase.collection('topics').doc(topicId).snapshots();
  }

  //Mark topic as seen by user
  Future<void> markAsSeen(String topicId, String userId) async {
    await dataBase.collection('topics').doc(topicId).update({
      'seenBy': FieldValue.arrayUnion([userId])
    });
  }

  //toggle favorite
  Future<void> toggleFavorite(String topicId, String userId) async {
    final docRef = dataBase.collection('topics').doc(topicId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      List favoritedBy = [];
      if (doc.data() != null && (doc.data() as Map).containsKey('favoritedBy')) {
        favoritedBy = List.from(doc.get('favoritedBy'));
      }

      if (favoritedBy.contains(userId)) {
        await docRef.update({'favoritedBy': FieldValue.arrayRemove([userId])});
      } else {
        await docRef.update({'favoritedBy': FieldValue.arrayUnion([userId])});
      }
    }
  }

  //create topic
  Future<void> createTopic(Map<String, dynamic> topicData) async {
    topicData['createdAt'] = FieldValue.serverTimestamp();
    await dataBase.collection('topics').add(topicData);
  }

  //add comment
  Future<void> addComment(String topicId, Map<String, dynamic> commentData) async {
    commentData['createdAt'] = FieldValue.serverTimestamp();
    
    await dataBase.collection('topics')
        .doc(topicId)
        .collection('comments')
        .add(commentData);
  }

  //comments stream
  Stream<QuerySnapshot> getCommentsStream(String topicId) {
    return dataBase.collection('topics')
        .doc(topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true) 
        .snapshots();
  }

  //get user information
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await dataBase.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  //user information stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return dataBase.collection('users').doc(uid).snapshots();
  }

  //update user information
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await dataBase.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  //check if username exists
  Future<bool> checkUsernameExists(String username) async {
    final result = await dataBase
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    
    return result.docs.isNotEmpty;
  }

  //Increment user level and points
  Future<void> incrementUserLevel(String uid) async {
    final userRef = dataBase.collection('users').doc(uid);
    bool leveledUp = false;
    int newLevelValue = 0;
    
    await dataBase.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      
      if (!snapshot.exists) {
        //if it is a new user, create with level 1 and 10 points
        transaction.set(userRef, {'level': 1, 'points': 10});
      } else {
        //existing user, increment points and check for level up
        final data = snapshot.data() as Map<String, dynamic>;
        int currentPoints = data['points'] ?? 0;
        int currentLevel = data['level'] ?? 1;
        
        int newPoints = currentPoints + 10;
        //level up for every 50 points
        int newLevel = (newPoints ~/ 50) + 1;

        //check if leveled up
        if (newLevel > currentLevel) {
          leveledUp = true;
          newLevelValue = newLevel;
        }

        //update user data (points and level)
        transaction.update(userRef, {
          'points': newPoints,
          'level': newLevel > currentLevel ? newLevel : currentLevel,
        });
      }
    });

    // --- NOVO: CRIA A NOTIFICAÇÃO NA LISTA ---
    // 1. Notificação de Pontos (Sempre que ganha pontos)
    await dataBase.collection('users').doc(uid).collection('notifications').add({
      'title': 'Points Earned! ⭐',
      'message': 'You received 10 points for your contribution.',
      'type': 'points', // Isto ajuda a escolher o ícone (se tiveres essa lógica na página)
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // 2. Notificação de Level Up (Se subiu de nível)
    if (leveledUp) {
      await dataBase.collection('users').doc(uid).collection('notifications').add({
        'title': 'Level Up! 🚀',
        'message': 'Congratulations! You reached Level $newLevelValue!',
        'type': 'points',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  //save user FCM token (for push notifications)
  Future<void> saveUserToken(String uid, String token) async {
    await dataBase.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  //notification sending function
  final String serviceAcc = '''
{
  "type": "service_account",
  "project_id": "world-wide-connect-3b5f2",
  "private_key_id": "8bfae882441099a0759bfc84d7d13d7746b23493",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDgqL3hKKHE77v6\\nyPzwJeHjOIwlPF/Tf27LgnVQnF5SUPR9h6fS1fWCVdevOxsyif5oTOOikEp3io6p\\n8KT7Zo4BZW5B9puDcPDZkkwwbEvFCgQszdH2x/6otsJaoJCnU8y38p1jPwnSbvLf\\nfOGEBvx21aAk6kkcBI2U0nLrlLqxCNBZ40iFTd6fLroeAnKaPdPMETT79NMmTBdt\\nmRtGwYJnRvvuEYfNN7wZhRT4sSBkLVnsNtHdbNEAOuA5liPVCc/iDLjx/UvBYQj+\\ndeRDPfLxmjkXdJbtRZJXepptUEEwvGmw1se//4h4baCrmZctZQpxnWXH49NBINGd\\nRWyKNG5FAgMBAAECggEADh50vn2N+yFA7GAsy0/qLBxN7HoooJNh7G7QviXxpJU7\\nZFc99Blnwk7wTO43RZwYDciFRt5wG6as1B/QUo9trcdI4GLl/6L9tALGgIWR1nqM\\nbB9sSmjjx4ki2ky8gpOY6leYThg0XxIDeAmyZ5iDzdkbpS5HNXhQyJFYURdqCz2f\\nHpY2I/Y+ns6k48Z67P54PS13m+XuUXYNWebRy+n7So+mfteQkCJKw+6mjcCmJNyE\\ndsKv5JZkRtAmQrUCR5ZhlTapC6dL+aY/I1hqSszNDPCQ7CWvT00HqH508ZSsCYzo\\nBsorAmz44XbHPiUFBJVKWT5366JOYzFhUKjvt0P2CQKBgQD+N3iCWFmyM7kNnllt\\nYn3KRvweEX/2ijkgbhMnGfhBkK6UBkOts63Kwvv07o1dwHzPHQAZ1skEppSIsDaq\\n3sDTDom7j+DnPQL83mozINSDWCpEo41Z139eBN+PYQh9tdq8cN1/m8xOB3c3M6bI\\n6bF2fb6fbQNnsM37PTZVXX8NfQKBgQDiPDDU7TSna70L3VnihX8qCH7v1C/jOGbC\\n2mf/mM81Fp5Om+TS9ITmHuWUzaqAtUT2kYv8VR+mbE0BYirn6vp9trwEJ3ZOnGBc\\nPKoloVN9MkDNs5b36F1WFjcSMYT2kqy/RzPkBQ/L6yIn9lLrATE2aFQc4jRf2P85\\nIv3lm/ReaQKBgQD0EroHG2By8an4Y1Ik7W0sal7hV5fuUuNqOYT2A78Q5CJZSHJu\\nMZbol7Bkhyz/GDI8f/F63Xb+mhj964FxKJElkk224PrjyPY3Ziu8jwa6XEmowQaT\\nfY1x7WffNyB54cHzLsHbJPBQ8mYJf/Pf7k9OHoiIdJfSVDRPxYOHDk9P2QKBgARw\\ndezXsr7OSGlhMJBXWkVy4TrHiSEGTE3qhzvmvbom9XhJatYQ4kK5vHuNBZl89Rt5\\ng6ux5+sWGPS7/meKntu0qD/UnmewfduRfS072y2LvOXMblvy/VHhIbeDrT5BZo5i\\nUUxaJRM1S/hIxxvBbDvLFEt0zN5MncV7QEwvIT5xAoGAAqcSNzbx4cMrmixZue9W\\nPOpjLwqJIxIy4AiHAOy6YH6qUDAUgI2S4Wk1NkX0mllfVjd5f2bq8vxfxW9BLBDw\\n6KTWid+Z3lF5NcSwdVwnJDkQQ35lmu8/ERPqpkFI0V/UMcNK1DAaYXwRg9LUuYat\\nVmr0WklXDTyHgkM2+f2h85M=\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@world-wide-connect-3b5f2.iam.gserviceaccount.com",
  "client_id": "115080134412545840638",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40world-wide-connect-3b5f2.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  //obtain access token using service account
  Future<String> getAccessToken() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(serviceAcc); //loads up the credetentials from the JSON
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccountCredentials, scopes); //creates the client
    return client.credentials.accessToken.data; //returns the access token
  }

  //send push notification
  Future<void> sendPushNotification(String token, String title, String body) async {
      //Obtain access token
      final String accessToken = await getAccessToken();
      
      //Extract project ID (project ID is in the service account JSON)
      final Map<String, dynamic> jsonMap = jsonDecode(serviceAcc);
      final String projectId = jsonMap['project_id'];

      //Send POST request to FCM API
      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            }
          }
        }),
      );
  }

  //when clicks the subscribe/unsubscribe button, toggle subscription
  Future<void> toggleTopicSubscription(String topicId, String userId) async {
    try {
      final docRef = dataBase.collection('topics').doc(topicId);
      final doc = await docRef.get();
      
      //if topic exists
      if (doc.exists) {
        List subscribedBy = [];
        //Get current list of subscribers
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('subscribedBy')) {
          subscribedBy = List.from(data['subscribedBy']);
        }

        //toggle subscription
        if (subscribedBy.contains(userId)) {
          //if already subscribed, remove
          await docRef.update({'subscribedBy': FieldValue.arrayRemove([userId])});
        } else {
          //if not subscribed, add
          await docRef.update({'subscribedBy': FieldValue.arrayUnion([userId])});
        }
      }
    } catch (e) {
      print("Error toggling subscription: $e");
    }
  }

  //Send notifications to subscribers when a new comment is added
  Future<void> notifySubscribers(String topicId, String commenterName, String topicTitle, String commenterId) async {
    DocumentSnapshot topicSnap = await dataBase.collection('topics').doc(topicId).get();
    if (!topicSnap.exists) return;

    final data = topicSnap.data() as Map<String, dynamic>;
    
    //Get the list of subscribers
    List subscribers = [];
    if (data.containsKey('subscribedBy')) {
      subscribers = List.from(data['subscribedBy']);
    }

    //Adds the author of the topic to the subscribers list if not already present
    String authorId = data['authorId'];
    if (!subscribers.contains(authorId)) {
      subscribers.add(authorId);
    }

    //Sends the notification to each subscriber
    for (String userId in subscribers) {
      //do not notify the commenter themselves (because it is oubvious they commented)
      if (userId == commenterId) continue;

      //save the message in the notifications collection
      await dataBase.collection('users').doc(userId).collection('notifications').add({
        'title': 'New Message 💬',
        'message': '$commenterName commented in: $topicTitle',
        'type': 'reply',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'topicId': topicId,
      });

      //Send push notification and reads user token
      DocumentSnapshot userSnap = await dataBase.collection('users').doc(userId).get();
      if (userSnap.exists) {
        var userData = userSnap.data() as Map<String, dynamic>;
        String? token = userData['fcmToken'];
        bool notificationsEnabled = userData['notificationsEnabled'] ?? false;

        if (notificationsEnabled && token != null && token.isNotEmpty) {
          await sendPushNotification(
            token, 
            "New Reply!", 
            "$commenterName commented in: $topicTitle"
          );
        }
      }
    }
  }
  
}