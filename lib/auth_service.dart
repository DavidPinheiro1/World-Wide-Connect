import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth authentication = FirebaseAuth.instance;
  final FirebaseFirestore dataBase = FirebaseFirestore.instance;

  //get current user
  User? get currentUser => authentication.currentUser;
  Stream<User?> get authStateChanges => authentication.authStateChanges();

  //login with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await authentication.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  //Register with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await authentication.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);
        //Create document for the user in Firestore Database
        await createUserDocument(user, name: name);
      }
      return user;
    } catch (e) {
      print("Register Error: $e");
      rethrow;
    }
  }

  //login with google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      //force pop-up account selection
      try { await googleSignIn.disconnect(); } catch (_) {} 

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await authentication.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        //calls the function that creates or updates the user document in Firestore Database
        await createUserDocument(user);
      }

      return userCredential;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  //create or updates user document in Firestore Database
  Future<void> createUserDocument(User user, {String? name}) async {
    final userRef = dataBase.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      //if the user does NOT EXIST, create the document
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
        'photoUrl': user.photoURL ?? "",
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false, 
      }, SetOptions(merge: true));
    } else {
      //In case the user already exists, we can update the photo
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        await userRef.update({
          'photoUrl': user.photoURL,
        });
      }
    }
  }

  //logout
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await authentication.signOut();
    } catch (e) {
      print("Erro logout: $e");
    }
  }
  
  //Additional helper methods for easier usage
  Future<User?> createAccount({required String name, required String email, required String password}) async {
    return registerWithEmailAndPassword(email, password, name);
  }
  
  Future<User?> signIn({required String email, required String password}) async {
    return signInWithEmailAndPassword(email, password);
  }

  Future<void> resetPassword({required String email}) async {
    await authentication.sendPasswordResetEmail(email: email);
  }
}