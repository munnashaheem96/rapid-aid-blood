import 'package:flutter/material.dart';
import 'package:rapid_aid/screens/home_screen.dart';
import 'package:rapid_aid/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/main.dart'; // ✅ IMPORTANT (for navigatorKey)

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Rapid Aid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Emergency Help, Instantly',
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 40),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 30,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              /// 📧 EMAIL
                              TextField(
                                controller: emailController,
                                decoration: input("Email", Icons.email),
                              ),

                              const SizedBox(height: 20),

                              /// 🔒 PASSWORD
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: input("Password", Icons.lock),
                              ),

                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// 🔴 LOGIN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: () async {
                                    String email =
                                        emailController.text.trim();
                                    String password =
                                        passwordController.text.trim();

                                    if (email.isEmpty || password.isEmpty) {
                                      showSnack("Enter email & password");
                                      return;
                                    }

                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                        email: email,
                                        password: password,
                                      );

                                      showSnack("Login successful");

                                      navigatorKey.currentState!
                                          .pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const HomeScreen(),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      showSnack(
                                        e.message ??
                                            "Invalid email or password",
                                      );
                                    } catch (e) {
                                      showSnack("Login failed");
                                    }
                                  },
                                  child: const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account? "),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SignupScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔧 INPUT DECORATION
  InputDecoration input(String text, IconData icon) {
    return InputDecoration(
      labelText: text,
      prefixIcon: Icon(icon, color: Colors.red),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔥 GLOBAL SAFE SNACKBAR
  void showSnack(String msg) {
    final ctx = navigatorKey.currentContext;

    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}