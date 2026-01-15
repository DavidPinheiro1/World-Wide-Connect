import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE
import '../auth_service.dart';
import 'onboarding_page.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = true;

  Future<void> _handleRegister() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _authService.createAccount(name: name, email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      
      if (mounted) {
        Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => OnboardingPage(
                name: name,
                email: email,
              )
            )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        // Rótulo ("Name", "Email") -> Montserrat (Padrão)
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
    // Capturar tamanho do ecrã para responsividade
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30), onPressed: () => Navigator.pop(context))),
      
      // Scroll View com padding no fundo
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 30, right: 30, bottom: 50),
        child: Column(
          children: [
             SizedBox(
              height: 320, 
              child: Stack(
                alignment: Alignment.center, 
                children: [
                  // Posições Relativas (baseadas no tamanho do ecrã)
                  _buildDecorationIcon(top: size.height * 0.05, left: size.width * 0.05, size: 60),    
                  _buildDecorationIcon(top: size.height * 0.02, left: size.width * 0.60, size: 60),   
                  _buildDecorationIcon(top: size.height * 0.26, left: size.width * 0.05, size: 60), 
                  _buildDecorationIcon(top: size.height * 0.21, left: size.width * 0.60, size: 60),

                  Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 15), blurRadius: 150, spreadRadius: -5)]), child: Image.asset('lib/assets/images/wwc.png', width: 320, height: 320, fit: BoxFit.contain))
                ]
              )
            ),
            const Text('Register', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildTextField(label: 'Name', hint: 'Enter your full name', controller: _nameController),
            const SizedBox(height: 15),
            _buildTextField(label: 'Email', hint: 'Enter your email', controller: _emailController),
            const SizedBox(height: 15),
            _buildTextField(label: 'Password', hint: 'Create a password', isPassword: true, controller: _passwordController),
             Row(children: [Checkbox(activeColor: const Color(0xFFFC751D), value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val ?? true)), const Text("Keep me signed in", style: TextStyle(fontSize: 14))]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _handleRegister, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2F2F2), foregroundColor: const Color(0xFFFC751D), elevation: 0, side: const BorderSide(color: const Color(0xFFFC751D), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: const Color(0xFFFC751D)) : const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            
            // Espaço extra para garantir scroll
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}