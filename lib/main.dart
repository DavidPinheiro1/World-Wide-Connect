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

// 1. BACKGROUND MESSAGE HANDLER
// This must be a top-level function to handle messages when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Logic to handle background message can be added here if needed.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // GlobalKey for showing SnackBars if needed
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  // Navigator Key to access context from anywhere (essential for overlays)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  // --- NOTIFICATION SETUP ---
  Future<void> _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for mobile platforms
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      
      // Get FCM Token
      String? token = await messaging.getToken();

      if (token != null) {
        // Save token when user logs in
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user != null) {
            DatabaseService().saveUserToken(user.uid, token);
          }
        });
        
        // Update token if it refreshes
        messaging.onTokenRefresh.listen((newToken) {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            DatabaseService().saveUserToken(currentUser.uid, newToken);
          }
        });
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          // Show custom in-app banner
          _showTopBanner(
            message.notification!.title ?? "New Message",
            message.notification!.body ?? "Tap to view",
          );
        }
      });
    }
  }

  // --- CUSTOM IN-APP BANNER LOGIC ---
  void _showTopBanner(String title, String body) {
    if (_navigatorKey.currentState == null) return;

    final overlayState = _navigatorKey.currentState!.overlay;
    if (overlayState == null) return;

    final context = _navigatorKey.currentState!.context;
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        // padding.top prevents overlap with the status bar/notch
        top: MediaQuery.of(context).padding.top + 10, 
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _ModernNotificationWidget(
            title: title,
            body: body,
            onDismiss: () {
              entry?.remove();
            },
          ),
        ),
      ),
    );

    // Insert the banner into the overlay
    overlayState.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry != null && entry!.mounted) {
        entry!.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Capture base text theme to apply Google Fonts correctly
    final baseTextTheme = Theme.of(context).textTheme;
    
    return MaterialApp(
      navigatorKey: _navigatorKey, // Essential for navigation without context
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Mensa App',
      theme: ThemeData(
        primaryColor: const Color(0xFFFC751D),
        useMaterial3: true,
        
        // --- TYPOGRAPHY CONFIGURATION ---
        // Applies Montserrat globally but ensures readability with specific weights/colors
        textTheme: GoogleFonts.montserratTextTheme(baseTextTheme).copyWith(
          bodyMedium: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500, // Medium weight for better visibility
            color: Colors.black87,       // High contrast color
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

// --- AUTHENTICATION WRAPPER ---
// Decides which screen to show based on user state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. User NOT logged in -> Landing Page
        if (!snapshot.hasData || snapshot.data == null) {
          return const LandingPage();
        }

        // 3. User LOGGED in -> Check profile completion in Firestore
        User user = snapshot.data!;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFC751D))));
            }

            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>;
              
              // Check 'isProfileComplete' flag
              bool isComplete = data['isProfileComplete'] ?? false;

              if (isComplete) {
                // Profile OK -> Main Screen
                return const MainScreen();
              } else {
                // Profile Incomplete -> Onboarding
                return OnboardingPage(
                  name: user.displayName ?? "",
                  email: user.email ?? "",
                );
              }
            }
            
            // Fallback (Assumes login successful if doc read fails)
            return const MainScreen();
          },
        );
      },
    );
  }
}

// -------------------------------------------------------
//    MODERN NOTIFICATION BANNER WIDGET
// -------------------------------------------------------
class _ModernNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _ModernNotificationWidget({
    required this.title, 
    required this.body, 
    required this.onDismiss
  });

  @override
  State<_ModernNotificationWidget> createState() => _ModernNotificationWidgetState();
}

class _ModernNotificationWidgetState extends State<_ModernNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Starts hidden above screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Spring/Bounce effect
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: widget.onDismiss,
        onVerticalDragEnd: (details) {
          // Swipe up to dismiss
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