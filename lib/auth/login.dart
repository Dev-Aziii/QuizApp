import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsreviewer_app/auth/auth.dart';
import 'package:itsreviewer_app/auth/register.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  // --- Show Top SnackBar ---
  void _showTopMessage(String message, {bool success = false}) {
    showTopSnackBar(
      Overlay.of(context),
      success
          ? CustomSnackBar.success(message: message)
          : CustomSnackBar.error(message: message),
    );
  }

  // --- Google Sign-In ---
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isEmailLoading) return;

    try {
      setState(() => _isGoogleLoading = true);
      final user = await _authService.signInWithGoogle();
      setState(() => _isGoogleLoading = false);

      if (user == null) {
        _showTopMessage("Google Sign-In cancelled.");
        return;
      }

      await _navigateBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      _showTopMessage("Error during Google Sign-In.");
      debugPrint("Google Sign-In Error: $e");
    }
  }

  // --- Email/Password Sign-In ---
  // --- Email/Password Sign-In ---
  Future<void> _handleEmailSignIn() async {
    if (_isEmailLoading || _isGoogleLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _isEmailLoading = false);

      if (user != null) {
        await _navigateBasedOnRole(user.uid);
      } else {
        _showTopMessage("Invalid credentials or account disabled.");
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isEmailLoading = false);

      switch (e.code) {
        case 'invalid-email':
          _showTopMessage("Please enter a valid email address.");
          break;
        case 'user-not-found':
          _showTopMessage("No account found for this email.");
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _showTopMessage("Incorrect email or password.");
          break;
        case 'user-disabled':
          _showTopMessage("This account has been disabled.");
          break;
        default:
          _showTopMessage("Login failed: ${e.message}");
          break;
      }
    } catch (e) {
      setState(() => _isEmailLoading = false);
      debugPrint("Email sign-in failed: $e");
      _showTopMessage("An unexpected error occurred. Please try again.");
    }
  }

  // --- Role-based navigation ---
  Future<void> _navigateBasedOnRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      _showTopMessage("User document not found. Please contact support.");
      return;
    }

    final role = doc['role'];
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/user');
    }

    _showTopMessage("Login successful!", success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(11, 0, 4, 244), AppTheme.primaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'appLogo',
                    child: Image.asset("assets/applogo.png", height: 100),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back!",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to continue to ITS Reviewer",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 32),

                  // --- Login Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your email";
                              }
                              // Simple regex to catch badly formatted emails
                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return "Please enter a valid email address";
                              }
                              return null;
                            },

                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Please enter password" : null,
                          ),
                          const SizedBox(height: 24),

                          // --- Email Sign In Button ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isEmailLoading
                                  ? null
                                  : _handleEmailSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isEmailLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // --- Register Link ---
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Don't have an account? Register",
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: const [
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.white54),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Or",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Google Sign-In ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Image.asset("assets/google.png", height: 24),
                      label: Text(
                        _isGoogleLoading
                            ? "Signing in..."
                            : "Sign in with Google",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
