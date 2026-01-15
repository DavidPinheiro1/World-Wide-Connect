import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database_service.dart';

class BicyclesPage extends StatelessWidget {
  const BicyclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGEM DE FUNDO
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Bicycles for a good price.png', // Nome exato do teu ficheiro
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800),
            ),
          ),

          // 2. OVERLAY ESCURO
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7), // Escurece para ler o texto
            ),
          ),

          // 3. CONTEÚDO
          SafeArea(
            child: Column(
              children: [
                // HEADER (Substitui todo este bloco)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "Bicycles for a good price",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Bloco da Estrela (Favoritos)
                      StreamBuilder<DocumentSnapshot>(
                        stream: DatabaseService().getSingleTopicStream('bicycle_system_topic'),
                        builder: (context, snapshot) {
                          bool isFavorite = false;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final List favs = data['favoritedBy'] is List ? data['favoritedBy'] : [];
                            isFavorite = favs.contains(FirebaseAuth.instance.currentUser?.uid);
                          }
                          return CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: IconButton(
                              icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.deepOrange : Colors.white),
                              onPressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  DatabaseService().toggleFavorite('bicycle_system_topic', user.uid);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --- TEXTO ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título Principal
                          const Center(
                            child: Text(
                              "Get Your Bicycle for a Great Price in Brandenburg!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.deepOrange
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "Looking for an affordable, fully functional bicycle in Brandenburg an der Havel? There's a fantastic community initiative that's been helping locals since 2017!",
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                          ),
                          
                          const Divider(height: 30, thickness: 1),

                          _buildSectionTitle("Where to Find It 📍"),
                          const Text(
                            "Head to Haus der Offiziere in Brandenburg, conveniently located near TH Brandenburg. Once you arrive, you'll find a QR code with all the details you need about this wonderful service.",
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                          ),

                          const SizedBox(height: 20),

                          _buildSectionTitle("What They Offer 🚲"),
                          const Text(
                            "This volunteer-run initiative provides two excellent services:",
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                          ),
                          const SizedBox(height: 10),
                          _buildBulletPoint("Buy a Cheap Bicycle", "Get a completely functional bike at an affordable price, perfect for students, newcomers, or anyone on a budget."),
                          const SizedBox(height: 10),
                          _buildBulletPoint("Free Repairs", "Already have a bicycle that needs fixing? Bring it along and they'll repair it for you at no cost!"),

                          const Divider(height: 30, thickness: 1),

                          _buildSectionTitle("Important Details ℹ️"),
                          const Text(
                            "• When: Tuesdays only\n• Cost: bicycles for 15€, repairs completely free.",
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200)
                            ),
                            child: const Text(
                              "Pro Tip: This service is popular and lines can get long! Call ahead using the mobile number on the QR code to reserve your spot and save time.",
                              style: TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildBulletPoint(String title, String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        children: [
          const TextSpan(text: "• "),
          TextSpan(text: "$title – ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text),
        ],
      ),
    );
  }
}