import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import '../../database_service.dart';
import '../../auth_service.dart';
import 'profile_page.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE
import 'services/good_behavior_service.dart'; // <--- IMPORT FILTRO

class TopicDetailPage extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> topicData; 

  const TopicDetailPage({super.key, required this.topicId, required this.topicData});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _auth = AuthService();
  final TextEditingController _commentController = TextEditingController();
  
  String currentUserId = "";
  ImageProvider? _currentUserImage;
  String? _currentUserBase64; 
  String? _currentUserName; 
  String? _currentName;     

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    _loadCurrentUserProfile();

    if (currentUserId.isNotEmpty) {
      FirebaseMessaging.instance.getToken().then((token) {
        if (token != null) {
          _dbService.saveUserToken(currentUserId, token);
        }
      });
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    if (currentUserId.isNotEmpty) {
      final userData = await _dbService.getUserData(currentUserId);
      if (userData != null && mounted) {
        setState(() {
          _currentUserName = userData['username'];
          _currentName = userData['name'];

          if (userData['imageBase64'] != null && (userData['imageBase64'] as String).isNotEmpty) {
            _currentUserBase64 = userData['imageBase64']; 
            try {
              _currentUserImage = MemoryImage(base64Decode(_currentUserBase64!));
            } catch (e) {
              print("Erro decoding image: $e");
            }
          } 
          else if (userData['photoUrl'] != null && (userData['photoUrl'] as String).isNotEmpty) {
             _currentUserImage = NetworkImage(userData['photoUrl']);
          }
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // --- NOVO: FILTRO DE BOM COMPORTAMENTO ---
    final validator = GoodBehaviorService();
    if (validator.isOffensive(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your message contains inappropriate language. Please be respectful."),
          backgroundColor: Colors.red,
        )
      );
      return; // Bloqueia o envio
    }
    // ------------------------------------------

    final user = _auth.currentUser;
    if (user != null) {
      String nameToSend = "User";
      
      if (_currentUserName != null && _currentUserName!.isNotEmpty) {
        nameToSend = _currentUserName!;
      } else if (_currentName != null && _currentName!.isNotEmpty) {
        nameToSend = _currentName!;
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        nameToSend = user.displayName!;
      }

      await _dbService.addComment(widget.topicId, {
        'text': text,
        'userId': user.uid,
        'userName': nameToSend,
        'userImage': _currentUserBase64 ?? "", 
      });

      String topicTitle = widget.topicData['title'] ?? "Topic";
      
      await _dbService.notifySubscribers(
        widget.topicId, 
        nameToSend, 
        topicTitle,
        user.uid 
      );
      
      await _dbService.incrementUserLevel(user.uid);

      if (!mounted) return; 

      _commentController.clear();
      FocusScope.of(context).unfocus(); 
    }
  }

  // --- WIDGET INTELIGENTE PARA CARREGAR AVATARS ---
  Widget _buildUserAvatar(String userId, double radius) {
    if (userId.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade400,
        child: Icon(Icons.person, size: radius * 1.4, color: Colors.white),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _dbService.getUserData(userId),
      builder: (context, snapshot) {
        ImageProvider? img;
        
        if (snapshot.hasData && snapshot.data != null) {
          final uData = snapshot.data!;
          if (uData['imageBase64'] != null && (uData['imageBase64'] as String).isNotEmpty) {
            try {
              img = MemoryImage(base64Decode(uData['imageBase64']));
            } catch (_) {}
          } 
          else if (uData['photoUrl'] != null && (uData['photoUrl'] as String).isNotEmpty) {
            img = NetworkImage(uData['photoUrl']);
          }
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: img,
          child: img == null 
            ? Icon(Icons.person, size: radius * 1.4, color: Colors.white) 
            : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePageWidget()))
                        .then((_) => _loadCurrentUserProfile()),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _currentUserImage,
                      child: _currentUserImage == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                  ),

                  StreamBuilder<DocumentSnapshot>(
                    stream: _dbService.getSingleTopicStream(widget.topicId),
                    builder: (context, snapshot) {
                      bool isSubscribed = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final List subs = (data['subscribedBy'] is List) ? data['subscribedBy'] : [];
                        isSubscribed = subs.contains(currentUserId);
                      }

                      return IconButton(
                        onPressed: () {
                          _dbService.toggleTopicSubscription(widget.topicId, currentUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSubscribed ? "Notifications OFF for this topic" : "Notifications ON for this topic"),
                              duration: const Duration(seconds: 1),
                            )
                          );
                        },
                        icon: Icon(
                          isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                          color: isSubscribed ? const Color(0xFFFC751D) : Colors.grey,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 2. BANNER DO TÓPICO
            StreamBuilder<DocumentSnapshot>(
              stream: _dbService.getSingleTopicStream(widget.topicId),
              builder: (context, snapshot) {
                Map<String, dynamic> data = widget.topicData;
                if (snapshot.hasData && snapshot.data!.exists) {
                  data = snapshot.data!.data() as Map<String, dynamic>;
                }
                
                List favoritedBy = data['favoritedBy'] is List ? data['favoritedBy'] : [];
                bool isFavorite = favoritedBy.contains(currentUserId);
                String authorId = data['authorId'] ?? ""; 

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade400,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- TÍTULO DO TÓPICO (AR One Sans) ---
                            Text(
                              data['title'] ?? "Topic",
                              style: GoogleFonts.arOneSans(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.black87
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildUserAvatar(authorId, 10),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    "Created by ${data['authorName'] ?? 'Unknown'}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _dbService.toggleFavorite(widget.topicId, currentUserId),
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? const Color(0xFFFC751D) : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),

            // 3. LISTA DE MENSAGENS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _dbService.getCommentsStream(widget.topicId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final comments = snapshot.data!.docs.toList();
                  
                  comments.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    
                    final aTimestamp = aData['createdAt'] as Timestamp?;
                    final bTimestamp = bData['createdAt'] as Timestamp?;

                    if (aTimestamp == null) return -1;
                    if (bTimestamp == null) return 1;

                    return bTimestamp.compareTo(aTimestamp);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    reverse: true, 
                    itemCount: comments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == comments.length) {
                        return _buildMessageBubble(
                          key: const ValueKey('description'),
                          text: widget.topicData['description'] ?? "",
                          senderName: widget.topicData['authorName'] ?? "Owner",
                          isMe: widget.topicData['authorId'] == currentUserId,
                          isDescription: true,
                          userId: widget.topicData['authorId'],
                        );
                      }

                      final doc = comments[index];
                      Map<String, dynamic> cData = doc.data() as Map<String, dynamic>;
                      
                      return _buildMessageBubble(
                        key: ValueKey(doc.id), 
                        text: cData['text'] ?? "",
                        senderName: cData['userName'] ?? "User",
                        isMe: cData['userId'] == currentUserId,
                        userId: cData['userId'], 
                      );
                    },
                  );
                },
              ),
            ),

            // 4. INPUT BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      // --- INPUT STYLE (AR One Sans) ---
                      style: GoogleFonts.arOneSans(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send, color: const Color(0xFFFC751D)),
                    onPressed: _sendComment,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DO BALÃO DE MENSAGEM ---
  Widget _buildMessageBubble({
    Key? key,
    required String text, 
    required String senderName, 
    required bool isMe, 
    required String? userId, 
    bool isDescription = false,
  }) {
    Color bubbleColor = isMe ? const Color(0xFFFC751D) : Colors.grey.shade200;

    Widget avatarWidget = _buildUserAvatar(userId ?? (isMe ? currentUserId : ""), 12);

    Widget identityText = RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black87),
        children: [
          // Labels "Created by/Replied by" -> Montserrat
          TextSpan(text: isDescription ? "Created by " : "Replied by "),
          TextSpan(text: isMe ? "You" : senderName, style: const TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFFFC751D))),
        ],
      ),
    );

    return RepaintBoundary( 
      key: key,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: isMe 
                ? [ 
                    identityText,
                    const SizedBox(width: 8),
                    avatarWidget,
                  ]
                : [ 
                    avatarWidget,
                    const SizedBox(width: 8),
                    identityText,
                  ],
            ),
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(maxWidth: 300), 
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0), 
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                ),
              ),
              // --- TEXTO DA MENSAGEM (AR One Sans) ---
              child: Text(
                text,
                style: GoogleFonts.arOneSans(
                  fontSize: 14, 
                  height: 1.4, 
                  color: Colors.black87
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}