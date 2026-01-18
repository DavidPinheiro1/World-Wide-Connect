import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firebase_options.dart';
import 'auth_service.dart';
import 'database_service.dart'; 
import 'pages/landing_page.dart';
import 'pages/main_screen.dart';
import 'pages/onboarding_page.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/services/good_behavior_service.dart'; 

//Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //Load the bad words list before app starts
  await GoodBehaviorService().loadBadWords();

  //Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //message system key
  final GlobalKey<ScaffoldMessengerState> messageKey = GlobalKey<ScaffoldMessengerState>();
  //navigation and overlay key, used to create the notification banner
  final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    notificationsSetup();
  }

  //setup notifications
  Future<void> notificationsSetup() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    //request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user != null) {
            DatabaseService().saveUserToken(user.uid, token);
          }
        });
        
        messaging.onTokenRefresh.listen((newToken) {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            DatabaseService().saveUserToken(currentUser.uid, newToken);
          }
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          TopBannerNotification(
            message.notification!.title ?? "New Message",
            message.notification!.body ?? "Tap to view",
          );
        }
      });
    }
  }

  //function to show top banner notification
  void TopBannerNotification(String title, String body) {
    if (navigationKey.currentState == null) return;

    final overlayState = navigationKey.currentState!.overlay;
    if (overlayState == null) return;

    final context = navigationKey.currentState!.context;
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, 
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationWidget(
            title: title,
            body: body,
            onDismiss: () {
              entry?.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (entry != null && entry!.mounted) {
        entry!.remove();
      }
    });
  }

  //Configure the app theme, all the text styles use Google Fonts Montserrat, besides user input
  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    
    return MaterialApp(
      navigatorKey: navigationKey,
      scaffoldMessengerKey: messageKey,
      debugShowCheckedModeBanner: false,
      title: 'Mensa App',
      theme: ThemeData(
        primaryColor: const Color(0xFFFC751D),
        useMaterial3: true,
        
        textTheme: GoogleFonts.montserratTextTheme(baseTextTheme).copyWith(
          bodyMedium: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodySmall: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
          titleLarge: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

//decides which page to show based on authentication state
//if the user is logged in, check if profile is complete
//if profile is complete, go to MainScreen, else go to OnboardingPage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LandingPage();
        }

        User user = snapshot.data!;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFC751D))));
            }

            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>;
              
              bool isComplete = data['isProfileComplete'] ?? false;

              if (isComplete) {
                return const MainScreen();
              } else {
                return OnboardingPage(
                  name: user.displayName ?? "",
                  email: user.email ?? "",
                );
              }
            }
            
            return const MainScreen();
          },
        );
      },
    );
  }
}

//Notification Widget with Animation
class NotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const NotificationWidget({
    required this.title, 
    required this.body, 
    required this.onDismiss
  });

  @override
  State<NotificationWidget> createState() => StateOfNotificationWidget();
}

//state class for notification banner, animation included
class StateOfNotificationWidget extends State<NotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController controllerOfAnimation;
  late Animation<Offset> animationPosition;

//initialize animation 
  @override
  void initState() {
    super.initState();
    controllerOfAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    animationPosition = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controllerOfAnimation,
      curve: Curves.elasticOut,
    ));

    controllerOfAnimation.forward();
  }

  //clean up memory after notification is dismissed
  @override
  void dispose() {
    controllerOfAnimation.dispose();
    super.dispose();
  }


  //notification banner UI
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animationPosition,
      child: GestureDetector(
        onTap: widget.onDismiss,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            widget.onDismiss();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC751D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: Color(0xFFFC751D)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}