import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/services/notification_service.dart';
import 'package:doctor_app/services/auth_service.dart';
import 'package:doctor_app/widgets/logout_button.dart';
import 'package:doctor_app/pages/settings_page.dart';
import 'package:doctor_app/pages/doctor/patient_details_page.dart';

import 'package:doctor_app/pages/doctor/notifications_page.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  // final List<Appointment> _upcomingAppointments = [];
  bool _isLoading = true;
  String _doctorName = 'Dr. Smith';
  String? _selectedPatientId;
  String? _selectedPatientName;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  void _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch doctor data from Firestore
        final doctorDoc =
            await _firestore.collection('doctors').doc(user.uid).get();
        if (doctorDoc.exists) {
          final data = doctorDoc.data() as Map<String, dynamic>;
          setState(() {
            _doctorName = data['fullName'] ?? 'Doctor';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _signOut() async {
    if (!mounted) return;

    // Show confirmation dialog first
    final shouldSignOut = await AuthService.showLogoutConfirmation(context);
    if (shouldSignOut) {
      await AuthService.signOut(context);
    }
  }

  // Create prescription for patient
  void _createPrescription(String patientId, String patientName) {
    showDialog(
      context: context,
      builder: (context) => PrescriptionDialog(
        patientId: patientId,
        patientName: patientName,
        onPrescriptionCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prescription created for $patientName')),
          );
        },
      ),
    );
  }

  // Create diet plan for patient
  void _createDietPlan(String patientId, String patientName) {
    showDialog(
      context: context,
      builder: (context) => DietPlanDialog(
        patientId: patientId,
        patientName: patientName,
        onDietPlanCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Diet plan created for $patientName')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Dr. $_doctorName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue[700],
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            StreamBuilder<int>(
              stream: NotificationService.getUnreadCount(
                  _auth.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
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
            LogoutIconButton(
              iconColor: Colors.white,
              onLogoutComplete: () {
                // Additional cleanup if needed
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
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Patients',
            ),
          
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Ensure selectedIndex is within valid range
    final safeIndex = _selectedIndex.clamp(0, 3);
    if (safeIndex != _selectedIndex) {
      // If index was out of bounds, update it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedIndex = safeIndex;
        });
      });
    }

    switch (safeIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildPatientsTab(); // Existing patients tab
  
      case 2:
        return _buildFeedbackTab();
      default:
        return _buildHomeTab();
    }
  }

  // Enhanced Patients tab with Analytics
  Widget _buildPatientsTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: AppBar(
            backgroundColor: Colors.blue[700],
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Patient List'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPatientListTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patients')
          .where('userType', isEqualTo: 'patient')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No patients available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final patients = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh will happen automatically with StreamBuilder
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patientData =
                  patients[index].data() as Map<String, dynamic>;
              final patientId = patients[index].id;

              // Skip if this is a doctor account
              if (patientData['userType'] == 'doctor' ||
                  patientData['role'] == 'doctor') {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsPage(
                          patientId: patientId,
                          patientName:
                              patientData['fullName'] ?? 'Unknown Patient',
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                patientData['fullName']
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'P',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientData['fullName'] ??
                                        'Unknown Patient',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    patientData['email'] ?? 'No email',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: patientData['profileCompleted'] ==
                                              true
                                          ? Colors.blue[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      patientData['profileCompleted'] == true
                                          ? 'Profile Complete'
                                          : 'Profile Incomplete',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            patientData['profileCompleted'] ==
                                                    true
                                                ? Colors.blue[800]
                                                : Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsPage(
                                    patientId: patientId,
                                    patientName: patientData['fullName'] ??
                                        'Unknown Patient',
                                  ),
                                ),
                              );
                            },
                            icon:
                                Icon(Icons.visibility, color: Colors.blue[700]),
                            label: Text('View Details',
                                style: TextStyle(color: Colors.blue[700])),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue[700]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  Widget _buildHomeTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in again'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadDoctorData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        _doctorName.isNotEmpty
                            ? _doctorName.substring(0, 1).toUpperCase()
                            : 'D',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $_doctorName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Have a great day!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Patients',
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('patients').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Text('Error');
                        if (!snapshot.hasData) return const Text('0');
                        return Text('${snapshot.data!.docs.length}');
                      },
                    ),
                    Icons.people,
                    Colors.blue[600]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Prescriptions',
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('prescriptions')
                          .where('doctorId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Text('Error');
                        if (!snapshot.hasData) return const Text('0');
                        return Text('${snapshot.data!.docs.length}');
                      },
                    ),
                    Icons.medical_services,
                    Colors.blue[700]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('prescriptions')
                  .where('doctorId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                          'Error loading recent activity: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final patientName =
                        data['patientName'] ?? 'Unknown Patient';
                    final medications = data['medications'] as List? ?? [];
                    final createdAt = data['createdAt'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.medical_services,
                            color: Colors.blue[700]),
                        title: Text('Prescription for $patientName'),
                        subtitle: Text(
                          medications.isNotEmpty
                              ? '${medications.length} medication(s)'
                              : 'No medications',
                        ),
                        trailing: createdAt != null
                            ? Text(
                                DateFormat('MMM dd').format(createdAt.toDate()),
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, Widget value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              child: value,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in again'));
    }

    return Column(
      children: [
        // Header with management button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Appointments',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
              ),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const AppointmentManagementPage(),
              //       ),
              //     );
              //   },
              //   icon: const Icon(Icons.manage_accounts),
              //   label: const Text('Manage'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.teal,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        // Appointments list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: user.uid)
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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error loading appointments: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
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
                      Icon(Icons.calendar_today,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No appointments scheduled',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Appointments will appear here when patients book them',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh will happen automatically with StreamBuilder
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  data['patientName'] ?? 'Unknown Patient',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(data['appointmentTime'] ?? 'No time set'),
                                const SizedBox(width: 16),
                                const Icon(Icons.medical_services,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(data['appointmentType'] ?? 'General'),
                              ],
                            ),
                            if (data['notes'] != null &&
                                data['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${data['notes']}',
                                style: const TextStyle(color: Colors.grey),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Patient Feedback'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showPatientAssignmentInfo(),
            icon: Icon(Icons.people),
            tooltip: 'Check Assignments',
          ),
          IconButton(
            onPressed: () => _assignPatientsToDoctor(),
            icon: Icon(Icons.person_add),
            tooltip: 'Assign Patients',
          ),
          IconButton(
            onPressed: () => _showPatientRequests(),
            icon: Icon(Icons.request_page),
            tooltip: 'Patient Requests',
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient Selector
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Patient:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('patients')
                      .where('assignedDoctorId',
                          isEqualTo: _auth.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final patients = snapshot.data?.docs ?? [];

                    if (patients.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[600]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No patients assigned yet.',
                                    style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Use "Assign Patients" button to assign patients.',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Debug: Total patients in system: ${patients.length}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Debug: Current doctor ID: ${_auth.currentUser?.uid}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedPatientId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Choose Patient',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('Select a patient...'),
                        ),
                        ...patients.map((patient) {
                          final data = patient.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: patient.id,
                            child: Text(data['fullName'] ?? 'Unknown Patient'),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? patientId) {
                        setState(() {
                          _selectedPatientId = patientId;
                          if (patientId != null) {
                            final patient =
                                patients.firstWhere((p) => p.id == patientId);
                            final data = patient.data() as Map<String, dynamic>;
                            _selectedPatientName =
                                data['fullName'] ?? 'Unknown Patient';
                          } else {
                            _selectedPatientName = null;
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Feedback Content
          Expanded(
            child: _selectedPatientId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Select a patient to view their feedback',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.blue[700],
                          child: TabBar(
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            indicatorColor: Colors.white,
                            isScrollable: true,
                            tabs: [
                              Tab(text: 'Meals'),
                              Tab(text: 'Medications'),
                              Tab(text: 'Exercise'),
                              Tab(text: 'Bimonthly'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildMealFeedbackTab(),
                              _buildMedicationFeedbackTab(),
                              _buildExerciseFeedbackTab(),
                              _buildBimonthlyFeedbackTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealFeedbackTab() {
    // Debug: Print index creation URL for diet_plan_feedback
    print('🔥 MAIN DASHBOARD - CREATE INDEX FOR MEALS:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2RpZXRfcGxhbl9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZRABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    if (_selectedPatientId == null) {
      return Center(
        child: Text('Please select a patient to view meal feedback'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('diet_plan_feedback')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No meal feedback yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Selected Patient: ${_selectedPatientName ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Selected Patient ID: ${_selectedPatientId ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Total docs in collection: ${snapshot.data?.docs.length ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Current Doctor ID: ${_auth.currentUser?.uid}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.restaurant, color: Colors.orange[600]),
                ),
                title: Text('Meal Plan Feedback'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${data['patientId']}'),
                    Text('Feedback: ${data['feedback'] ?? 'No feedback'}'),
                    if (data['issues'] != null)
                      Text('Issues: ${(data['issues'] as List).join(', ')}'),
                  ],
                ),
                trailing: Text(
                  data['timestamp'] != null
                      ? DateFormat('MMM dd, yyyy').format(
                          DateTime.parse(data['timestamp']),
                        )
                      : 'No date',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicationFeedbackTab() {
    // Debug: Print index creation URL for prescription_feedback
    print('💊 MAIN DASHBOARD - CREATE INDEX FOR MEDICINES:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl9wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3ByZXNjcmlwdGlvbl9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZBABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    if (_selectedPatientId == null) {
      return Center(
        child: Text('Please select a patient to view medication feedback'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescription_feedback')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No medication feedback yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Selected Patient: ${_selectedPatientName ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Selected Patient ID: ${_selectedPatientId ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Total docs in collection: ${snapshot.data?.docs.length ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Current Doctor ID: ${_auth.currentUser?.uid}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Icon(Icons.medication, color: Colors.red[600]),
                ),
                title: Text('Medication Feedback'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${data['patientId']}'),
                    Text('Feedback: ${data['feedback'] ?? 'No feedback'}'),
                    if (data['issues'] != null)
                      Text('Issues: ${(data['issues'] as List).join(', ')}'),
                  ],
                ),
                trailing: Text(
                  data['timestamp'] != null
                      ? DateFormat('MMM dd, yyyy').format(
                          DateTime.parse(data['timestamp']),
                        )
                      : 'No date',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseFeedbackTab() {
    // Debug: Print index creation URL for exercise_feedback
    print('🏃 MAIN DASHBOARD - CREATE INDEX FOR EXERCISE:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2V4ZXJjaXNlX2ZlZWRiYWNrL2luZGV4ZXMvXxABGgoKBmRvY3RvcklkEAEaCwoHcGF0aWVudElkEAEaDQoJdGltZXN0YW1wEAI=');
    print('====================================');

    if (_selectedPatientId == null) {
      return Center(
        child: Text('Please select a patient to view exercise feedback'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exercise_feedback')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No exercise feedback yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Selected Patient: ${_selectedPatientName ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Selected Patient ID: ${_selectedPatientId ?? "None"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Total docs in collection: ${snapshot.data?.docs.length ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Current Doctor ID: ${_auth.currentUser?.uid}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.fitness_center, color: Colors.green[600]),
                ),
                title: Text('Exercise Progress'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${data['patientId']}'),
                    Text(
                        'Completed: ${data['totalCompleted']}/${data['totalTarget']}'),
                    Text('Completion Rate: ${data['completionRate']}%'),
                  ],
                ),
                trailing: Text(
                  data['timestamp'] != null
                      ? DateFormat('MMM dd, yyyy').format(
                          DateTime.parse(data['timestamp']),
                        )
                      : 'No date',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBimonthlyFeedbackTab() {
    // Debug: Print index creation URL for bimonthly_feedback
    print('📋 MAIN DASHBOARD - CREATE INDEX FOR BIMONTHLY:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl5wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2JpbW9udGhseV9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZBABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    if (_selectedPatientId == null) {
      return Center(
        child: Text('Please select a patient to view bimonthly feedback'),
      );
    }

    final currentDoctorId = _auth.currentUser?.uid;
    print('Current doctor ID: $currentDoctorId');

    // Create query based on whether doctorId is available
    Stream<QuerySnapshot> feedbackStream;
    if (currentDoctorId != null) {
      feedbackStream = _firestore
          .collection('bimonthly_feedback')
          .where('doctorId', isEqualTo: currentDoctorId)
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // Fallback: show all feedback if doctorId is null
      feedbackStream = _firestore
          .collection('bimonthly_feedback')
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: feedbackStream,
      builder: (context, snapshot) {
        print(
            'Bimonthly feedback snapshot: ${snapshot.data?.docs.length ?? 0} documents');
        if (snapshot.hasError) {
          print('Bimonthly feedback error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No bimonthly feedback yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Doctor ID: $currentDoctorId',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Total docs in collection: ${snapshot.data?.docs.length ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showPatientAssignmentInfo(),
                      child: Text('Check Assignments'),
                    ),
                    ElevatedButton(
                      onPressed: () => _assignPatientsToDoctor(),
                      child: Text('Assign Patients'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _showPatientRequests(),
                  child: Text('Patient Requests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.feedback, color: Colors.blue[600]),
                ),
                title: Text('Bimonthly Health Feedback'),
                subtitle: Text(
                  'Patient: ${data['patientId']} • Health: ${data['overallHealthRating']}/10',
                  style: TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Ratings
                        _buildSectionTitle('Health Ratings (1-10)'),
                        _buildHealthRatings(data),
                        SizedBox(height: 16),

                        // Godin Exercise Questionnaire
                        _buildSectionTitle(
                            'Physical Activity Assessment (Godin)'),
                        _buildGodinQuestionnaire(data),
                        SizedBox(height: 16),

                        // Food Frequency Questionnaire
                        _buildSectionTitle('Dietary Habits Assessment'),
                        _buildFoodFrequencyQuestionnaire(data),
                        SizedBox(height: 16),

                        // SARC-F Muscle Strength
                        _buildSectionTitle(
                            'Muscle Strength Assessment (SARC-F)'),
                        _buildSarcfQuestionnaire(data),
                        SizedBox(height: 16),

                        // System Usability Scale
                        _buildSectionTitle('Application Usability Scale (SUS)'),
                        _buildSusQuestionnaire(data),
                        SizedBox(height: 16),

                        // Additional Notes
                        if (data['symptoms'] != null &&
                            (data['symptoms'] as List).isNotEmpty)
                          _buildSectionTitle('Symptoms & Side Effects'),
                        if (data['symptoms'] != null &&
                            (data['symptoms'] as List).isNotEmpty)
                          _buildSymptomsSection(data),
                        if (data['concerns'] != null &&
                            data['concerns'].isNotEmpty)
                          _buildConcernsSection(data),
                        if (data['improvements'] != null &&
                            data['improvements'].isNotEmpty)
                          _buildImprovementsSection(data),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildHealthRatings(Map<String, dynamic> data) {
    final ratings = [
      {'label': 'Overall Health', 'value': data['overallHealthRating']},
      {'label': 'Energy Level', 'value': data['energyLevel']},
      {'label': 'Mood Level', 'value': data['moodLevel']},
      {'label': 'Sleep Quality', 'value': data['sleepQuality']},
      {'label': 'Appetite Level', 'value': data['appetiteLevel']},
      {'label': 'Medication Compliance', 'value': data['medicationCompliance']},
      {'label': 'Diet Compliance', 'value': data['dietCompliance']},
      {'label': 'Exercise Compliance', 'value': data['exerciseCompliance']},
    ];

    return Column(
      children: ratings
          .map((rating) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rating['label'].toString()),
                    Text('${rating['value']}/10'),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGodinQuestionnaire(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Strenuous Exercise (×9): ${data['strenuousExercise']} times/week'),
        Text('Moderate Exercise (×5): ${data['moderateExercise']} times/week'),
        Text('Light Exercise (×3): ${data['lightExercise']} times/week'),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Godin Score: ${data['godinScore']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodFrequencyQuestionnaire(Map<String, dynamic> data) {
    final foodItems = [
      {'label': 'Vegetables', 'value': data['vegetableFreq']},
      {'label': 'Fruits/Berries', 'value': data['fruitFreq']},
      {'label': 'Nuts', 'value': data['nutsFreq']},
      {'label': 'Fish/Shellfish', 'value': data['fishFreq']},
      {'label': 'Red Meat', 'value': data['redMeatFreq']},
      {'label': 'White Meat', 'value': data['whiteMeatFreq']},
      {'label': 'Sweets/Cakes', 'value': data['sweetsFreq']},
      {'label': 'Breakfast', 'value': data['breakfastFreq']},
      {'label': 'Bread Type', 'value': data['breadType']},
      {'label': 'Dairy Products', 'value': data['dairyFreq']},
    ];

    return Column(
      children: foodItems
          .map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label'].toString()),
                    Text(
                      item['value'].toString(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSarcfQuestionnaire(Map<String, dynamic> data) {
    final sarcfItems = [
      {'label': 'Lifting 10 pounds', 'value': data['liftingDifficulty']},
      {'label': 'Walking across room', 'value': data['walkingDifficulty']},
      {'label': 'Rising from chair', 'value': data['chairDifficulty']},
      {'label': 'Climbing stairs', 'value': data['stairsDifficulty']},
      {'label': 'Falls in past year', 'value': data['fallsFrequency']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sarcfItems.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label'].toString()),
                  Text(
                    item['value'].toString(),
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'SARC-F Score: ${data['sarcfScore']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSusQuestionnaire(Map<String, dynamic> data) {
    final susItems = [
      {
        'label': 'Would like to use frequently',
        'value': data['susFrequentUse']
      },
      {'label': 'System unnecessarily complex', 'value': data['susComplexity']},
      {'label': 'System easy to use', 'value': data['susEaseOfUse']},
      {'label': 'Need technical support', 'value': data['susTechnicalSupport']},
      {'label': 'Functions well integrated', 'value': data['susIntegration']},
      {'label': 'Too much inconsistency', 'value': data['susInconsistency']},
      {'label': 'Learn to use quickly', 'value': data['susLearnQuickly']},
      {'label': 'System cumbersome', 'value': data['susCumbersome']},
      {'label': 'Confident using system', 'value': data['susConfident']},
      {'label': 'Need to learn many things', 'value': data['susLearnFirst']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...susItems.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item['label'].toString())),
                  Text(
                    '${item['value']}/5',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'SUS Score: ${data['susScore']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsSection(Map<String, dynamic> data) {
    final symptoms = data['symptoms'] as List;
    final sideEffects = data['sideEffects'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (symptoms.isNotEmpty && !symptoms.contains('None'))
          Text('Symptoms: ${symptoms.join(', ')}'),
        if (sideEffects.isNotEmpty && !sideEffects.contains('None'))
          Text('Side Effects: ${sideEffects.join(', ')}'),
        if (data['symptomsNotes'] != null && data['symptomsNotes'].isNotEmpty)
          Text('Notes: ${data['symptomsNotes']}'),
      ],
    );
  }

  Widget _buildConcernsSection(Map<String, dynamic> data) {
    return Text('Concerns: ${data['concerns']}');
  }

  Widget _buildImprovementsSection(Map<String, dynamic> data) {
    return Text('Improvements: ${data['improvements']}');
  }

  void _showPatientAssignmentInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final doctorDoc =
        await _firestore.collection('doctors').doc(user.uid).get();
    final doctorName = doctorDoc.exists
        ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
        : 'Doctor';

    final patients = await _firestore
        .collection('patients')
        .where('assignedDoctorId', isEqualTo: user.uid)
        .get();

    if (patients.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No patients assigned to $doctorName yet.')),
      );
      return;
    }

    final patientNames =
        patients.docs.map((doc) => doc.data()['fullName']).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patients Assigned to $doctorName'),
        content: SingleChildScrollView(
          child: ListBody(
            children: patientNames.map((name) => Text(name)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _assignPatientsToDoctor() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get all patients without assigned doctor
      final unassignedPatients = await _firestore
          .collection('patients')
          .where('assignedDoctorId', isNull: true)
          .limit(5) // Assign max 5 patients at once
          .get();

      if (unassignedPatients.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unassigned patients found')),
        );
        return;
      }

      // Assign patients to current doctor
      for (var doc in unassignedPatients.docs) {
        await doc.reference.update({
          'assignedDoctorId': user.uid,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Assigned ${unassignedPatients.docs.length} patients to you'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning patients: $e')),
      );
    }
  }

  void _showPatientRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get pending patient requests for this doctor
      final requests = await _firestore
          .collection('doctor_requests')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (requests.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending patient requests')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Patient Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: requests.docs.length,
              itemBuilder: (context, index) {
                final request = requests.docs[index].data();
                final patientName = request['patientName'] ?? 'Unknown Patient';
                final message = request['message'] ?? 'No message';
                final requestId = requests.docs[index].id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approvePatientRequest(
                                  requestId, request['patientId']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                            ElevatedButton(
                              onPressed: () => _rejectPatientRequest(requestId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading requests: $e')),
      );
    }
  }

  void _approvePatientRequest(String requestId, String patientId) async {
    try {
      // Update request status
      await _firestore.collection('doctor_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': DateTime.now().toIso8601String(),
      });

      // Assign patient to doctor
      await _firestore.collection('patients').doc(patientId).update({
        'assignedDoctorId': _auth.currentUser?.uid,
      });

      // Create notification for patient
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'Doctor Request Approved',
        'message': 'Your request has been approved by the doctor.',
        'type': 'doctor_request_approved',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient request approved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  void _rejectPatientRequest(String requestId) async {
    try {
      // Update request status
      await _firestore.collection('doctor_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }

  void _createSampleData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Create a sample patient
      final patientDoc = await _firestore.collection('patients').add({
        'fullName': 'John Doe',
        'email': 'john.doe@example.com',
        'assignedDoctorId': user.uid,
        'profileCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final patientId = patientDoc.id;

      // Create sample diet plan feedback
      await _firestore.collection('diet_plan_feedback').add({
        'dietPlanId': 'sample_diet_plan',
        'patientId': patientId,
        'doctorId': user.uid,
        'feedback': 'Sample meal feedback - ate as prescribed',
        'mealType': 'Breakfast',
        'eatenAsPrescribed': true,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      // Create sample prescription feedback
      await _firestore.collection('prescription_feedback').add({
        'prescriptionId': 'sample_prescription',
        'patientId': patientId,
        'doctorId': user.uid,
        'feedback': 'Sample medication feedback - taken as prescribed',
        'medicationName': 'Sample Medicine',
        'taken': true,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      // Create sample exercise feedback
      await _firestore.collection('exercise_feedback').add({
        'patientId': patientId,
        'doctorId': user.uid,
        'feedback': 'Sample exercise feedback - completed 3 days this week',
        'daysCompleted': 3,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      // Create sample bimonthly feedback
      await _firestore.collection('bimonthly_feedback').add({
        'patientId': patientId,
        'doctorId': user.uid,
        'feedback': 'Sample bimonthly health assessment',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Sample data created successfully! Check Feedback tab.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// AppointmentCard class moved outside of _DoctorDashboardState

// PrescriptionDialog class moved outside of _DoctorDashboardState
class PrescriptionDialog extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onPrescriptionCreated;

  const PrescriptionDialog({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onPrescriptionCreated,
  });

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _createPrescription() async {
    if (_medicineController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get doctor name
      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      final doctorName = doctorDoc.exists
          ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
          : 'Doctor';

      // Create prescription
      final prescriptionRef = await _firestore.collection('prescriptions').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'date': DateTime.now().toIso8601String(),
        'medications': [
          {
            'name': _medicineController.text.trim(),
            'dosage': _dosageController.text.trim(),
            'frequency': _frequencyController.text.trim(),
            'duration': _durationController.text.trim(),
            'notes': '',
          }
        ],
        'instructions': _instructionsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for patient
      await NotificationService.createPrescriptionNotification(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        prescriptionId: prescriptionRef.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPrescriptionCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating prescription: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Prescribe for ${widget.patientName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 500mg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency (e.g., Twice daily)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (e.g., 7 days)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createPrescription,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// DietPlanDialog class moved outside of _DoctorDashboardState
class DietPlanDialog extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onDietPlanCreated;

  const DietPlanDialog({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onDietPlanCreated,
  });

  @override
  State<DietPlanDialog> createState() => _DietPlanDialogState();
}

class _DietPlanDialogState extends State<DietPlanDialog> {
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _restrictionsController = TextEditingController();
  final _guidelinesController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _restrictionsController.dispose();
    _guidelinesController.dispose();
    super.dispose();
  }

  void _createDietPlan() async {
    if (_breakfastController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get doctor name
      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      final doctorName = doctorDoc.exists
          ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
          : 'Doctor';

      // Create diet plan
      final dietPlanRef = await _firestore.collection('diet_plans').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'meals': [
          {
            'type': 'Breakfast',
            'name': _breakfastController.text.trim(),
            'description': _breakfastController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': '8:00 AM',
          },
          {
            'type': 'Lunch',
            'name': _lunchController.text.trim(),
            'description': _lunchController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': '1:00 PM',
          },
          {
            'type': 'Dinner',
            'name': _dinnerController.text.trim(),
            'description': _dinnerController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': '7:00 PM',
          },
        ],
        'restrictions': _restrictionsController.text.trim().split(','),
        'nutritionGuidelines': _guidelinesController.text.trim(),
        'additionalInstructions': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for patient
      await NotificationService.createDietPlanNotification(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        dietPlanId: dietPlanRef.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDietPlanCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating diet plan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Diet Plan for ${widget.patientName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _breakfastController,
              decoration: const InputDecoration(
                labelText: 'Breakfast',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lunchController,
              decoration: const InputDecoration(
                labelText: 'Lunch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dinnerController,
              decoration: const InputDecoration(
                labelText: 'Dinner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _restrictionsController,
              decoration: const InputDecoration(
                labelText: 'Restrictions (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _guidelinesController,
              decoration: const InputDecoration(
                labelText: 'Nutrition Guidelines',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createDietPlan,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
