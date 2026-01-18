import 'package:firebase_messaging/firebase_messaging.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final DatabaseService dataBase = DatabaseService();

  //Inicialize notifications
  Future<void> initNotifications() async {
    //Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      
      //Get the token for this device (used to send notifications to it)
      String? userToken = await messaging.getToken();
      //Save the token to your database when the user is logged in
      if (userToken != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await dataBase.saveUserToken(user.uid, userToken);
        }
      }

      //Get notified when a message is received while the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      });
    }
  }
}