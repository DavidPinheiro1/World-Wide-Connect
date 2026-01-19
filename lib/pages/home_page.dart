import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../database_service.dart';
import '../widgets/topic_card.dart';
import 'profile_page.dart';
import 'topic_list_page.dart';
import 'notifications_page.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT DA FONTE

class HomePageWidget extends StatefulWidget {
  final Function(String) onSearchSubmitted;

  const HomePageWidget({super.key, required this.onSearchSubmitted});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final AuthService _auth = AuthService();
  final DatabaseService _dbService = DatabaseService();
  ImageProvider? _avatarImage;
  bool _showDefaultIcon = false;

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _dbService.getUserData(user.uid);
        if (userData != null && userData['imageBase64'] != null && (userData['imageBase64'] as String).isNotEmpty) {
          if (mounted) setState(() { _avatarImage = MemoryImage(base64Decode(userData['imageBase64'])); _showDefaultIcon = false; });
        } else if (user.photoURL != null) {
          if (mounted) setState(() { _avatarImage = NetworkImage(user.photoURL!); _showDefaultIcon = false; });
        } else { if (mounted) setState(() => _showDefaultIcon = true); }
      } catch (e) { if (mounted) setState(() => _showDefaultIcon = true); }
    }
  }

  void _navigateToSeeAll(String title, List<DocumentSnapshot> topics) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TopicListPage(title: title, topics: topics)));
  }

  List<String> _getSafeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePageWidget())).then((_) => _loadUserAvatar()),
                    child: CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade300, backgroundImage: _avatarImage, child: (_avatarImage == null || _showDefaultIcon) ? const Icon(Icons.person, color: Colors.white) : null),
                  ),

                  // BOTÃO DE NOTIFICAÇÕES
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null ? _dbService.getUserStream(user.uid) : null,
                    builder: (context, snapshot) {
                      Color bellColor = Colors.grey; 
                      
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        bool isEnabled = data['notificationsEnabled'] ?? false;
                        bellColor = isEnabled ? const Color(0xFFFC751D) : Colors.grey;
                      }

                      return IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsPage()),
                          );
                        },
                        icon: Icon(
                          Icons.notifications, 
                          size: 28, 
                          color: bellColor, 
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // SEARCH
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center, 
                  textInputAction: TextInputAction.search,
                  
                  // --- ESTILO DO TEXTO QUE O UTILIZADOR ESCREVE (AR ONE SANS) ---
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
                    suffixIcon: const Icon(Icons.search, color: Color(0xFFFC751D)), 
                    contentPadding: EdgeInsets.zero
                  ),
                  onSubmitted: (value) {
                    widget.onSearchSubmitted(value);
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // CONTEÚDO
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getTopicsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final allTopicsDocs = snapshot.data!.docs;
                    
                    final myTopics = allTopicsDocs.where((doc) { try { return doc.get('authorId') == user?.uid && doc.get('type') != 'system'; } catch (e) { return false; } }).toList();
                    final recommendedTopics = allTopicsDocs.where((doc) { try { return doc.get('authorId') != user?.uid && doc.get('type') != 'system'; } catch (e) { return false; } }).take(20).toList();
                    final seenTopics = allTopicsDocs.where((doc) { try { final l = _getSafeList(doc.get('seenBy')); return l.contains(user?.uid); } catch (e) { return false; } }).toList();
                    final favoriteTopics = allTopicsDocs.where((doc) { try { final l = _getSafeList(doc.get('favoritedBy')); return l.contains(user?.uid); } catch (e) { return false; } }).toList();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- SECÇÃO: MEUS TÓPICOS ---
                          if (myTopics.isNotEmpty) ...[
                            _buildSectionHeader("My Topics", () => _navigateToSeeAll("My Topics", myTopics)), 
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 210, 
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal, 
                                itemCount: myTopics.length, 
                                itemBuilder: (context, index) => Container(
                                  width: 300, 
                                  margin: const EdgeInsets.only(right: 15),
                                  child: TopicCard(topicId: myTopics[index].id, data: myTopics[index].data() as Map<String, dynamic>)
                                )
                              )
                            ),
                            const SizedBox(height: 20),
                          ],

                          // --- SECÇÃO: RECOMENDADOS ---
                          _buildSectionHeader("Recommended", () => _navigateToSeeAll("Recommended", recommendedTopics)), 
                          const SizedBox(height: 10),
                          recommendedTopics.isEmpty 
                            ? Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text("No recommendations yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)))) 
                            : SizedBox(
                                height: 210, 
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal, 
                                  itemCount: recommendedTopics.length, 
                                  itemBuilder: (context, index) => Container(
                                    width: 300, 
                                    margin: const EdgeInsets.only(right: 15),
                                    child: TopicCard(topicId: recommendedTopics[index].id, data: recommendedTopics[index].data() as Map<String, dynamic>)
                                  )
                                )
                              ),
                          const SizedBox(height: 20),

                          // --- SECÇÃO: VISTOS RECENTEMENTE ---
                          _buildSectionHeader("Recently Seen", () => _navigateToSeeAll("Recently Seen", seenTopics)), 
                          const SizedBox(height: 10),
                          seenTopics.isEmpty 
                            ? Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text("You haven't viewed any topics yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)))) 
                            : SizedBox(
                                height: 210, 
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal, 
                                  itemCount: seenTopics.length, 
                                  itemBuilder: (context, index) {
                                    final doc = seenTopics[index];
                                    return Container(
                                      width: 300, 
                                      margin: const EdgeInsets.only(right: 15),
                                      child: TopicCard(
                                        topicId: doc.id, 
                                        data: doc.data() as Map<String, dynamic>,
                                        onRemove: () async {
                                          if (user != null) {
                                            await FirebaseFirestore.instance
                                                .collection('topics')
                                                .doc(doc.id)
                                                .update({
                                              'seenBy': FieldValue.arrayRemove([user.uid])
                                            });
                                          }
                                        },
                                      )
                                    );
                                  }
                                )
                              ),
                          const SizedBox(height: 20),

                          // --- SECÇÃO: FAVORITOS (VERTICAL) ---
                          _buildSectionHeader("Favourites", () => _navigateToSeeAll("Favourites", favoriteTopics)), 
                          const SizedBox(height: 10),
                          favoriteTopics.isEmpty 
                            ? Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text("No favorites yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)))) 
                            : Column(
                                children: favoriteTopics.map((doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 15), 
                                  child: SizedBox(
                                    width: double.infinity, 
                                    child: TopicCard(
                                      topicId: doc.id, 
                                      data: doc.data() as Map<String, dynamic>,
                                      margin: EdgeInsets.zero,
                                    )
                                  ),
                                )).toList()
                              ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), GestureDetector(onTap: onSeeAll, child: const Text("see all", style: TextStyle(color: const Color(0xFF007AFF), fontSize: 14, decoration: TextDecoration.underline)))]);
  }
}