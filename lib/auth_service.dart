import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- LOGIN EMAIL ---
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // --- REGISTO EMAIL ---
  Future<User?> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);
        // Cria doc na DB com flag isProfileComplete: false
        await _createUserDocument(user, name: name);
      }
      return user;
    } catch (e) {
      print("Register Error: $e");
      rethrow;
    }
  }

  // --- LOGIN GOOGLE ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Tenta desconectar para forçar o popup de escolha de conta se necessário
      try { await googleSignIn.disconnect(); } catch (_) {} 

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Chama a função que cria ou ATUALIZA o utilizador
        await _createUserDocument(user);
      }

      return userCredential;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  // --- CRIAR OU ATUALIZAR DOCUMENTO NA DB ---
  // AQUI FOI FEITA A CORREÇÃO
  Future<void> _createUserDocument(User user, {String? name}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      // 1. Se o utilizador NÃO existir, cria tudo de novo
      await userRef.set({
        'username': name ?? user.displayName ?? "User",
        'name': name ?? user.displayName ?? "User",
        'email': user.email ?? "",
        'bio': "Hello, I am using WWC app!", 
        'country': "World",
        'level': 1,
        'points': 0,
        'notificationsEnabled': true,
        'imageBase64': "", 
        'photoUrl': user.photoURL ?? "", // Guarda a foto aqui
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false, 
      }, SetOptions(merge: true));
    } else {
      // 2. Se o utilizador JÁ EXISTIR (Caso do Duarte), atualiza a foto se vier do Google
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        await userRef.update({
          'photoUrl': user.photoURL,
        });
      }
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      print("Erro logout: $e");
    }
  }
  
  Future<User?> createAccount({required String name, required String email, required String password}) async {
    return registerWithEmailAndPassword(email, password, name);
  }
  
  Future<User?> signIn({required String email, required String password}) async {
    return signInWithEmailAndPassword(email, password);
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}