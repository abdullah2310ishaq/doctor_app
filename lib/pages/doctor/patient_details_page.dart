import 'package:doctor_app/pages/doctor/comprehensive_patient_detials.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/pages/doctor/patient_diet_strength_details.dart';

import 'create_diet.dart';
import 'create_prescription.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrescriptionPage(
          patientId: widget.patientId,
          patientName: widget.patientName,
          onPrescriptionCreated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Prescription created for ${widget.patientName}')),
            );
          },
        ),
      ),
    );
  }

  void _createDietPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDietPlanPage(
          patientId: widget.patientId,
          patientName: widget.patientName,
          onDietPlanCreated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Diet plan created for ${widget.patientName}')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Colors.teal[50],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[100]!, Colors.teal[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => CompletePatientProfile(
          //           patientId: widget.patientId,
          //           patientName: widget.patientName,
          //         ),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.person, color: Colors.teal),
          //   tooltip: 'Complete Profile',
          // ),
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
            icon: const Icon(Icons.assessment, color: Colors.teal),
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
                    Icon(Icons.medical_services, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Create Prescription'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'diet_plan',
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.teal),
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
              ? Center(
                  child: Text(
                    'Patient data not found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientHeader(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildAssessmentStatus(),
                      const SizedBox(height: 24),
                      _buildPersonalInfo(),
                      const SizedBox(height: 24),
                      _buildMedicalInfo(),
                      const SizedBox(height: 24),
                      _buildEmergencyContact(),
                      const SizedBox(height: 24),
                      _buildMedicalHistory(),
                      const SizedBox(height: 24),
                      _buildRecentPrescriptions(),
                      const SizedBox(height: 24),
                      _buildRecentDietPlans(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStringValue(_patientData!['email']),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              ? Colors.teal[100]
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
                                ? Colors.teal[800]
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    onPressed: _createPrescription,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Prescribe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => CompletePatientProfile(
                //             patientId: widget.patientId,
                //             patientName: widget.patientName,
                //           ),
                //         ),
                //       );
                //     },
                //     icon: const Icon(Icons.person),
                //     label: const Text('Full Profile'),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  hasDetailedAssessment ? Icons.check_circle : Icons.cancel,
                  color: hasDetailedAssessment ? Colors.teal : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Detailed Assessment: ${hasDetailedAssessment ? "Completed" : "Not Completed"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasDetailedAssessment ? Colors.teal : Colors.red[600],
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
                  color: hasSimpleAssessment ? Colors.teal : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Basic Assessment: ${hasSimpleAssessment ? "Completed" : "Not Completed"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasSimpleAssessment ? Colors.teal : Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            if (hasDetailedAssessment || hasSimpleAssessment) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Assessment Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical History Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 16),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  .where('patientId', isEqualTo: widget.patientId)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(
                    'No prescriptions found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  );
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
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                ),
                                Text(
                                  '${medications.length} medications',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...medications.map((med) {
                              if (med is Map<String, dynamic>) {
                                return Text(
                                  '• ${med['name'] ?? 'Unknown'} - ${med['dosage'] ?? 'N/A'} (${med['frequency'] ?? 'N/A'})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                );
                              }
                              return Text(
                                '• $med',
                                style: Theme.of(context).textTheme.bodyMedium,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Diet Plans',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
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
                  return Text(
                    'No diet plans found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  );
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
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                ),
                                Text(
                                  '${meals.length} meals',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...meals.map((meal) {
                              if (meal is Map<String, dynamic>) {
                                return Text(
                                  '• ${meal['type'] ?? 'Unknown'}: ${meal['name'] ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                );
                              }
                              return Text(
                                '• $meal',
                                style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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