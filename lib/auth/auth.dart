import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;
  // --- Google Sign-In ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;
      if (user != null) await _createUserDocIfNotExists(user);

      return user;
    } catch (e, stack) {
      log("Google Sign-In failed:", error: e, stackTrace: stack);
      return null;
    }
  }

  // --- Email/Password Sign-Up ---
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        await _createUserDocIfNotExists(user, name: name);
      }

      return user;
    } catch (e, stack) {
      log('Email sign-up failed:', error: e, stackTrace: stack);
      return null;
    }
  }

  // --- Email/Password Sign-In ---
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        log("No Firestore document found for user: ${user.uid}");
        await auth.signOut();
        return null;
      }

      final data = userDoc.data();
      final bool isDisabled = data?['disabled'] == true;

      if (isDisabled) {
        log("User ${user.email} is disabled.");
        await auth.signOut();

        return null;
      }

      return user;
    } catch (e, stack) {
      log("Email sign-in failed:", error: e, stackTrace: stack);
      return null;
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await auth.signOut();
    await _googleSignIn.signOut();
  }

  // --- Create User Document in Firestore ---
  Future<void> _createUserDocIfNotExists(User user, {String? name}) async {
    final userDoc = firestore.collection("users").doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        "email": user.email,
        "name": name ?? user.displayName ?? "",
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
