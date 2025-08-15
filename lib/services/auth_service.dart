import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/welcome_page.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Proper logout functionality that clears all user data and signs out
  static Future<void> signOut(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing out...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clear any local storage or cached data here if needed
      // For example, SharedPreferences, local database, etc.

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Successfully signed out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to welcome page and clear all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if there's an error
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error signing out: $e',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Show logout confirmation dialog
  static Future<bool> showLogoutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red[600], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                'Are you sure you want to sign out? You will need to log in again to access your account.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get user role (doctor or patient)
  static Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Check if user is a doctor
      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      if (doctorDoc.exists) {
        return 'doctor';
      }

      // Check if user is a patient
      final patientDoc =
          await _firestore.collection('patients').doc(user.uid).get();
      if (patientDoc.exists) {
        return 'patient';
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
