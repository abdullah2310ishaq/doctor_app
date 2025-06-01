import 'package:doctor_app/pages/patient/patient_personal_data_form.dart';
import 'package:flutter/material.dart';
import 'package:doctor_app/pages/doctor/doctor_dashboard.dart';
import 'package:doctor_app/pages/patient/patient_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDoctor = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Set default values for demo
    _emailController.text =
        _isDoctor ? 'abdullahh@gmail.com' : 'mahad@gmail.com';
    _passwordController.text = 'Abdullah';
  }

  @override
  void dispose() { 
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Determine user role and profile completion status from Firestore
        DocumentSnapshot? userDoc;
        String? userRole;
        bool? profileCompleted;
        int? profileVersion;

        // Try to fetch from 'doctors' collection first
        userDoc = await _firestore.collection('doctors').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          userRole = data?['role'] as String?;
        } else {
          // If not a doctor, try to fetch from 'patients' collection
          userDoc = await _firestore.collection('patients').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>?;
            userRole = data?['role'] as String?;
            profileCompleted = data?.containsKey('profileCompleted') == true
                ? data!['profileCompleted'] as bool?
                : false;
            profileVersion = data?['profileVersion'] as int? ?? 0;
          }
        }

        if (!mounted) return;

        if (userRole == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          );
        } else if (userRole == 'patient') {
          // Check if profile is completed with version 29
          if (profileCompleted == true && profileVersion! >= 29) {
            // Profile is complete with latest version, go to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientDashboard()),
            );
          } else {
            // Profile is not completed or old version, go to original form flow
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PatientPersonalDataForm()),
            );
          }
        } else {
          // Handle cases where role is not found or invalid
          await _auth.signOut();
          setState(() {
            _errorMessage =
                'User role not found or invalid. Please contact support.';
            _isLoading = false;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Login failed: ${e.message}';
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.blue.shade100,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ChoiceChip(
                        label: 'Doctor',
                        selected: _isDoctor,
                        onSelected: (selected) {
                          setState(() {
                            _isDoctor = true;
                            _emailController.text = 'abdullah@gmail.com';
                            _passwordController.text = 'Abdullah@2310';
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      _ChoiceChip(
                        label: 'Patient',
                        selected: !_isDoctor,
                        onSelected: (selected) {
                          setState(() {
                            _isDoctor = false;
                            _emailController.text = 'mahad@gmail.com';
                            _passwordController.text = 'Abdullah@2310';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      prefixIcon:
                          Icon(Icons.email, color: Colors.blue.shade700),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blue.shade200,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Demo Credentials:\nDoctor: abdullah@gmail.com\nPatient: mahad@gmail.com\nPassword: Abdullah@2310',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.blue.shade700,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.blue.shade700,
      backgroundColor: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      elevation: selected ? 5 : 2,
      shadowColor: Colors.blue.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}
