import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart'; // <--- OBRIGATÓRIO: flutter pub add googleapis_auth

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- TOPICS (Tópicos) ---

  Stream<QuerySnapshot> getTopicsStream() {
    return _db.collection('topics').orderBy('createdAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot> getSingleTopicStream(String topicId) {
    return _db.collection('topics').doc(topicId).snapshots();
  }

  Future<void> markAsSeen(String topicId, String userId) async {
    try {
      await _db.collection('topics').doc(topicId).update({
        'seenBy': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print("Error marking as seen: $e");
    }
  }

  Future<void> toggleFavorite(String topicId, String userId) async {
    try {
      final docRef = _db.collection('topics').doc(topicId);
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
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  Future<void> createTopic(Map<String, dynamic> topicData) async {
    try {
      topicData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('topics').add(topicData);
    } catch (e) {
      print("Error creating topic: $e");
      rethrow;
    }
  }

  // --- COMMENTS / MESSAGES ---

  Future<void> addComment(String topicId, Map<String, dynamic> commentData) async {
    try {
      commentData['createdAt'] = FieldValue.serverTimestamp();
      
      await _db.collection('topics')
          .doc(topicId)
          .collection('comments')
          .add(commentData);
    } catch (e) {
      print("Error adding comment: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getCommentsStream(String topicId) {
    return _db.collection('topics')
        .doc(topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true) 
        .snapshots();
  }

  // --- USER DATA & GAMIFICATION ---

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final result = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return false; 
    }
  }

  // Substitui a função incrementUserLevel por esta:
  Future<void> incrementUserLevel(String uid) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      bool leveledUp = false;
      int newLevelVal = 0;
      
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) {
          // Se o user não tiver dados, cria com 10 pontos
          transaction.set(userRef, {'level': 1, 'points': 10});
        } else {
          final data = snapshot.data() as Map<String, dynamic>;
          int currentPoints = data['points'] ?? 0;
          int currentLevel = data['level'] ?? 1;
          
          int newPoints = currentPoints + 10;
          // Exemplo: Sobe de nível a cada 50 pontos
          int newLevel = (newPoints ~/ 50) + 1;

          if (newLevel > currentLevel) {
            leveledUp = true;
            newLevelVal = newLevel;
          }

          transaction.update(userRef, {
            'points': newPoints,
            'level': newLevel > currentLevel ? newLevel : currentLevel,
          });
        }
      });

      // --- NOVO: CRIA A NOTIFICAÇÃO NA LISTA ---
      // 1. Notificação de Pontos (Sempre que ganha pontos)
      await _db.collection('users').doc(uid).collection('notifications').add({
        'title': 'Points Earned! ⭐',
        'message': 'You received 10 points for your contribution.',
        'type': 'points', // Isto ajuda a escolher o ícone (se tiveres essa lógica na página)
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // 2. Notificação de Level Up (Se subiu de nível)
      if (leveledUp) {
        await _db.collection('users').doc(uid).collection('notifications').add({
          'title': 'Level Up! 🚀',
          'message': 'Congratulations! You reached Level $newLevelVal!',
          'type': 'points',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

    } catch (e) {
      print("Error incrementing user level: $e");
    }
  }

  Future<void> saveUserToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print("Token guardado/atualizado com sucesso: $token");
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // --- NOTIFICATIONS (NOVA API V1 - COM O SEU JSON) ---

  final String _serviceAccountJson = '''
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

  Future<String> _getAccessToken() async {
    try {
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(serviceAccountCredentials, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      print("Erro ao obter Access Token: $e");
      rethrow;
    }
  }

  Future<void> sendPushNotification(String token, String title, String body) async {
    try {
      // 1. Obter o token de segurança (Agora é automático com o seu JSON)
      final String accessToken = await _getAccessToken();
      
      // 2. Extrair o Project ID
      final Map<String, dynamic> jsonMap = jsonDecode(_serviceAccountJson);
      final String projectId = jsonMap['project_id'];

      // 3. Enviar para a API V1
      final response = await http.post(
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

      if (response.statusCode == 200) {
        print("✅ Notificação V1 enviada com sucesso!");
      } else {
        print("❌ FALHA NO ENVIO V1. Código: ${response.statusCode}");
        print("❌ Resposta: ${response.body}");
      }
    } catch (e) {
      print("❌ Erro CRÍTICO ao enviar notificação V1: $e");
    }
  }

  // --- NOVAS FUNÇÕES DE SUBSCRIÇÃO ---

  // 1. Botão do Sino: Subscrever ou Cancelar subscrição num tópico
  Future<void> toggleTopicSubscription(String topicId, String userId) async {
    try {
      final docRef = _db.collection('topics').doc(topicId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        List subscribedBy = [];
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('subscribedBy')) {
          subscribedBy = List.from(data['subscribedBy']);
        }

        if (subscribedBy.contains(userId)) {
          // Se já segue, remove (deixa de seguir)
          await docRef.update({'subscribedBy': FieldValue.arrayRemove([userId])});
        } else {
          // Se não segue, adiciona
          await docRef.update({'subscribedBy': FieldValue.arrayUnion([userId])});
        }
      }
    } catch (e) {
      print("Error toggling subscription: $e");
    }
  }

  // 2. Enviar Notificação aos Subscritores (Avisa quem segue o tópico)
  Future<void> notifySubscribers(String topicId, String commenterName, String topicTitle, String commenterId) async {
    try {
      DocumentSnapshot topicSnap = await _db.collection('topics').doc(topicId).get();
      if (!topicSnap.exists) return;

      final data = topicSnap.data() as Map<String, dynamic>;
      
      // A. Lista de Subscritores (quem clicou no sino)
      List subscribers = [];
      if (data.containsKey('subscribedBy')) {
        subscribers = List.from(data['subscribedBy']);
      }

      // B. Adicionar o Dono do Tópico (se não estiver na lista)
      String authorId = data['authorId'];
      if (!subscribers.contains(authorId)) {
        subscribers.add(authorId);
      }

      // C. Enviar para cada pessoa
      for (String userId in subscribers) {
        // Não notificar a própria pessoa que escreveu
        if (userId == commenterId) continue;

        // 1. Gravar na Base de Dados (Para aparecer na lista da App)
        await _db.collection('users').doc(userId).collection('notifications').add({
          'title': 'New Message 💬',
          'message': '$commenterName commented in: $topicTitle',
          'type': 'reply',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'topicId': topicId,
        });

        // 2. Enviar Push Notification (Para o telemóvel vibrar)
        // (Lê o token de cada utilizador individualmente)
        DocumentSnapshot userSnap = await _db.collection('users').doc(userId).get();
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
    } catch (e) {
      print("Erro ao notificar subscritores: $e");
    }
  }
  
}