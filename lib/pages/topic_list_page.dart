import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necessário para obter o ID do user
import '../widgets/topic_card.dart';

class TopicListPage extends StatefulWidget {
  final String title;
  final List<DocumentSnapshot> topics;

  const TopicListPage({super.key, required this.title, required this.topics});

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  // Lista local para podermos remover itens visualmente sem recarregar a página
  late List<DocumentSnapshot> _displayedTopics;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    // Criamos uma cópia da lista que vem do widget para podermos manipulá-la
    _displayedTopics = List.from(widget.topics);
  }

  // Função para remover o tópico da lista e da base de dados
  Future<void> _removeItem(String topicId) async {
    if (currentUserId.isEmpty) return;

    // 1. Atualiza a UI imediatamente
    setState(() {
      _displayedTopics.removeWhere((doc) => doc.id == topicId);
    });

    // 2. Remove o ID do utilizador do array 'seenBy' no Firebase
    try {
      await FirebaseFirestore.instance.collection('topics').doc(topicId).update({
        'seenBy': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      print("Erro ao remover dos vistos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificamos se estamos na página "Recently Seen" para ativar a cruz
    final bool isRecentlySeenPage = widget.title == "Recently Seen";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _displayedTopics.isEmpty
          ? Center(
              child: Text(
                "No topics found for ${widget.title}.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              // Este padding de 20 define a margem lateral da lista inteira
              padding: const EdgeInsets.all(20),
              itemCount: _displayedTopics.length,
              itemBuilder: (context, index) {
                final doc = _displayedTopics[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15), // Espaço entre cartões
                  child: TopicCard(
                    topicId: doc.id, 
                    data: data,
                    // CORREÇÃO DE MARGENS:
                    // Passamos margem zero para o cartão preencher a largura dada pelo ListView
                    margin: EdgeInsets.zero,
                    // LÓGICA DA CRUZ:
                    // Só passamos a função se for a página "Recently Seen"
                    onRemove: isRecentlySeenPage 
                        ? () => _removeItem(doc.id) 
                        : null,
                  ),
                );
              },
            ),
    );
  }
}