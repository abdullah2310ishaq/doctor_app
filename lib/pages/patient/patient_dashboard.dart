import 'package:doctor_app/pages/patient/patient_vital_signs_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/models/prescription.dart';
import 'package:doctor_app/models/diet_plan.dart';
import 'package:doctor_app/models/exercise.dart';
import 'patient_exercise_page.dart';
import 'patient_diet_plan_page.dart';
import 'patient_prescription_page.dart';
import 'appointment_booking_page.dart';
import 'package:doctor_app/models/notification.dart';
import 'package:doctor_app/services/notification_service.dart';
import 'package:doctor_app/services/auth_service.dart';
import 'package:doctor_app/pages/settings_page.dart';
import 'package:doctor_app/pages/doctor/notifications_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/pages/patient/weekly_feedback_page.dart';
import 'package:doctor_app/pages/patient/patient_profile_edit_page.dart';

import 'package:doctor_app/services/reminder_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  String _patientName = 'Patient';
  bool _isLoading = true;
  String? _errorMessage;
  DietPlan? _todayDietPlan;
  Prescription? _todayPrescription;
  ExerciseRecommendation? _weeklyExerciseRec;
  bool _plansLoading = true;
  bool _feedbackLoading = false;
  bool _feedbackSubmitted = false;
  final _feedbackController = TextEditingController();
  final int _currentWeek =
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays ~/
              7 +
          1;

  DateTime _currentWeekStart = DateTime.now();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _loadPatientName();
    _loadPlans();
    _checkFeedback();
    _checkWeeklyFeedback();
    _scheduleReminders();
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  void _loadPatientName() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('patients').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _patientName = data['fullName'] ?? data['name'] ?? 'Patient';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Patient profile not found';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading patient data: $e';
          _isLoading = false;
        });
        debugPrint('Error loading patient name: $e');
      }
    } else {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _plansLoading = true;
    });
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      // Fetch today's diet plan
      final dietSnap = await _firestore
          .collection('diet_plans')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();
      if (dietSnap.docs.isNotEmpty) {
        _todayDietPlan = DietPlan.fromJson(dietSnap.docs.first.data());
      }
      // Fetch today's prescription
      final presSnap = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (presSnap.docs.isNotEmpty) {
        _todayPrescription = Prescription.fromJson(presSnap.docs.first.data());
      }
      // Fetch weekly exercise recommendation
      final exSnap = await _firestore
          .collection('exercise_recommendations')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (exSnap.docs.isNotEmpty) {
        _weeklyExerciseRec =
            ExerciseRecommendation.fromMap(exSnap.docs.first.data());
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
    setState(() {
      _plansLoading = false;
    });
  }

  Future<void> _logMeal(String mealType, bool eatenAsPrescribed,
      [String? altFood]) async {
    final user = _auth.currentUser;
    if (user == null || _todayDietPlan == null) return;
    final log = {
      'mealType': mealType,
      'date': DateTime.now().toIso8601String(),
      'eatenAsPrescribed': eatenAsPrescribed,
      'alternativeFood': altFood,
    };
    await _firestore.collection('diet_plans').doc(_todayDietPlan!.id).update({
      'logs': FieldValue.arrayUnion([log])
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Meal log saved!'), backgroundColor: Colors.blue[700]),
    );
  }

  Future<void> _logMedicine(String medName, String time, bool taken,
      [String? notes]) async {
    final user = _auth.currentUser;
    if (user == null || _todayPrescription == null) return;
    final log = {
      'medicationName': medName,
      'date': DateTime.now().toIso8601String(),
      'time': time,
      'taken': taken,
      'notes': notes,
    };
    await _firestore
        .collection('prescriptions')
        .doc(_todayPrescription!.id)
        .update({
      'logs': FieldValue.arrayUnion([log])
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Medicine log saved!'),
          backgroundColor: Colors.blue[700]),
    );
  }

  Future<void> _logExercise(String exId, bool completed,
      [String? notes]) async {
    final user = _auth.currentUser;
    if (user == null || _weeklyExerciseRec == null) return;
    final log = {
      'exerciseId': exId,
      'date': DateTime.now().toIso8601String(),
      'completed': completed,
      'notes': notes,
    };
    await _firestore
        .collection('exercise_recommendations')
        .doc(_weeklyExerciseRec!.patientId)
        .update({
      'logs': FieldValue.arrayUnion([log])
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Exercise log saved!'),
          backgroundColor: Colors.blue[700]),
    );
  }

  void _signOut() async {
    if (!mounted) return;

    // Show confirmation dialog first
    final shouldSignOut = await AuthService.showLogoutConfirmation(context);
    if (shouldSignOut) {
      await AuthService.signOut(context);
    }
  }

  // void _bookAppointment(
  //     String doctorId, String doctorName, String specialization) async {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => AppointmentBookingPage(
  //         doctorId: doctorId,
  //         doctorName: doctorName,
  //         doctorSpecialization: specialization,
  //       ),
  //     ),
  //   );
  // }

  // void _requestDoctorAssignment(String doctorId, String doctorName) async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;

  //   // Show dialog to enter request message
  //   final TextEditingController messageController = TextEditingController();

  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Request $doctorName'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //               'Send a request to $doctorName to become your assigned doctor.'),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: messageController,
  //             decoration: const InputDecoration(
  //               labelText: 'Message (optional)',
  //               hintText:
  //                   'Tell the doctor why you want to be assigned to them...',
  //               border: OutlineInputBorder(),
  //             ),
  //             maxLines: 3,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () =>
  //               Navigator.of(context).pop(messageController.text.trim()),
  //           child: const Text('Send Request'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (result == null) return;

  //   try {
  //     // Get patient name
  //     final patientDoc =
  //         await _firestore.collection('patients').doc(user.uid).get();
  //     final patientName = patientDoc.exists
  //         ? (patientDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Patient'
  //         : 'Patient';

  //     // Create doctor request
  //     await _firestore.collection('doctor_requests').add({
  //       'patientId': user.uid,
  //       'patientName': patientName,
  //       'doctorId': doctorId,
  //       'doctorName': doctorName,
  //       'message': result.isEmpty
  //           ? 'Patient wants to be assigned to this doctor.'
  //           : result,
  //       'status': 'pending',
  //       'createdAt': DateTime.now().toIso8601String(),
  //       'timestamp': DateTime.now().toIso8601String(),
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Request sent to $doctorName!'),
  //         backgroundColor: Colors.green[600],
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error sending request: $e'),
  //         backgroundColor: Colors.red[600],
  //       ),
  //     );
  //   }
  // }

  Future<void> _checkFeedback() async {
    setState(() {
      _feedbackLoading = true;
    });
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await _firestore
        .collection('feedback')
        .where('patientId', isEqualTo: user.uid)
        .where('week', isEqualTo: _currentWeek)
        .limit(1)
        .get();
    setState(() {
      _feedbackSubmitted = snap.docs.isNotEmpty;
      _feedbackLoading = false;
    });
  }

  Future<void> _submitFeedback() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;
    await _firestore.collection('feedback').add({
      'patientId': user.uid,
      'week': _currentWeek,
      'feedback': feedback,
      'timestamp': DateTime.now().toIso8601String(),
    });
    setState(() {
      _feedbackSubmitted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Feedback submitted!'),
          backgroundColor: Colors.blue[700]),
    );
  }

  Future<void> _checkWeeklyFeedback() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('weekly_feedback')
          .where('patientId', isEqualTo: user.uid)
          .where('weekStart', isEqualTo: _currentWeekStart.toIso8601String())
          .limit(1)
          .get();

      final hasSubmitted = snapshot.docs.isNotEmpty;

      // Create persistent reminder if not submitted
      if (!hasSubmitted) {
        await _createWeeklyFeedbackReminder(user.uid);
      }
    } catch (e) {
      print('Error checking weekly feedback: $e');
    }
  }

  Future<void> _createWeeklyFeedbackReminder(String patientId) async {
    try {
      // Check if reminder already exists
      final existingReminder = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: patientId)
          .where('type', isEqualTo: 'weekly_feedback_reminder')
          .where('weekStartDate',
              isEqualTo: _currentWeekStart.toIso8601String())
          .limit(1)
          .get();

      if (existingReminder.docs.isEmpty) {
        // Create new reminder
        await _firestore.collection('notifications').add({
          'userId': patientId,
          'title': '📋 Weekly Feedback Due',
          'message':
              'Please fill out your weekly health feedback form. Your doctor is waiting!',
          'type': 'weekly_feedback_reminder',
          'relatedId': _currentWeekStart.toIso8601String(),
          'weekStartDate': _currentWeekStart.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'isPersistent': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error creating weekly feedback reminder: $e');
    }
  }

  void _scheduleReminders() {
    final user = _auth.currentUser;
    if (user != null) {
      ReminderService.scheduleAllDailyReminders(user.uid);
      ReminderService.scheduleAllWeeklyReminders(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue[700],
                ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red[50],
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _signOut,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPatientName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_plansLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when user tries to exit
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Welcome, $_patientName! 👋',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.teal[700],
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[700]!, Colors.teal[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            StreamBuilder<int>(
              stream: NotificationService.getUnreadCount(user.uid),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex:
              _selectedIndex.clamp(0, 3), // Ensure index is within valid range
          onTap: (index) {
            setState(() {
              _selectedIndex =
                  index.clamp(0, 3); // Ensure index is within valid range
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.teal[50],
          selectedItemColor: Colors.teal[700],
          unselectedItemColor: Colors.blue[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart),
              label: 'Vitals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const PatientVitalSignsPage();
      case 2:
        return SettingsPage();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital, size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'No doctors available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Doctors will appear here when they register',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final doctors = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctorData = doctors[index].data() as Map<String, dynamic>;
              final doctorId = doctors[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.teal[100],
                            child: Text(
                              (doctorData['fullName'] as String?)?.isNotEmpty ==
                                      true
                                  ? doctorData['fullName']
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'D',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${doctorData['fullName'] ?? 'Unknown'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctorData['specialization'] ??
                                      'General Practitioner',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctorData['clinicName'] ??
                                      'Private Practice',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (doctorData['phone'] != null &&
                          doctorData['phone'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              doctorData['phone'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (doctorData['email'] != null &&
                          doctorData['email'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              doctorData['email'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // COMMENTED OUT: Book Appointment with assigned doctor
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: ElevatedButton.icon(
                      //     onPressed: () => _bookAppointment(
                      //       doctorId,
                      //       doctorData['fullName'] ?? 'Unknown',
                      //       doctorData['specialization'] ?? 'General Medicine',
                      //     ),
                      //     icon: const Icon(Icons.calendar_today),
                      //     label: const Text('Book Appointment'),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.teal,
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       elevation: 2,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Greeting Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        color: Colors.teal[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_patientName! 👋',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[900],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Have a good day! 🌟',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.teal[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientDietPlanPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu,
                            color: Colors.white),
                        label: const Text('Diet Plans',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PatientPrescriptionPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medical_services,
                            color: Colors.white),
                        label: const Text('Prescriptions',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // COMMENTED OUT: Find doctors, book appointments functionality
                // const SizedBox(height: 8),
                // Row(
                //   children: [
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: () => _showDoctorsList(),
                //         icon: const Icon(Icons.people, color: Colors.white),
                //         label: const Text('Find Doctors',
                //             style: TextStyle(color: Colors.white)),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.indigo[600],
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(vertical: 12),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(8),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientExercisePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fitness_center,
                            color: Colors.white),
                        label: const Text('Exercises',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // COMMENTED OUT: Book Appointment functionality
                    // const SizedBox(width: 8),
                    // Expanded(
                    //   child: ElevatedButton.icon(
                    //     onPressed: () => _showBookAppointmentDialog(),
                    //     icon: const Icon(Icons.calendar_today,
                    //         color: Colors.white),
                    //     label: const Text('Book Appointment',
                    //         style: TextStyle(color: Colors.white)),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.orange[600],
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications,
                            color: Colors.white),
                        label: const Text('Notifications',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Vital Signs Widget
        // const PatientVitalSignsWidget(),

        const SizedBox(height: 16),

        // BP and Sugar Input Widget
        // const BPSugarInputWidget(),

        const SizedBox(height: 16),

        // Weekly Vitals Chart Widget

        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Diet Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('diet_plans')
                      .where('patientId', isEqualTo: _auth.currentUser!.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load diet plans',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No diet plans available',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                      );
                    }

                    final dietPlanDoc = snapshot.data!.docs.first;
                    final dietPlanData =
                        dietPlanDoc.data() as Map<String, dynamic>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Duration: ${DateFormat('MMM dd').format(DateTime.parse(dietPlanData['startDate'] as String))} - ${DateFormat('MMM dd').format(DateTime.parse(dietPlanData['endDate'] as String))}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (dietPlanData['meals'] != null) ...[
                          ...(dietPlanData['meals'] as List)
                              .take(3)
                              .map((meal) {
                            final mealData = meal as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: mealData['type'] == 'Breakfast'
                                          ? Colors.orange
                                          : mealData['type'] == 'Lunch'
                                              ? Colors.green
                                              : Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${mealData['type']}: ${mealData['name']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        if (dietPlanData['restrictions'] != null &&
                            (dietPlanData['restrictions'] as List)
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Restrictions: ${(dietPlanData['restrictions'] as List).join(', ')}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red[600],
                                    ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientDietPlanPage(),
                        ),
                      );
                    },
                    child: Text(
                      'View Full Diet Plan',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Prescriptions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('prescriptions')
                      .where('patientId', isEqualTo: _auth.currentUser!.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(2)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load prescriptions',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No prescriptions available',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                      );
                    }

                    final prescriptions = snapshot.data!.docs;
                    return Column(
                      children: prescriptions.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final prescriptionDate =
                            DateTime.parse(data['date'] as String);
                        final medications = data['medications'] as List? ?? [];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          title: Text(
                            'Prescription',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          subtitle: Text(
                            '${DateFormat('MMM dd, yyyy').format(prescriptionDate)} • ${medications.length} medications',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.blue[600],
                                ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    child: Text(
                      'View All Prescriptions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Weekly Feedback Section
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.feedback, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'BIMONTHLY ASSESMENT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your weekly health assessment including:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text('• Physical Activity (Godin)',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                    Text('• Dietary Habits',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                    Text('• Muscle Strength (SARC-F)',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                    Text('• App Usability (SUS)',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeeklyFeedbackPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('Start Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Profile Management Section

        const SizedBox(height: 16),

        // Vital Signs Tracking Section
        // Card(
        //   elevation: 4,
        //   shape:
        //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        //   child: Padding(
        //     padding: const EdgeInsets.all(16),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Row(
        //           children: [
        //             Icon(Icons.monitor_heart, color: Colors.red[600], size: 24),
        //             const SizedBox(width: 8),
        //             Text(
        //               'Vital Signs Tracking',
        //               style: TextStyle(
        //                 fontSize: 18,
        //                 fontWeight: FontWeight.bold,
        //                 color: Colors.red[700],
        //               ),
        //             ),
        //           ],
        //         ),
        //         const SizedBox(height: 12),
        //         Text(
        //           'Track your blood pressure and blood sugar levels with detailed charts and trends. Regular monitoring helps manage your health effectively.',
        //           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        //         ),
        //         const SizedBox(height: 12),
        //         ElevatedButton.icon(
        //           onPressed: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (context) => const PatientVitalSignsPage(),
        //               ),
        //             );
        //           },
        //           icon: const Icon(Icons.trending_up),
        //           label: const Text('Track Vitals'),
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.red[600],
        //             foregroundColor: Colors.white,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Please log in',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue[700],
              ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('appointmentTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error:  ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.blue[300]),
                const SizedBox(height: 16),
                const Text(
                  'No appointments yet',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Book your first appointment!',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final upcoming = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final time = DateTime.tryParse(data['appointmentTime'] ?? '') ?? now;
          return time.isAfter(now);
        }).toList();
        final past = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final time = DateTime.tryParse(data['appointmentTime'] ?? '') ?? now;
          return time.isBefore(now);
        }).toList();

        return Column(
          children: [
            // Book Appointment Button
            Container(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showBookAppointmentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Book New Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        Text(
                          'Upcoming Appointments',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900],
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ...upcoming
                            .map((doc) => _buildAppointmentCard(doc, true)),
                        const SizedBox(height: 24),
                      ],
                      if (past.isNotEmpty) ...[
                        Text(
                          'Past Appointments',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700],
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ...past.map((doc) => _buildAppointmentCard(doc, false)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot doc, bool isUpcoming) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentTime =
        DateTime.tryParse(data['appointmentTime'] ?? '') ?? DateTime.now();
    final status = (data['status'] ?? 'pending').toLowerCase();
    final doctorName = data['doctorName'] ?? 'Doctor';
    final type = data['appointmentType'] ?? 'Consultation';
    final duration = data['duration'] ?? '30 minutes';
    final notes = data['notes'] ?? '';
    final id = doc.id;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.teal[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. $doctorName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(appointmentTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.access_time, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(appointmentTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.timer, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Your Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isUpcoming &&
                (status == 'pending' || status == 'confirmed')) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(id),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rescheduleAppointment(id, data),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _cancelAppointment(String appointmentId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Appointment cancelled'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rescheduleAppointment(
      String appointmentId, Map<String, dynamic> data) async {
    DateTime? newDate;
    TimeOfDay? newTime;

    // Show date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    newDate = pickedDate;

    // Show time picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;
    newTime = pickedTime;

    // Check if new time is in the past
    final newDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );

    if (newDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Update appointment
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'appointmentTime': newDateTime.toIso8601String(),
        'status': 'pending', // Reset to pending for doctor approval
        'updatedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Appointment rescheduled successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rescheduling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPrescriptionsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Please log in',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue[700],
              ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'No prescriptions available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prescriptions from doctors will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[500],
                      ),
                ),
              ],
            ),
          );
        }

        final prescriptions = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final prescriptionData =
                  prescriptions[index].data() as Map<String, dynamic>;
              final prescriptionDate =
                  DateTime.parse(prescriptionData['date'] as String);
              final medications =
                  prescriptionData['medications'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription - ${DateFormat('MMM dd, yyyy').format(prescriptionDate)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[900],
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Medications:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (medications.isEmpty)
                        Text(
                          'No medications listed',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                        ),
                      ...medications.map((medication) {
                        final med = medication as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['name'] as String? ?? 'Not specified',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dosage: ${med['dosage'] as String? ?? 'Not specified'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.blue[600],
                                    ),
                              ),
                              Text(
                                'Frequency: ${med['frequency'] as String? ?? 'Not specified'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.blue[600],
                                    ),
                              ),
                              Text(
                                'Duration: ${med['duration'] as String? ?? 'Not specified'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.blue[600],
                                    ),
                              ),
                              if (med['notes'] != null &&
                                  (med['notes'] as String).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Notes: ${med['notes']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      if (prescriptionData['instructions'] != null &&
                          (prescriptionData['instructions'] as String)
                              .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Instructions:',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescriptionData['instructions'] as String,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[700],
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Please log in',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue[700],
              ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService.getUserNotifications(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when doctors\nsend prescriptions or diet plans',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notificationData =
                  notificationDoc.data() as Map<String, dynamic>;

              final notification = AppNotification.fromMap(
                notificationData,
                notificationDoc.id,
              );

              final notificationDate = DateTime.parse(notification.createdAt);

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: notification.isRead ? Colors.white : Colors.teal[50],
                child: InkWell(
                  onTap: () {
                    if (!notification.isRead) {
                      NotificationService.markAsRead(notification.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: notification.type == 'appointment'
                                    ? Colors.teal[100]
                                    : notification.type == 'prescription'
                                        ? Colors.green[100]
                                        : notification.type == 'diet_plan'
                                            ? Colors.orange[100]
                                            : Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                notification.type == 'appointment'
                                    ? Icons.calendar_today
                                    : notification.type == 'prescription'
                                        ? Icons.medical_services
                                        : notification.type == 'diet_plan'
                                            ? Icons.restaurant_menu
                                            : Icons.notifications,
                                color: notification.type == 'appointment'
                                    ? Colors.teal
                                    : notification.type == 'prescription'
                                        ? Colors.green
                                        : notification.type == 'diet_plan'
                                            ? Colors.orange
                                            : Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: Colors.teal[900],
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.blue[700],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('MMM dd').format(notificationDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                ),
                                Text(
                                  DateFormat('hh:mm a')
                                      .format(notificationDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                ),
                                if (!notification.isRead) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToExercisePlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientExercisePage(),
      ),
    );
  }

  Widget _buildWeeklyFeedbackBanner() {
    final weekEnd = _currentWeekStart.add(Duration(days: 6));
    final weekRange =
        '${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd').format(weekEnd)}';

    return Container(
      width: double.infinity,
      color: Colors.orange[100],
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.feedback, color: Colors.orange[800], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Weekly Feedback Due',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Please fill out your health feedback for $weekRange',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeeklyFeedbackPage()),
              );
              await _checkWeeklyFeedback();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Fill Now',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysRemindersSection() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to see your reminders.'),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ReminderService.getDailyReminders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading daily reminders: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'No daily reminders for today.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see your meal and medicine reminders here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reminders = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Reminders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 16),
            ...reminders.map((reminder) {
              final reminderType = reminder['type'] as String;
              final reminderTime = DateTime.parse(reminder['time'] as String);
              final reminderMessage = reminder['message'] as String;
              final reminderId = reminder['id'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.teal[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminderType.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminderMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('hh:mm a').format(reminderTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (!reminder['isCompleted']) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ReminderService.markAsCompleted(
                                reminderId, context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder marked as completed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          label: const Text('Mark as Completed'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCurrentDietPlanSection() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to see your current diet plan.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('diet_plans')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading current diet plan: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'No current diet plan available.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your doctor will provide you with a diet plan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final dietPlanDoc = snapshot.data!.docs.first;
        final dietPlanData = dietPlanDoc.data() as Map<String, dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Diet Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plan Duration: ${DateFormat('MMM dd').format(DateTime.parse(dietPlanData['startDate'] as String))} - ${DateFormat('MMM dd').format(DateTime.parse(dietPlanData['endDate'] as String))}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue[600],
                  ),
            ),
            const SizedBox(height: 12),
            if (dietPlanData['meals'] != null) ...[
              ...(dietPlanData['meals'] as List).take(3).map((meal) {
                final mealData = meal as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: mealData['type'] == 'Breakfast'
                              ? Colors.orange
                              : mealData['type'] == 'Lunch'
                                  ? Colors.green
                                  : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${mealData['type']}: ${mealData['name']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            if (dietPlanData['restrictions'] != null &&
                (dietPlanData['restrictions'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Restrictions: ${(dietPlanData['restrictions'] as List).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[600],
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showBookAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: const Text('This will open the appointment booking page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to doctors list to book appointment
              _showDoctorsList();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showDoctorsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Select Doctor'),
            backgroundColor: Colors.teal[700],
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('doctors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final doctors = snapshot.data?.docs ?? [];
              if (doctors.isEmpty) {
                return const Center(
                  child: Text('No doctors available'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctorData =
                      doctors[index].data() as Map<String, dynamic>;
                  final doctorId = doctors[index].id;
                  final doctorName = doctorData['fullName'] ?? 'Doctor';
                  final specialization =
                      doctorData['specialization'] ?? 'General';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Text(
                          doctorName[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(doctorName),
                      subtitle: Text(specialization),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ElevatedButton(
                          //   onPressed: () =>
                          //       _requestDoctorAssignment(doctorId, doctorName),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.orange[600],
                          //     foregroundColor: Colors.white,
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 8, vertical: 4),
                          //   ),
                          //   child: const Text('Request',
                          //       style: TextStyle(fontSize: 12)),
                          // ),
                          // const SizedBox(width: 4),
                          //   ElevatedButton(
                          //     onPressed: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => AppointmentBookingPage(
                          //             doctorId: doctorId,
                          //             doctorName: doctorName,
                          //             doctorSpecialization: specialization,
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //     child: const Text('Book'),
                          //   ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
