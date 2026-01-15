import 'dart:ui';
import 'package:flutter/material.dart';

// Input de Texto Genérico
Widget buildTextField({
  required String label, 
  required String hint, 
  bool isPassword = false, 
  TextEditingController? controller
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, 
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint, 
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: const Color(0xFFFC751D))),
        ),
      ),
    ],
  );
}

// Imagem desfocada de fundo
Widget buildBlurredImage({required double top, required double left, required double size}) {
  return Positioned(
    top: top, 
    left: left,
    child: Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: const Color(0xFFFC751D).withOpacity(0.3), blurRadius: 30, spreadRadius: 0)]),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), 
        child: Opacity(
          opacity: 0.5, 
          child: Image.asset('lib/assets/images/wwc.png', width: size, height: size)
        )
      ),
    ),
  );
}