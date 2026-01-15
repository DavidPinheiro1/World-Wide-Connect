import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database_service.dart'; 

class CitizenshipPage extends StatefulWidget {
  const CitizenshipPage({super.key});

  @override
  State<CitizenshipPage> createState() => _CitizenshipPageState();
}

class _CitizenshipPageState extends State<CitizenshipPage> {
  // Controla a vista: 'selection', 'eu', 'non-eu'
  String _currentView = 'selection'; 

  void _selectCategory(String category) {
    setState(() {
      _currentView = category;
    });
  }

  void _resetSelection() {
    setState(() {
      _currentView = 'selection';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGEM DE FUNDO (BANDEIRA)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/bandeira.png', 
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800),
            ),
          ),

          // 2. OVERLAY ESCURO
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7), // Um pouco mais escuro para ler melhor
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
                          onPressed: () {
                            if (_currentView == 'selection') {
                              Navigator.pop(context);
                            } else {
                              _resetSelection();
                            }
                          },
                        ),
                      ),
                      const Text(
                        "Citizenship",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      // Bloco da Estrela (Favoritos)
                      StreamBuilder<DocumentSnapshot>(
                        stream: DatabaseService().getSingleTopicStream('citizenship_system_topic'),
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
                                  DatabaseService().toggleFavorite('citizenship_system_topic', user.uid);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // CORPO
                Expanded(
                  child: _currentView == 'selection'
                      ? _buildSelectionView()
                      : _buildDetailView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA SELEÇÃO ---
  Widget _buildSelectionView() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "For New Students in\nBrandenburg an der Havel",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                "When arriving in Germany, one of the first administrative steps you must complete is registering your residence and, depending on your nationality, taking care of your citizenship or residence status. Below you will find practical information to guide you through the process.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 30),
              _buildButton("EU", () => _selectCategory('eu')),
              const SizedBox(height: 15),
              _buildButton("Non-EU", () => _selectCategory('non-eu')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC77148), // Um tom acastanhado/laranja similar ao design
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- VISTA DETALHE ---
  Widget _buildDetailView() {
    final bool isEU = _currentView == 'eu';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Center(
              child: Text(
                isEU ? "EU" : "Non-EU",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // --- INFORMAÇÃO COMUM: MORADA E HORÁRIOS ---
            _buildSectionTitle("Stadtverwaltung Brandenburg an der Havel 🏛️"),
            const SizedBox(height: 10),
            _buildSectionTitle("Where to Go 📍"),
            const Text(
              "Bürgeramt – Brandenburg an der Havel\n📍 Nicolaiplatz 30, 14770\n\nAt the main entrance of the municipal building, there is always an information desk where staff can direct you.\nAlternatively, you may go directly to the first floor, where in the first room on the right you will find an automatic ticket machine to take a waiting number.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 15),

            _buildSectionTitle("Opening Hours ⏰"),
            const Text(
              "Saturday: 08:00 – 12:00\nMonday: 09:00 – 11:30, 13:00 – 15:00\nTuesday: 09:00 – 11:30, 14:00 – 18:00\nWednesday: 09:00 – 11:30\nThursday: 08:00 – 11:30, 13:00 – 15:00\nFriday: 08:00 – 12:00",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 15),

            _buildSectionTitle("Appointments 🗓️"),
            const Text(
              "Making an appointment is possible but not mandatory.\n\nYou can book an appointment online via the official website:\nBürgeramt Brandenburg an der Havel\n\nBooking online is recommended, as your information will already be in the system, which can make the process faster and easier.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const Divider(height: 30, thickness: 1),

            // --- CONTEÚDO ESPECÍFICO (EU vs NON-EU) ---
            if (isEU) ...[
              _buildSectionTitle("Citizens 🇪🇺"),
              _buildSubTitle("What You Need:"),
              const Text(
                "• National ID card (passport is not mandatory).\n• Wohngeberbestätigung (Confirmation from your landlord).\n• University enrolment document.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ] else ...[
              _buildSectionTitle("Citizens 🌍"),
              const Text("The process involves two main steps:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              _buildSubTitle("1. Residence Registration (Anmeldung):"),
              const Text(
                "(This step confirms your address in Germany and is mandatory for everyone)\n\n• Passport.\n• Wohngeberbestätigung (Confirmation from your landlord).\n• University enrolment document.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 15),
              
              _buildSubTitle("2. Residence Permit (Aufenthaltstitel):"),
              const Text(
                "(Non-EU citizens usually also need a residence permit for study purposes)",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  "⚠️ Important:\nThe residence permit is often handled by the Ausländerbehörde (Foreigners’ Office), not directly at the Bürgeramt.\nAfter completing your registration, you may be instructed to book a separate appointment for your residence permit.",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Commonly Required Documents:\n• Valid passport\n• Student visa (if applicable)\n• University enrolment certificate\n• Proof of health insurance\n• Proof of financial resources\n• Registration confirmation (Anmeldebestätigung)",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ],

            const SizedBox(height: 20),

            // --- IMAGENS (ID Card + Doc) ---
            Row(
              children: [
                Expanded(child: _buildImage("idCard.png")),
                const SizedBox(width: 15),
                Expanded(child: _buildImage("documentation.png")),
              ],
            ),
            const SizedBox(height: 20),

            // --- NOTAS FINAIS (COMUM) ---
            _buildSectionTitle("Important Notes:"),
            Text(
              isEU 
              ? "You do not need a residence permit.\nAt the Bürgeramt, you will be asked to sign a document stating the purpose of your stay in Germany (e.g. studies).\nOnce registered, you will receive a registration confirmation (Anmeldebestätigung)."
              : "At the Bürgeramt, you will be asked to sign a document stating the purpose of your stay in Germany (e.g. studies).\nOnce registered, you will receive a registration confirmation (Anmeldebestätigung), which is essential for many other administrative procedures in Germany.",
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            
            const SizedBox(height: 15),
            _buildSectionTitle("Useful Tips 💡:"),
            const Text(
              "• Arrive 10–15 minutes earlier than your appointment time;\n• Bring original documents and, if possible, copies;\n• Double‑check that all forms are fully completed before the appointment;\n• Keep your confirmation email or appointment proof accessible;\n• Public offices can be busy — patience and preparation make the process much smoother.\n\nRegistering early will help you avoid future administrative issues and is often required for opening a bank account, obtaining health insurance, or applying for a residence permit.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),

            const SizedBox(height: 15),
            _buildSectionTitle("Additional Information ℹ️"),
            const Text(
              "🔹 Ground Floor (EG):\nThe ground floor is mainly dedicated to memorial and cultural institutions.\n\n🔹 First Floor (1. OG):\nThis is the main floor for citizens administrative services.\n\n🔹 Second Floor (2. OG):\nThe second floor hosts departments related to public order, security, and traffic administration.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),

            // --- IMAGEM SCHEDULE ---
            _buildImage("schedule.png"),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
    );
  }

  Widget _buildSubTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
    );
  }

  Widget _buildImage(String imageName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'lib/assets/images/$imageName',
        fit: BoxFit.cover,
        errorBuilder: (c,e,s) => Container(
          height: 100, 
          color: Colors.grey.shade200, 
          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
        ),
      ),
    );
  }
}