import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database_service.dart';
import '../pages/topic_detail_page.dart';
import '../pages/special/mensa_page.dart';
import '../pages/special/transportation_page.dart';
import '../pages/special/citizenship_page.dart';
import '../pages/special/bicycles_page.dart';

class TopicCard extends StatelessWidget {
  final String topicId;
  final Map<String, dynamic> data;
  final DatabaseService _dbService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Callback opcional para remover o card
  final VoidCallback? onRemove;
  
  // NOVO: Margem opcional para controlar o espaçamento externo
  final EdgeInsetsGeometry? margin;

  TopicCard({
    super.key,
    required this.topicId,
    required this.data,
    this.onRemove,
    this.margin, // Adicionado ao construtor
  });

  @override
  Widget build(BuildContext context) {
    bool isUserCreated = data['isUserCreated'] ?? false;
    
    // Altura unificada
    const double cardHeight = 210.0;
    
    // Margem por defeito (com espaço à direita para listas horizontais)
    // Se 'this.margin' for fornecido (ex: nos favoritos), usamos esse.
    final effectiveMargin = margin ?? const EdgeInsets.only(right: 15, bottom: 10);

    // Verificação de "Visto"
    List seenBy = [];
    if (data['seenBy'] != null && data['seenBy'] is List) {
      seenBy = data['seenBy'];
    }
    bool isSeen = seenBy.contains(currentUserId);
    Color buttonTextColor = isSeen ? const Color(0xFF007AFF) : const Color(0xFF34C759);
    Color buttonBorderColor = isSeen ? const Color(0xFF007AFF).withOpacity(0.5) : const Color(0xFF34C759).withOpacity(0.5);

    // --- LÓGICA DE NAVEGAÇÃO ---
    void onCardTap() {
      if (!isSeen && currentUserId.isNotEmpty) {
        _dbService.markAsSeen(topicId, currentUserId);
      }

      if (topicId == 'mensa_system_topic') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MensaPage()));
      } else if (topicId == 'transportation_system_topic') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TransportationPage()));
      } else if (topicId == 'citizenship_system_topic') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CitizenshipPage()));
      } else if (topicId == 'bicycle_system_topic') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BicyclesPage()));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicDetailPage(topicId: topicId, topicData: data),
          ),
        );
      }
    }

    // --- WIDGET DA ESTRELA "INTELIGENTE" ---
    Widget buildFavoriteStar({Color colorWhenSelected = const Color(0xFFFC751D)}) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _dbService.getSingleTopicStream(topicId),
        builder: (context, snapshot) {
          bool isFav = false;

          if (snapshot.hasData && snapshot.data!.exists) {
            final freshData = snapshot.data!.data() as Map<String, dynamic>;
            final List favs = (freshData['favoritedBy'] is List) ? freshData['favoritedBy'] : [];
            isFav = favs.contains(currentUserId);
          } else {
            final List favs = (data['favoritedBy'] is List) ? data['favoritedBy'] : [];
            isFav = favs.contains(currentUserId);
          }

          return GestureDetector(
            onTap: () {
              if (currentUserId.isNotEmpty) {
                _dbService.toggleFavorite(topicId, currentUserId);
              }
            },
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? colorWhenSelected : Colors.white,
              size: 24,
              shadows: const [Shadow(blurRadius: 2, color: Colors.black45)],
            ),
          );
        },
      );
    }

    // --- BOTÃO DE REMOVER (X) ---
    Widget buildRemoveButton() {
      if (onRemove == null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    }

    // --- DESIGN A: Tópico Criado por Utilizador ---
    if (isUserCreated) {
      return Stack(
        children: [
          GestureDetector(
            onTap: onCardTap,
            child: Container(
              height: cardHeight, 
              margin: effectiveMargin, // Usamos a margem dinâmica
              padding: EdgeInsets.fromLTRB(20, onRemove != null ? 35.0 : 20.0, 20, 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6D5C52), Color(0xFF4A4A4A)],
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? "No Title",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      buildFavoriteStar(colorWhenSelected: const Color(0xFFFC751D)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  Text(
                    "Created by ${data['authorName'] ?? 'Unknown'}",
                    style: const TextStyle(color: Color(0xFFFC751D), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: Text(
                      data['description'] ?? "", 
                      maxLines: 4, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(border: Border.all(color: buttonBorderColor), borderRadius: BorderRadius.circular(20), color: Colors.black12),
                      child: Text("See Task", style: TextStyle(color: buttonTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 10,
              left: 10,
              child: buildRemoveButton(),
            ),
        ],
      );
    }

    // --- DESIGN B: Tópico de Sistema ---
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        height: cardHeight,
        margin: effectiveMargin, // Usamos a margem dinâmica
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                data['imageUrl'] ?? "https://via.placeholder.com/150",
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: buildFavoriteStar(colorWhenSelected: const Color(0xFFFC751D)),
            ),

            if (onRemove != null)
              Positioned(
                top: 10,
                left: 10,
                child: buildRemoveButton(),
              ),

            Positioned(
              bottom: 10,
              left: 15,
              right: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? "No Title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(
                    data['description'] ?? "", 
                    style: const TextStyle(color: Colors.white70, fontSize: 11), 
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, border: Border.all(color: buttonBorderColor), borderRadius: BorderRadius.circular(20)),
                      child: Text("See Task", style: TextStyle(color: buttonTextColor, fontSize: 11)),
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
}