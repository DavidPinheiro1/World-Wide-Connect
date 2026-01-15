import 'package:firebase_messaging/firebase_messaging.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseService _dbService = DatabaseService();

  // Inicializar Notificações
  Future<void> initNotifications() async {
    // 1. Pedir permissão
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // 2. Obter o Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("FCM Token: $token");
        // Guardar na base de dados se o user estiver logado
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _dbService.saveUserToken(user.uid, token);
        }
      }

      // 3. Ouvir mensagens em primeiro plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          // Aqui podes usar o flutter_local_notifications para mostrar um popup
          // Se quiseres, posso dar-te esse código extra depois.
        }
      });
    }
  }
}