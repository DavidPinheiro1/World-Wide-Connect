import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'main_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    if (FirebaseAuth.instance.currentUser != null) {
       Future.delayed(Duration.zero, () {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
       });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final userCred = await _authService.signInWithGoogle();
      if (userCred != null && mounted) {
         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Sign In Failed."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CORREÇÃO: Usa a imagem wwc.png desfocada ---
  Widget _buildDecorationIcon({required double top, required double left, required double size}) {
    return Positioned(
      top: top,
      left: left,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // Desfoque ligeiro
        child: Opacity(
          opacity: 0.8,
          child: Image.asset('lib/assets/images/wwc.png', width: size, height: size),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double imageSize = size.height * 0.40; 
    double buttonWidth = size.width * 0.65; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // As 4 Imagens pequenas desfocadas
            _buildDecorationIcon(top: size.height * 0.1, left: size.width * 0.75, size: 60),
            _buildDecorationIcon(top: size.height * 0.15, left: size.width * 0.1, size: 60),
            _buildDecorationIcon(top: size.height * 0.35, left: size.width * 0.1, size: 60),
            _buildDecorationIcon(top: size.height * 0.30, left: size.width * 0.75, size: 60),

            SizedBox(
              width: double.infinity, height: size.height,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.05),
                    
                    // Imagem Central
                    Container(
                      height: imageSize, width: imageSize,
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 25), blurRadius: 150, spreadRadius: -5)]),
                      child: Image.asset('lib/assets/images/wwc.png', fit: BoxFit.contain),
                    ),
                    
                    SizedBox(height: size.height * 0.01),
                    const Text('Hello', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text('Welcome To World Wide Connect,\nwhere foreigner students help each others', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9F9F9F), fontSize: 14, height: 1.5))),
                    SizedBox(height: size.height * 0.05),
                    
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                      child: Container(
                        width: buttonWidth, padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFFFC751D), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFFFC751D).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: const Text('Login', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                      child: Container(
                        width: buttonWidth, height: 55,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFCC80), const Color(0xFFFC751D)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30)),
                        child: Padding(padding: const EdgeInsets.all(2.0), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)), child: const Center(child: Text('Sign Up', style: TextStyle(color: const Color(0xFFFC751D), fontSize: 20, fontWeight: FontWeight.bold))))),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.02),
                    
                    Column(children: [
                        const Text('Sign up using', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        _isLoading 
                        ? const CircularProgressIndicator(color: const Color(0xFFFC751D))
                        : GestureDetector(
                            onTap: _handleGoogleLogin,
                            child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10)]), child: Image.asset('lib/assets/images/google-plus.png', width: 60, height: 40)),
                          ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}