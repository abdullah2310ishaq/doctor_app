import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/pages/welcome_page.dart';
import 'package:doctor_app/pages/patient/patient_dashboard.dart';
import 'package:doctor_app/pages/doctor/doctor_dashboard.dart';
import 'package:doctor_app/pages/patient/patient_personal_data_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Patient App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, check their role and profile status
          return FutureBuilder<Widget>(
            future: _determineUserDestination(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              return futureSnapshot.data ?? const WelcomePage();
            },
          );
        }

        // User is not logged in
        return const WelcomePage();
      },
    );
  }

  Future<Widget> _determineUserDestination(User user) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Check if user is a doctor
    DocumentSnapshot doctorDoc = await firestore.collection('doctors').doc(user.uid).get();
    if (doctorDoc.exists) {
      return const DoctorDashboard();
    }
    
    // Check if user is a patient
    DocumentSnapshot patientDoc = await firestore.collection('patients').doc(user.uid).get();
    if (patientDoc.exists) {
      final data = patientDoc.data() as Map<String, dynamic>?;
      final profileCompleted = data?['profileCompleted'] as bool? ?? false;
      final profileVersion = data?['profileVersion'] as int? ?? 0;
      
      // Check if profile is completed with version 29
      if (profileCompleted && profileVersion >= 29) {
        return const PatientDashboard();
      } else {
        // Profile not completed or old version, go to original form flow
        return const PatientPersonalDataForm();
      }
    }
    
    // User document not found, sign out and go to welcome
    await FirebaseAuth.instance.signOut();
    return const WelcomePage();
    
  } catch (e) {
    print('Error determining user destination: $e');
    return const WelcomePage();
  }
}
}
