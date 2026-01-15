import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database_service.dart';

// --- IMPORTANTE: Importar as 3 páginas especiais ---
import 'special/mensa_page.dart';
import 'special/transportation_page.dart';
import 'special/citizenship_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanning = true;
  final DatabaseService _dbService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botão de Voltar
            Align(
              alignment: Alignment.topLeft, 
              child: Padding(
                padding: const EdgeInsets.all(20.0), 
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black), 
                  onPressed: () => Navigator.pop(context)
                )
              )
            ),
            
            const SizedBox(height: 10),
            const Text('Scan & Explore', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFFC751D))),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40), 
              child: Text(
                "Point your camera at any QR code to find out information.\nDon't have a QR code? Browse our featured offers.", 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)
              )
            ),
            const SizedBox(height: 40),
            
            // Área do Scanner
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        MobileScanner(
                          onDetect: (capture) {
                            if (!_isScanning) return;
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              String code = barcodes.first.rawValue ?? "";
                              setState(() => _isScanning = false); // Pausa o scanner para não ler várias vezes
                              _handleQrCode(context, code);
                            }
                          },
                        ),
                        // Moldura visual
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2), 
                            borderRadius: BorderRadius.circular(30)
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Botão para reiniciar o scan
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30), 
              child: SizedBox(
                width: double.infinity, height: 55, 
                child: ElevatedButton(
                  onPressed: () { setState(() { _isScanning = true; }); }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F2F2), 
                    foregroundColor: const Color(0xFFFC751D), 
                    elevation: 0, 
                    side: BorderSide(color: const Color(0xFFFC751D).withOpacity(0.3)), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ), 
                  child: Text('Scan Code', style: TextStyle(color: const Color(0xFFFC751D), fontSize: 18, fontWeight: FontWeight.w500))
                )
              )
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE RECONHECIMENTO DOS QR CODES ---
  void _handleQrCode(BuildContext context, String code) {
    String cleanCode = code.toLowerCase().trim();

    // 1. Lógica para MENSA
    if (cleanCode.contains("mensa")) {
      if (_currentUserId.isNotEmpty) {
        _dbService.markAsSeen("mensa_system_topic", _currentUserId);
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MensaPage()));
    } 
    
    // 2. Lógica para TRANSPORTE (Adicionado agora)
    else if (cleanCode.contains("transport")) {
      if (_currentUserId.isNotEmpty) {
        // Usa o ID exato que criaste no Firebase
        _dbService.markAsSeen("transportation_system_topic", _currentUserId);
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => const TransportationPage()));
    }

    // 3. Lógica para CIDADANIA (Adicionado agora)
    else if (cleanCode.contains("citizen") || cleanCode.contains("registration")) {
      if (_currentUserId.isNotEmpty) {
        // Usa o ID exato que criaste no Firebase
        _dbService.markAsSeen("citizenship_system_topic", _currentUserId);
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CitizenshipPage()));
    }

    // 4. Se não reconhecer nada
    else {
      _showResult(context, "QR Code: $code\n(Topic not recognized)");
    }
  }

  void _showResult(BuildContext context, String message) {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        title: const Text("Result"), 
        content: Text(message), 
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _isScanning = true); }, 
            child: const Text("Scan Again")
          ), 
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC751D)), 
            child: const Text("OK", style: TextStyle(color: Colors.white))
          )
        ]
      )
    );
  }
}