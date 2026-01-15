import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE
import '../database_service.dart';
import '../widgets/topic_card.dart'; 

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, required this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  final DatabaseService _dbService = DatabaseService();
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      setState(() {
        _currentQuery = widget.initialQuery;
        _searchController.text = widget.initialQuery;
        // Coloca o cursor no fim do texto
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length)
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9), 
        elevation: 0, 
        automaticallyImplyLeading: false, 
        leading: null, 
        title: const Text("Search Results", style: TextStyle(color: Colors.black, fontSize: 16)), 
        centerTitle: true
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // BARRA DE PESQUISA
            Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (val) => setState(() => _currentQuery = val),
                
                // --- ESTILO DO TEXTO (AR ONE SANS) ---
                style: GoogleFonts.arOneSans(
                  fontSize: 16, 
                  color: Colors.black
                ),

                decoration: InputDecoration(
                  hintText: "Search for Topics", 
                  
                  // --- ESTILO DO PLACEHOLDER (AR ONE SANS) ---
                  hintStyle: GoogleFonts.arOneSans(
                    fontSize: 16, 
                    color: Colors.grey.shade500
                  ),

                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.zero, 
                  prefixIcon: const Icon(Icons.search, color: const Color(0xFFFC751D)), 
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20), 
                    onPressed: () { 
                      // LÓGICA DO BOTÃO X
                      _searchController.clear(); 
                      setState(() => _currentQuery = ""); 
                      // Ao limpar, a lista volta ao normal (alfabética) sem saltar
                    }
                  )
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // LISTA DE RESULTADOS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _dbService.getTopicsStream(), 
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  // 1. Criar uma cópia da lista
                  List<DocumentSnapshot> docs = List.from(snapshot.data!.docs);
                  
                  // 2. Lógica de Filtro
                  if (_currentQuery.isNotEmpty) {
                    // SE TIVER PESQUISA: Filtra pelo nome
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'].toString().toLowerCase();
                      return title.contains(_currentQuery.toLowerCase());
                    }).toList();
                  } else {
                    // --- MUDANÇA IMPORTANTE AQUI ---
                    // Antes tinhas docs.shuffle(). ISSO ERA O ERRO.
                    // Agora ordenamos alfabeticamente. Assim a lista fica estável.
                    docs.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      final titleA = (dataA['title'] ?? "").toString().toLowerCase();
                      final titleB = (dataB['title'] ?? "").toString().toLowerCase();
                      return titleA.compareTo(titleB);
                    });
                  }

                  if (docs.isEmpty) return Center(child: Text("No topics found.", style: TextStyle(color: Colors.grey.shade500)));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        // O TopicCard trata da estrela sozinho sem afetar a ordem aqui
                        // Importante: margin: EdgeInsets.zero para ocupar a largura toda
                        child: TopicCard(
                          topicId: docId, 
                          data: data,
                          margin: EdgeInsets.zero, // <--- ADICIONADO PARA CORRIGIR LARGURA
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}