import 'package:doctor_app/pages/doctor/comprehensive_patient_detials.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/services/notification_service.dart';
import 'package:doctor_app/pages/doctor/patient_diet_strength_details.dart';
import 'package:doctor_app/pages/doctor/complete_patient_profile.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  String _getStringValue(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  void _loadPatientDetails() async {
    try {
      final doc = await _firestore.collection('patients').doc(widget.patientId).get();
      if (doc.exists) {
        setState(() {
          _patientData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patient details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createPrescription() {
    showDialog(
      context: context,
      builder: (context) => PrescriptionDialog(
        patientId: widget.patientId,
        patientName: widget.patientName,
        onPrescriptionCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prescription created for ${widget.patientName}')),
          );
        },
      ),
    );
  }

  void _createDietPlan() {
    showDialog(
      context: context,
      builder: (context) => DietPlanDialog(
        patientId: widget.patientId,
        patientName: widget.patientName,
        onDietPlanCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Diet plan created for ${widget.patientName}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Colors.green[50],
        actions: [
          // View Complete Profile Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletePatientProfile(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Complete Profile',
          ),
          // View Diet & Strength Details Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDietStrengthDetails(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assessment),
            tooltip: 'Diet & Strength Assessment',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'prescribe') {
                _createPrescription();
              } else if (value == 'diet_plan') {
                _createDietPlan();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'prescribe',
                child: Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Create Prescription'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'diet_plan',
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Create Diet Plan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patientData == null
              ? const Center(child: Text('Patient data not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Header
                      _buildPatientHeader(),
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      
                      // Assessment Status
                      _buildAssessmentStatus(),
                      const SizedBox(height: 24),
                      
                      // Personal Information
                      _buildPersonalInfo(),
                      const SizedBox(height: 24),
                      
                      // Medical Information
                      _buildMedicalInfo(),
                      const SizedBox(height: 24),
                      
                      // Emergency Contact
                      _buildEmergencyContact(),
                      const SizedBox(height: 24),
                      
                      // Medical History
                      _buildMedicalHistory(),
                      const SizedBox(height: 24),
                      
                      // Recent Prescriptions
                      _buildRecentPrescriptions(),
                      const SizedBox(height: 24),
                      
                      // Recent Diet Plans
                      _buildRecentDietPlans(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStringValue(_patientData!['email']),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _patientData!['profileCompleted'] == true
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _patientData!['profileCompleted'] == true
                              ? 'Profile Complete'
                              : 'Profile Incomplete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _patientData!['profileCompleted'] == true
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_patientData!['dateOfBirth'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Age: ${_calculateAge(_getStringValue(_patientData!['dateOfBirth']))}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
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
                    onPressed: _createPrescription,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Prescribe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createDietPlan,
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Diet Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientDietStrengthDetails(
                            patientId: widget.patientId,
                            patientName: widget.patientName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment),
                    label: const Text('Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompletePatientProfile(
                            patientId: widget.patientId,
                            patientName: widget.patientName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Full Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComprehensivePatientDetails(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.description),
                label: const Text('Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentStatus() {
    final hasDetailedAssessment = _patientData!['dietaryHabits'] != null ||
        _patientData!['muscleStrength'] != null ||
        _patientData!['applicationUsability'] != null;
    
    final hasSimpleAssessment = _patientData!['dietType'] != null ||
        _patientData!['exerciseLevel'] != null ||
        _patientData!['healthGoal'] != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  hasDetailedAssessment ? Icons.check_circle : Icons.cancel,
                  color: hasDetailedAssessment ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detailed Assessment: ${hasDetailedAssessment ? "Completed" : "Not Completed"}',
                  style: TextStyle(
                    color: hasDetailedAssessment ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasSimpleAssessment ? Icons.check_circle : Icons.cancel,
                  color: hasSimpleAssessment ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Basic Assessment: ${hasSimpleAssessment ? "Completed" : "Not Completed"}',
                  style: TextStyle(
                    color: hasSimpleAssessment ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (hasDetailedAssessment || hasSimpleAssessment) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDietStrengthDetails(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Assessment Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', _getStringValue(_patientData!['name'])),
            _buildInfoRow('Date of Birth', _getStringValue(_patientData!['dateOfBirth'])),
            _buildInfoRow('Age', _getStringValue(_patientData!['age'])),
            _buildInfoRow('Gender', _getStringValue(_patientData!['gender'])),
            _buildInfoRow('Marital Status', _getStringValue(_patientData!['maritalStatus'])),
            _buildInfoRow('Living Situation', _getStringValue(_patientData!['livingSituation'])),
            _buildInfoRow('Phone', _getStringValue(_patientData!['phone'])),
            _buildInfoRow('Email', _getStringValue(_patientData!['email'])),
            _buildInfoRow('Address', _getStringValue(_patientData!['address'])),
            _buildInfoRow('Blood Group', _getStringValue(_patientData!['bloodGroup'])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Contact Name', _getStringValue(_patientData!['emergencyContactName'])),
            _buildInfoRow('Relationship', _getStringValue(_patientData!['emergencyContactRelationship'])),
            _buildInfoRow('Phone Number', _getStringValue(_patientData!['emergencyContactPhone'])),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Medical History', _getStringValue(_patientData!['medicalHistory'])),
            _buildInfoRow('Current Medications', _getStringValue(_patientData!['currentMedications'])),
            _buildInfoRow('Allergies', _getStringValue(_patientData!['allergies'])),
            _buildInfoRow('Chronic Conditions', _getStringValue(_patientData!['chronicConditions'])),
            _buildInfoRow('Previous Surgeries', _getStringValue(_patientData!['previousSurgeries'])),
            _buildInfoRow('Family Medical History', _getStringValue(_patientData!['familyMedicalHistory'])),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical History Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Appointments Count
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('patientId', isEqualTo: widget.patientId)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildInfoRow('Total Appointments', count.toString());
              },
            ),
            
            // Prescriptions Count
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('prescriptions')
                  .where('patientId', isEqualTo: widget.patientId)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildInfoRow('Total Prescriptions', count.toString());
              },
            ),
            
            // Diet Plans Count
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('diet_plans')
                  .where('patientId', isEqualTo: widget.patientId)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildInfoRow('Total Diet Plans', count.toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPrescriptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Prescriptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('prescriptions')
                  .where('patientId', isEqualTo: widget.patientId)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No prescriptions found');
                }
                
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = aData['date'] ?? '';
                  final bDate = bData['date'] ?? '';
                  return bDate.compareTo(aDate);
                });
                
                return Column(
                  children: docs.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateStr = data['date'] ?? '';
                    final medications = data['medications'] as List? ?? [];
                    
                    DateTime? date;
                    try {
                      date = DateTime.parse(dateStr);
                    } catch (e) {
                      date = null;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date != null 
                                      ? DateFormat('MMM dd, yyyy').format(date)
                                      : 'Date not available',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${medications.length} medications',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...medications.map((med) {
                              if (med is Map<String, dynamic>) {
                                return Text(
                                  '• ${med['name'] ?? 'Unknown'} - ${med['dosage'] ?? 'N/A'} (${med['frequency'] ?? 'N/A'})',
                                  style: const TextStyle(fontSize: 14),
                                );
                              }
                              return Text(
                                '• $med',
                                style: const TextStyle(fontSize: 14),
                              );
                            }).toList(),
                          ],
                        ),
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

  Widget _buildRecentDietPlans() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Diet Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('diet_plans')
                  .where('patientId', isEqualTo: widget.patientId)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No diet plans found');
                }
                
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = aData['startDate'] ?? '';
                  final bDate = bData['startDate'] ?? '';
                  return bDate.compareTo(aDate);
                });
                
                return Column(
                  children: docs.take(3).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final startDateStr = data['startDate'] ?? '';
                    final meals = data['meals'] as List? ?? [];
                    
                    DateTime? startDate;
                    try {
                      startDate = DateTime.parse(startDateStr);
                    } catch (e) {
                      startDate = null;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  startDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(startDate)
                                      : 'Date not available',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${meals.length} meals',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...meals.map((meal) {
                              if (meal is Map<String, dynamic>) {
                                return Text(
                                  '• ${meal['type'] ?? 'Unknown'}: ${meal['name'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 14),
                                );
                              }
                              return Text(
                                '• $meal',
                                style: const TextStyle(fontSize: 14),
                              );
                            }).toList(),
                          ],
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(String dateOfBirth) {
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}

// Prescription Dialog (same as before but with doctor name)
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

// Diet Plan Dialog (same as before but with doctor name)
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
