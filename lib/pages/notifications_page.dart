import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/topic_card.dart'; // Garante que este import está correto para o teu projeto

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _deleteNotification(String userId, String notificationId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').doc(notificationId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text("Please log in"))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- 1. LISTA DE TÓPICOS SUBSCRITOS (NO TOPO) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: const Text("Topics with notifications active", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  
                  SizedBox(
                    height: 220, // Altura suficiente para os cartões
                    child: StreamBuilder<QuerySnapshot>(
                      // Procura tópicos onde o meu ID está na lista 'subscribedBy'
                      stream: FirebaseFirestore.instance
                          .collection('topics')
                          .where('subscribedBy', arrayContains: userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final topics = snapshot.data!.docs;

                        if (topics.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                            child: Center(child: Text("You are not following any topics.", style: TextStyle(color: Colors.grey.shade400))),
                          );
                        }

                        // Lista Horizontal
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          scrollDirection: Axis.horizontal,
                          itemCount: topics.length,
                          itemBuilder: (context, index) {
                            final topicData = topics[index].data() as Map<String, dynamic>;
                            return Container(
                              width: 280, 
                              margin: const EdgeInsets.only(right: 10),
                              child: TopicCard(topicId: topics[index].id, data: topicData),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const Divider(height: 40, thickness: 1),

                  // --- 2. LISTA DE NOTIFICAÇÕES (MENSAGENS RECENTES) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text("Recent Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(); // Carregando...
                      final docs = snapshot.data!.docs;
                      
                      if (docs.isEmpty) {
                         return Padding(
                           padding: const EdgeInsets.all(40.0),
                           child: Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey.shade400))),
                         );
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(), // Scroll controlado pela página toda
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(15),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          // Formatar data (opcional)
                          String timeAgo = "";
                          if (data['timestamp'] != null) {
                            final ts = (data['timestamp'] as Timestamp).toDate();
                            timeAgo = "${ts.day}/${ts.month} ${ts.hour}:${ts.minute.toString().padLeft(2,'0')}";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFC751D).withOpacity(0.1),
                                child: const Icon(Icons.notifications, color: const Color(0xFFFC751D), size: 20),
                              ),
                              title: Text(data['title'] ?? "Notification", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['message'] ?? "", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  Text(timeAgo, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), 
                                onPressed: () => _deleteNotification(userId, docs[index].id)
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30), // Espaço no fundo
                ],
              ),
            ),
    );
  }
}