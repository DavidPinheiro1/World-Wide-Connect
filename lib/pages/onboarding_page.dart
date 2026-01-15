import 'package:flutter/material.dart';
import 'dart:ui' as ui; 
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE PARA CONSISTÊNCIA
import 'profile_setup_page.dart'; 

class OnboardingPage extends StatefulWidget {
  // 1. Receber os dados do Registo
  final String name;
  final String email;

  const OnboardingPage({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildIntroPage(),          // Slide 1
      _buildFindingHelpPage(),    // Slide 2
      _buildQRScannerPage(),      // Slide 3
      _buildCreateTopicPage(),    // Slide 4
      _buildFinalPage(),          // Slide 5
    ];
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Lógica Final: Ir para o Setup de Perfil
  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    
    // Passar os dados para a próxima página
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupPage(
          name: widget.name, 
          email: widget.email
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (Botão Voltar) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    )
                  else
                    const SizedBox(height: 40, width: 40),

                  const Spacer(),
                ],
              ),
            ),

            // --- SLIDES ---
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: _pages,
              ),
            ),

            // --- BOTÕES INFERIORES ---
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1 ? _finishOnboarding : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC751D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 0 ? "Get Started" : 
                        _currentPage == _pages.length - 1 ? "Let's Start" : "Next",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _finishOnboarding, // Skip também leva ao fim
                    child: const Text(
                      "skip",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================ SLIDE 1: INTRODUÇÃO ==========================
  Widget _buildIntroPage() {
    return Stack(
      children: [
        _buildBackgroundWWC(),
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10), 
              const Text("World Wide Connect",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(0xFFFC751D), fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "With our App, We give you\nthe best solutions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 25), 
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F0), 
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    _buildIntroRow("Finding Help", Icons.search),
                    const SizedBox(height: 25),
                    _buildIntroRow("Scan Our QR Codes", Icons.camera_alt_outlined),
                    const SizedBox(height: 25),
                    _buildIntroRow("Creating Your Own Topic", Icons.add_circle_outline),
                  ],
                ),
              ),
              const SizedBox(height: 250), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroRow(String text, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        Icon(icon, size: 28, color: Colors.black),
      ],
    );
  }

  // ============================ SLIDE 2: FINDING HELP ==========================
  Widget _buildFindingHelpPage() {
    return Stack(
      children: [
        _buildBackgroundWWC(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("Finding Help", style: TextStyle(color: const Color(0xFFFC751D), fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("With only a few clicks!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0), 
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search, color: const Color(0xFFFC751D), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Icon(Icons.arrow_upward, color: Colors.black, size: 24),
                      const SizedBox(height: 15),
                      const Text(
                        "You can search for the topic that is being hard on you, tranportation or even citizenship procedures, and be able to find out that there is a very practical solution for it.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "If you can't find it, create your own!\nThere might be someone out there that is able to help you out!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRoundedImage('lib/assets/images/tram.png', width: 170, height: 108),
                    _buildRoundedImage('lib/assets/images/bandeira.png', width: 170, height: 108),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ SLIDE 3: QR SCANNER ============================
  Widget _buildQRScannerPage() {
    return Stack(
      children: [
        _buildBackgroundWWC(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("QR Code Scanner", style: TextStyle(color: const Color(0xFFFC751D), fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Go for a walk and find them outside!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: const Color(0xFFFC751D), size: 60),
                          const SizedBox(width: 20),
                          _buildRoundedImage('lib/assets/images/tele_qr_code.png', width: 170, height: 108),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Go for a walk and you might find a simple and practical solution to your problem, all you need to start solving it, is your camera!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildRoundedImage('lib/assets/images/mensa_card.png', width: 170, height: 108),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text("How does\nMensa work?", textAlign: TextAlign.left, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), 
                      Row(
                        children: [
                          const Expanded(
                            child: Text("What? Repair my\nbike for free?", textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 15),
                          _buildRoundedImage('lib/assets/images/casa.png', width: 170, height: 108),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ SLIDE 4: CREATE TOPIC ==========================
  Widget _buildCreateTopicPage() {
    return Stack(
      children: [
        _buildBackgroundWWC(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("Create Your Topic", style: TextStyle(color: const Color(0xFFFC751D), fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Ask for help on something you need!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 25), 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0), 
                    borderRadius: BorderRadius.circular(30), 
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFC751D), width: 1.5)),
                        child: const Icon(Icons.add, color: const Color(0xFFFC751D), size: 28),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Title", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 5),
                            
                            // --- INPUT TÍTULO SIMULADO ---
                            Container(
                                height: 40,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                                child: Align(
                                  alignment: Alignment.centerLeft, 
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10), 
                                    // AQUI: Texto vazio e fonte AR One Sans
                                    child: Text("", style: GoogleFonts.arOneSans(color: Colors.grey, fontSize: 13))
                                  )
                                )
                            ),
                            
                            const SizedBox(height: 15),
                            const Text("Description", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 5),
                            Container(height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8))),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: const Color(0xFFFC751D)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: const Text("Submit", style: TextStyle(color: const Color(0xFFFC751D))),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "With a simple topic creation, you can get in contact with people that will be able to help you figure out what's best for you!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ SLIDE 5: FINAL =================================
  Widget _buildFinalPage() {
    return Stack(
      children: [
        _buildBackgroundWWC(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("Let's use the App!", style: TextStyle(color: const Color(0xFFFC751D), fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Now you will be able to try it out, don't forget to go outside, you might find new practical solutions for your problems!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  height: 460, 
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0), 
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Positioned(top: 30, right: 20, child: _buildRoundedImage('lib/assets/images/tele_qr_code.png', width: 180, height: 115)),
                      const Positioned(top: 60, right: 240, child: Icon(Icons.camera_alt_outlined, color: const Color(0xFFFC751D), size: 70)),
                      Positioned(top: 170, left: 11, child: _buildRoundedImage('lib/assets/images/tram.png', width: 155, height: 108)),
                      Positioned(top: 170, right: 11, child: _buildRoundedImage('lib/assets/images/bandeira.png', width: 155, height: 108)),
                      Positioned(bottom: 40, left: 35, child: _buildRoundedImage('lib/assets/images/casa.png', width: 155, height: 108)),
                      const Positioned(bottom: 60, left: 235, child: Icon(Icons.search, color: const Color(0xFFFC751D), size: 70)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ HELPERS ======================================

  Widget _buildRoundedImage(String path, {required double width, required double height}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))),
      ),
    );
  }

  Widget _buildBackgroundWWC() {
    return Positioned(
      bottom: -60, 
      left: 0,
      right: 0,
      height: 420, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildBlurredSatellite(top: 50, left: 30, size: 45),      
          _buildBlurredSatellite(top: 20, right: 50, size: 40),     
          _buildBlurredSatellite(bottom: 90, left: 20, size: 50),   
          _buildBlurredSatellite(bottom: 40, right: 40, size: 45),  
          Opacity(
            opacity: 0.15, 
            child: Image.asset('lib/assets/images/wwc.png', fit: BoxFit.contain, height: 310, errorBuilder: (c,e,s) => const SizedBox()),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredSatellite({double? top, double? bottom, double? left, double? right, required double size}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: 0.1, 
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3), 
          child: Image.asset('lib/assets/images/wwc.png', width: size, height: size, errorBuilder: (c,e,s) => const SizedBox()),
        ),
      ),
    );
  }
}