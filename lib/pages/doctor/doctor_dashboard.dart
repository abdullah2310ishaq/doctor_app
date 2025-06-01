import 'package:flutter/material.dart';
import 'package:doctor_app/pages/welcome_page.dart';
import 'package:doctor_app/models/appointment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/services/notification_service.dart';
import 'package:doctor_app/pages/doctor/patient_details_page.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final List<Appointment> _upcomingAppointments = [];
  bool _isLoading = true;
  String _doctorName = 'Dr. Smith';

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
        final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
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

  void _signOut() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. $_doctorName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildPatientsTab(); // NEW: Patients tab
      case 2:
        return _buildAppointmentsTab();
      default:
        return _buildHomeTab();
    }
  }

  // NEW: Patients tab showing all registered patients
  Widget _buildPatientsTab() {
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
              final patientData = patients[index].data() as Map<String, dynamic>;
              final patientId = patients[index].id;

              // Skip if this is a doctor account
              if (patientData['userType'] == 'doctor' || patientData['role'] == 'doctor') {
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
                          patientName: patientData['fullName'] ?? 'Unknown Patient',
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
                              backgroundColor: Colors.green[100],
                              child: Text(
                                patientData['fullName']?.substring(0, 1).toUpperCase() ?? 'P',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientData['fullName'] ?? 'Unknown Patient',
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
                                      color: patientData['profileCompleted'] == true
                                          ? Colors.green[100]
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
                                        color: patientData['profileCompleted'] == true
                                            ? Colors.green[800]
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
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _createPrescription(
                                  patientId,
                                  patientData['fullName'] ?? 'Unknown',
                                ),
                                icon: const Icon(Icons.medical_services),
                                label: const Text('Prescribe'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _createDietPlan(
                                  patientId,
                                  patientData['fullName'] ?? 'Unknown',
                                ),
                                icon: const Icon(Icons.restaurant_menu),
                                label: const Text('Diet Plan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                    patientName: patientData['fullName'] ?? 'Unknown Patient',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Details'),
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
                        _doctorName.isNotEmpty ? _doctorName.substring(0, 1).toUpperCase() : 'D',
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
                    Colors.green,
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
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1; // Go to Patients tab
                              });
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('View Patients'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      child: Text('Error loading recent activity: ${snapshot.error}'),
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
                    final patientName = data['patientName'] ?? 'Unknown Patient';
                    final medications = data['medications'] as List? ?? [];
                    final createdAt = data['createdAt'] as Timestamp?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.medical_services, color: Colors.blue),
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

  Widget _buildStatCard(String title, Widget value, IconData icon, Color color) {
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

    return StreamBuilder<QuerySnapshot>(
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
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
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
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(data['appointmentTime'] ?? 'No time set'),
                          const SizedBox(width: 16),
                          const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(data['appointmentType'] ?? 'General'),
                        ],
                      ),
                      if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
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
    );
  }
}

// AppointmentCard class moved outside of _DoctorDashboardState
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final appointmentDate = DateTime.parse(appointment.appointmentTime);

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
                  appointment.patientName,
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateFormat.format(appointmentDate)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(timeFormat.format(appointmentDate)),
              ],
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${appointment.notes}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
      final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
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
      final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
      final doctorName = doctorDoc.exists 
          ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
          : 'Doctor';

      // Create diet plan
      final dietPlanRef = await _firestore.collection('diet_plans').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
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
