import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE
import 'package:firebase_auth/firebase_auth.dart'; // <--- NECESSÁRIO PARA RESET PASSWORD
import '../auth_service.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = true;

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NOVA FUNÇÃO: RECUPERAR PASSWORD ---
  Future<void> _handleForgotPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address first."),
          backgroundColor: Color(0xFFFC751D),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Função auxiliar para as imagens desfocadas ---
  Widget _buildDecorationIcon({required double top, required double left, required double size}) {
    return Positioned(
      top: top, left: left,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Opacity(
          opacity: 0.8,
          child: Image.asset('lib/assets/images/wwc.png', width: size, height: size),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // Rótulo ("Email", "Password") -> Mantém Montserrat (Padrão)
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), 
          child: TextField(
            controller: controller, 
            obscureText: isPassword, 
            
            // --- TEXTO DO UTILIZADOR (AR ONE SANS) ---
            style: GoogleFonts.arOneSans(
              fontSize: 16,
              color: Colors.black,
            ),

            decoration: InputDecoration(
              hintText: hint, 
              
              // --- PLACEHOLDER (AR ONE SANS) ---
              hintStyle: GoogleFonts.arOneSans(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
            )
          )
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Captura o tamanho do ecrã para usar nos cálculos abaixo
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 30, right: 30, bottom: 50), 
        child: Column(
          children: [
            SizedBox(
              height: 380, 
              child: Stack(
                alignment: Alignment.center, 
                children: [
                  // --- NOVAS POSIÇÕES BASEADAS NO TAMANHO DO ECRÃ ---
                  _buildDecorationIcon(top: size.height * 0.1, left: size.width * 0, size: 60),
                  _buildDecorationIcon(top: size.height * 0.05, left: size.width * 0.58, size: 60),
                  _buildDecorationIcon(top: size.height * 0.26, left: size.width * 0.58, size: 60),
                  _buildDecorationIcon(top: size.height * 0.3, left: size.width * 0.01, size: 60),
                  
                  // Imagem Principal Central
                  Container(
                    decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 15), blurRadius: 150, spreadRadius: -5)]), 
                    child: Image.asset('lib/assets/images/wwc.png', width: 320, height: 320, fit: BoxFit.contain)
                  )
                ]
              )
            ),
            const Text('Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildTextField(label: 'Email', hint: 'Enter your email', controller: _emailController),
            const SizedBox(height: 20),
            _buildTextField(label: 'Password', hint: 'Enter your password', isPassword: true, controller: _passwordController),
            Row(children: [Checkbox(activeColor: const Color(0xFFFC751D), value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val ?? true)), const Text("Keep me signed in", style: TextStyle(fontSize: 14))]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC751D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 10, shadowColor: const Color(0xFFFC751D).withOpacity(0.5)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 20),
            
            // --- CORREÇÃO: BOTÃO FORGOT PASSWORD ---
            GestureDetector(
              onTap: _handleForgotPassword,
              child: const Text(
                "Forgot password?", 
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.black87,
                  fontSize: 14
                )
              ),
            ),
            
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}