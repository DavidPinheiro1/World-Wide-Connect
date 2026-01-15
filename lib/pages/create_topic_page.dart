import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT DA FONTE
import '../../database_service.dart';
import '../../auth_service.dart';
import 'services/good_behavior_service.dart'; // <--- IMPORT DO FILTRO

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({super.key});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _submitTopic() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) return;
    
    // --- NOVO: FILTRO DE BOM COMPORTAMENTO ---
    final validator = GoodBehaviorService();

    if (validator.isOffensive(title)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Title contains inappropriate language."),
            backgroundColor: Colors.red,
          )
        );
      }
      return;
    }

    if (validator.isOffensive(description)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Description contains inappropriate language."),
            backgroundColor: Colors.red,
          )
        );
      }
      return;
    }
    // ------------------------------------------
    
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _dbService.createTopic({
          'title': title,
          'description': description,
          'authorId': user.uid,
          'authorName': user.displayName ?? "Anonymous",
          'createdAt': DateTime.now(), 
          'seenBy': [],
          'favoritedBy': [],
          'isUserCreated': true,
          'type': 'general',
          'imageUrl': 'https://via.placeholder.com/300',
        });
        
        // GAMIFICAÇÃO
        await _dbService.incrementUserLevel(user.uid);
        
        if (mounted) {
          // --- NOTIFICAÇÃO MODERNA ---
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              backgroundColor: const Color(0xFFFC751D),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Topic Created! +10 Points",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // ---------------------------

          _titleController.clear();
          _descriptionController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Título da página -> Montserrat (Padrão do sistema)
        title: const Text("Create Topic"), 
        centerTitle: true, 
        automaticallyImplyLeading: false
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline, size: 80, color: const Color(0xFFFC751D)),
            const SizedBox(height: 20),
            // Texto estático -> Montserrat (Padrão do sistema)
            const Text(
              "Share something interesting!", 
              style: TextStyle(fontSize: 16, color: Colors.grey)
            ),
            const SizedBox(height: 30),
            
            // --- CAMPO TÍTULO ---
            TextField(
              controller: _titleController, 
              // INPUT DO UTILIZADOR -> AR ONE SANS
              style: GoogleFonts.arOneSans(fontSize: 16, color: Colors.black),
              decoration: InputDecoration(
                labelText: "Title", 
                // RÓTULO DO CAMPO -> AR ONE SANS (Para consistência visual dentro da caixa)
                labelStyle: GoogleFonts.arOneSans(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                prefixIcon: const Icon(Icons.title, color: const Color(0xFFFC751D))
              )
            ),
            
            const SizedBox(height: 20),
            
            // --- CAMPO DESCRIÇÃO ---
            TextField(
              controller: _descriptionController, 
              maxLines: 5, 
              // INPUT DO UTILIZADOR -> AR ONE SANS
              style: GoogleFonts.arOneSans(fontSize: 16, color: Colors.black),
              decoration: InputDecoration(
                labelText: "Description", 
                // RÓTULO DO CAMPO -> AR ONE SANS
                labelStyle: GoogleFonts.arOneSans(color: Colors.grey),
                alignLabelWithHint: true, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              )
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTopic, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC751D), 
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ), 
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  // Botão -> Montserrat (Padrão do sistema)
                  : const Text("Post Topic", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              )
            ),
          ],
        ),
      ),
    );
  }
}