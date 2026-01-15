import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir os links

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database_service.dart';

class MensaPage extends StatefulWidget {
  const MensaPage({super.key});

  @override
  State<MensaPage> createState() => _MensaPageState();
}

class _MensaPageState extends State<MensaPage> {
  // Controla a vista: 'selection', 'student', 'staff', 'external'
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

  // Função auxiliar para abrir links
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Se falhar, apenas imprime no console (ou podes mostrar um SnackBar)
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGEM DE FUNDO
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Mensa_fh_brandenburg.jpg', // Confirma se é .jpg ou .png na tua pasta
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800),
            ),
          ),

          // 2. OVERLAY ESCURO
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7), // Fundo escuro para ler o texto
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
                        "Mensa",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      // Bloco da Estrela (Favoritos)
                      StreamBuilder<DocumentSnapshot>(
                        stream: DatabaseService().getSingleTopicStream('mensa_system_topic'),
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
                                  DatabaseService().toggleFavorite('mensa_system_topic', user.uid);
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
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              _buildButton("Student", () => _selectCategory('student')),
              const SizedBox(height: 15),
              _buildButton("University Staff", () => _selectCategory('staff')),
              const SizedBox(height: 15),
              _buildButton("Non-Student", () => _selectCategory('external')),
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
          backgroundColor: Colors.deepOrange, // Cor tema da app
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
    String title = "";
    if (_currentView == 'student') title = "Student";
    else if (_currentView == 'staff') title = "University Staff";
    else title = "Non-Student";

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
            // Título Categoria
            Center(
              child: Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // --- INTRODUÇÃO (COMUM) ---
            _buildSectionTitle("Welcome to the Mensa! 🍜🥗"),
            const Text(
              "The Mensa is your university canteen, a modern and welcoming space where you can enjoy complete, healthy, and affordable meals. Every day, several lunch options are offered, ranging from traditional menus to vegetarian and vegan dishes, ensuring there are alternatives for all tastes and dietary needs.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 15),

            // --- LAYOUT (COMUM) ---
            _buildSectionTitle("The Mensa Building Layout"),
            const Text(
              "The Mensa has outdoor tables for those who prefer to eat outdoors.\nUpon entering the building, there are more dining tables on the left side.\nOn the right side is the ASTA (Student Union).\n\nGoing up to the first floor, you will find:\n• The food collection area;\n• The main dining area;\n• Microwaves, available for heating food brought from home;\n• The tray drop-off location.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            
            const Divider(height: 30, thickness: 1),

            // --- INFORMAÇÃO ESPECÍFICA (VARIÁVEL) ---
            if (_currentView == 'student') ...[
              _buildSectionTitle("Information for Students 🎓"),
              const Text(
                "To benefit from the reduced student price, it is mandatory to present your student card.\nIf the card does not have a balance, you can top it up on-site before making the payment.\n\nNote: Cash is required to top up the card.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ] else if (_currentView == 'staff') ...[
              _buildSectionTitle("Information for Staff 🧑‍🏫"),
              const Text(
                "Staff members must bring their staff card, which grants access to the specific price for this category.\nIf the card does not have a balance, you can top it up on-site before making the payment.\n\nNote: Cash is required to top up the card.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ] else ...[
              _buildSectionTitle("Information for External Persons 👥"),
              const Text(
                "People who are neither students nor staff can also use the Mensa.\nExternal persons pay a different rate, according to the external price list, as they do not benefit from the discounts given to students and staff.\nAt the payment area, you only need to pay the full price of the meal.\n\nNote: Cash is required to make the payment.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ],

            const Divider(height: 30, thickness: 1),

            // --- APPS & LINKS (COMUM) ---
            _buildSectionTitle("How the Online Menu and App Work 💻📱"),
            const Text(
              "The Mensa provides the weekly menu online, allowing you to conveniently check the meals and their respective prices.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 10),
            
            _buildSubTitle("Access via the Website"),
            GestureDetector(
              onTap: () => _launchURL("https://www.stwwb.de/en/food-co/menu/app"),
              child: const Text(
                "https://www.stwwb.de/en/food-co/menu/app",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Scroll down the page until you find the “Go to the online menu” button;\nClick the button and fill in the requested information.\n\nOn the website, you can:\n• Consult the menus for each day of the week;\n• Filter dishes by allergies and dietary preferences.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text(
                "When certain filters are active, menus that appear greyed out contain ingredients that do not match your preferences.",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ),
            
            const SizedBox(height: 20),
            _buildSubTitle("Access via the App 📱"),
            const Text(
              "It is also possible to consult all this information through mobile applications. The application from the first link is recommended as it is more intuitive.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 15),

            _buildLinkButton("Recommended Mensa App", "https://swp.konkaapps.de/kms-mt-link/9F162EB1766163AE1428AABFEF0CAE67"),
            _buildLinkButton("Mensa App (iOS)", "https://apps.apple.com/at/app/mensa/id1607858145"),
            _buildLinkButton("Mensa App (Android)", "https://play.google.com/store/apps/details?id=de.imensa.app.android"),

            const SizedBox(height: 15),
            const Text(
              "In the apps, you can:\n• Consult the daily menus;\n• View ingredients and allergens;\n• Filter meals according to dietary preferences;\n• Plan the week's meals in advance.",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, top: 5.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildLinkButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _launchURL(url),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.deepOrange),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: Colors.deepOrange, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.open_in_new, size: 16, color: Colors.deepOrange)
            ],
          ),
        ),
      ),
    );
  }
}