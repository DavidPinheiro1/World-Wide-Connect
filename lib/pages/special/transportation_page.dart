import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- OBRIGATÓRIO: Importar para abrir links

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database_service.dart';

class TransportationPage extends StatefulWidget {
  const TransportationPage({super.key});

  @override
  State<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends State<TransportationPage> {
  // Controla qual vista está ativa: 'selection', 'student', ou 'non-student'
  String _currentView = 'selection'; 

  // Função para mudar a vista
  void _selectCategory(String category) {
    setState(() {
      _currentView = category;
    });
  }

  // Função para voltar à seleção
  void _resetSelection() {
    setState(() {
      _currentView = 'selection';
    });
  }

  // --- NOVA FUNÇÃO PARA ABRIR LINKS ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGEM DE FUNDO (TRAM)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/tram.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800),
            ),
          ),

          // 2. OVERLAY ESCURO
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6), 
            ),
          ),

          // 3. CONTEÚDO PRINCIPAL
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
                        "Transportation",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      // Bloco da Estrela (Favoritos)
                      StreamBuilder<DocumentSnapshot>(
                        stream: DatabaseService().getSingleTopicStream('transportation_system_topic'),
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
                                  DatabaseService().toggleFavorite('transportation_system_topic', user.uid);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --- CORPO DA PÁGINA ---
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

  // --- VISTA 1: SELEÇÃO ---
  Widget _buildSelectionView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please select your user category:",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildSelectionButton("Student", () => _selectCategory('student')),
            const SizedBox(height: 20),
            _buildSelectionButton("Non-Student", () => _selectCategory('non-student')),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- VISTA 2: DETALHE ---
  Widget _buildDetailView() {
    final bool isStudent = _currentView == 'student';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                isStudent ? "Student" : "Non-Student",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Public transport is the easiest, most affordable, and most sustainable way to move around the city and across Germany. Whether you are a student of the university or an external visitor, there are practical ticket options designed to suit your needs and make daily travel simple and efficient.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const Divider(height: 30, thickness: 1),

            if (isStudent) ...[
              _buildSectionTitle("🎓 Students (University Members)"),
              const Text(
                "Most German universities automatically provide a Semester Ticket (Semesterticket) to their students.\nWe advice you to contact your university to confirm.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("🎫 What is the Semester Ticket?"),
              const Text(
                "The Semester Ticket is a transport pass included in your semester fees. The exact conditions may vary slightly from university to university, but in general it allows:\n\n• Unlimited use of public transport throughout Germany;\n• Valid on regional and local transport (buses, trams, U-Bahn, S-Bahn, RE, RB);\n• Not valid on long-distance or tourist trains such as ICE, IC, or EC.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("Important Notes:"),
              const Text(
                "• The ticket is usually valid for the entire semester;\n• You must always carry your student card (and, if required, a valid ID);\n• The ticket is personal and non-transferable.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ] else ...[
              _buildSectionTitle("👥 External Persons"),
              const Text(
                "If you are a External Persons, you can still easily use public transport by purchasing regular tickets.\n\nExternal users have access to several ticket options, depending on:\n• Duration of travel (single trip, daily, weekly, monthly);\n• Travel zones or regions;\n• Frequency of use.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("🎫 Ticket Prices and Options:"),
              const Text(
                "• Short trip (Kurzstrecke): €1.90 – Up to 3 stops;\n• Standard ticket: €2.40 – Valid for 2 hours;\n• Day ticket: €6.00 – Unlimited travel until 3:00 AM;\n• Monthly pass: €60–80, depending on zones;\n• Subscription (Abo): Save up to 20% with automatic renewal.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("Payment Information:"),
              const Text(
                "• Tickets can be purchased at ticket machines, online, or via official transport apps;\n• Accepted payment methods depend on the provider (cash, card, or digital payment).",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ],

            const Divider(height: 40, thickness: 1, color: Colors.deepOrange),

            _buildSectionTitle("💡 Useful Tips for Everyone"),
            const Text(
              "• Always validate your ticket if required;\n• Keep your ticket accessible during your journey, as inspections are frequent;\n• Fines for traveling without a valid ticket can be high;\n• Official transport apps are highly recommended for route planning and real-time updates (we advice you to use a Navigation App. During our experience, “DB Navigator” was our choise number one!).",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),

            // --- AQUI ESTÁ A ATUALIZAÇÃO DOS LINKS ---
            // Usei os links universais para estas Apps.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAppIcon('Maps.png', "Maps", "https://www.google.com/maps"),
                _buildAppIcon('Db_navigator.png', "DB Navigator", "https://www.bahn.de/"),
                _buildAppIcon('apple_maps_icon.png', "Apple Maps", "http://maps.apple.com/"),
              ],
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("🗓️ Service Schedule"),
            const Text(
              "• Weekdays: Full service from 5:00 AM to 12:00 AM;\n• Saturdays: Full service from 6:00 AM to 1:00 AM;\n• Sundays: Reduced service from 7:00 AM to 11:00 PM;\n• Public Holidays: Sunday schedule applies.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle("🚌 Main Routes in Brandenburg"),
            const Text(
              "From TH Brandenburg\n• Bus 1: To Hauptbahnhof (Main Station) – Every 20 minutes;\n• Bus 6: To City Center – Every 15 minutes;\n• Bus 12: To Görden – Every 30 minutes.\n\nFrom Hauptbahnhof\n• RE1: Berlin ↔ Brandenburg – Every 30 minutes;\n• RB trains: Regional connections to Potsdam;\n• Trams and buses serving all city districts.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Public transport in Germany is reliable, well-connected, and easy to use — making it the best choice for everyday mobility.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.deepOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  // ATUALIZADO: Agora aceita um URL e é clicável
  Widget _buildAppIcon(String imageName, String label, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0,2))]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'lib/assets/images/$imageName', 
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}