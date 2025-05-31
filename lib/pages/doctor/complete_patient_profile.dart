import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CompletePatientProfile extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CompletePatientProfile({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CompletePatientProfile> createState() => _CompletePatientProfileState();
}

class _CompletePatientProfileState extends State<CompletePatientProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  String _getStringValue(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  void _loadPatientData() async {
    try {
      final doc = await _firestore.collection('patients').doc(widget.patientId).get();
      if (doc.exists) {
        setState(() {
          _patientData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName} - Complete Profile'),
        backgroundColor: Colors.blue[50],
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
                      
                      // Personal Information
                      _buildPersonalInformation(),
                      const SizedBox(height: 24),
                      
                      // Medical Information
                      _buildMedicalInformation(),
                      const SizedBox(height: 24),
                      
                      // Family & Activity Information
                      _buildFamilyActivityInformation(),
                      const SizedBox(height: 24),
                      
                      // Diet & Fitness Information
                      _buildDietFitnessInformation(),
                      const SizedBox(height: 24),
                      
                      // Emergency Contact
                      _buildEmergencyContact(),
                      const SizedBox(height: 24),
                      
                      // Assessment Information
                      _buildAssessmentInformation(),
                      const SizedBox(height: 24),
                      
                      // Medical History Summary
                      _buildMedicalHistorySummary(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStringValue(_patientData!['email']),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildPersonalInformation() {
    return _buildSection(
      'Personal Information',
      Icons.person,
      Colors.blue,
      [
        _buildInfoRow('Full Name', _getStringValue(_patientData!['fullName'])),
        _buildInfoRow('Date of Birth', _getStringValue(_patientData!['dateOfBirth'])),
        _buildInfoRow('Gender', _getStringValue(_patientData!['gender'])),
        _buildInfoRow('Phone', _getStringValue(_patientData!['phone'])),
        _buildInfoRow('Email', _getStringValue(_patientData!['email'])),
        _buildInfoRow('Address', _getStringValue(_patientData!['address'])),
        _buildInfoRow('Blood Group', _getStringValue(_patientData!['bloodGroup'])),
        _buildInfoRow('Height', _getStringValue(_patientData!['height'])),
        _buildInfoRow('Weight', _getStringValue(_patientData!['weight'])),
      ],
    );
  }

  Widget _buildMedicalInformation() {
    return _buildSection(
      'Medical Information',
      Icons.medical_services,
      Colors.red,
      [
        _buildInfoRow('Medical History', _getStringValue(_patientData!['medicalHistory'])),
        _buildInfoRow('Current Medications', _getStringValue(_patientData!['currentMedications'])),
        _buildInfoRow('Allergies', _getStringValue(_patientData!['allergies'])),
        _buildInfoRow('Chronic Conditions', _getStringValue(_patientData!['chronicConditions'])),
        _buildInfoRow('Previous Surgeries', _getStringValue(_patientData!['previousSurgeries'])),
        _buildInfoRow('Family Medical History', _getStringValue(_patientData!['familyMedicalHistory'])),
      ],
    );
  }

  Widget _buildFamilyActivityInformation() {
    return _buildSection(
      'Family & Activity Information',
      Icons.family_restroom,
      Colors.green,
      [
        _buildInfoRow('Marital Status', _getStringValue(_patientData!['maritalStatus'])),
        _buildInfoRow('Number of Children', _getStringValue(_patientData!['numberOfChildren'])),
        _buildInfoRow('Occupation', _getStringValue(_patientData!['occupation'])),
        _buildInfoRow('Education Level', _getStringValue(_patientData!['educationLevel'])),
        _buildInfoRow('Physical Activity Level', _getStringValue(_patientData!['physicalActivityLevel'])),
        _buildInfoRow('Exercise Frequency', _getStringValue(_patientData!['exerciseFrequency'])),
        _buildInfoRow('Smoking Status', _getStringValue(_patientData!['smokingStatus'])),
        _buildInfoRow('Alcohol Consumption', _getStringValue(_patientData!['alcoholConsumption'])),
      ],
    );
  }

  Widget _buildDietFitnessInformation() {
    return _buildSection(
      'Diet & Fitness Information',
      Icons.fitness_center,
      Colors.orange,
      [
        _buildInfoRow('Diet Type', _getStringValue(_patientData!['dietType'])),
        _buildInfoRow('Exercise Level', _getStringValue(_patientData!['exerciseLevel'])),
        _buildInfoRow('Health Goal', _getStringValue(_patientData!['healthGoal'])),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return _buildSection(
      'Emergency Contact',
      Icons.emergency,
      Colors.purple,
      [
        _buildInfoRow('Contact Name', _getStringValue(_patientData!['emergencyContactName'])),
        _buildInfoRow('Relationship', _getStringValue(_patientData!['emergencyContactRelationship'])),
        _buildInfoRow('Phone Number', _getStringValue(_patientData!['emergencyContactPhone'])),
      ],
    );
  }

  Widget _buildAssessmentInformation() {
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
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Assessment Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.brown[600]),
                const SizedBox(width: 8),
                const Text(
                  'Medical History Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
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
            width: 140,
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
