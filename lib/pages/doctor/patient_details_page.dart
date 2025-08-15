import 'package:doctor_app/pages/doctor/comprehensive_patient_detials.dart';
import 'package:doctor_app/pages/doctor/create_diet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/pages/doctor/patient_diet_strength_details.dart';
import 'package:doctor_app/widgets/weekly_vitals_chart_widget.dart';

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

    // Handle timestamp conversion for date of birth
    if (value is int || value is double) {
      try {
        // Check if it's a timestamp in seconds (Firestore timestamp)
        if (value > 1000000000) {
          // Likely a timestamp in seconds
          final date =
              DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
          return DateFormat('MMM dd, yyyy').format(date);
        } else if (value > 1000000000000) {
          // Likely a timestamp in milliseconds
          final date = DateTime.fromMillisecondsSinceEpoch(value.round());
          return DateFormat('MMM dd, yyyy').format(date);
        }
      } catch (e) {
        // If conversion fails, return as string
        return value.toString();
      }
    }

    return value.toString();
  }

  void _loadPatientDetails() async {
    try {
      final doc =
          await _firestore.collection('patients').doc(widget.patientId).get();
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
              SnackBar(
                  content:
                      Text('Prescription created for ${widget.patientName}')),
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
              SnackBar(
                  content: Text('Diet plan created for ${widget.patientName}')),
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
        title: Text(
          widget.patientName,
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
            icon: const Icon(Icons.assessment, color: Colors.white),
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
                    Icon(Icons.restaurant_menu, color: Colors.blue),
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
                      _buildPatientBaselineProfile(),
                      const SizedBox(height: 24),
                      _buildVitalSignsCharts(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildAssessmentStatus(),
                      const SizedBox(height: 24),
                      _buildPersonalInfo(),
                      const SizedBox(height: 24),
                      _buildMedicalHistory(),
                      const SizedBox(height: 24),
                      _buildRecentPrescriptions(),
                      const SizedBox(height: 24),
                      _buildRecentDietPlans(),
                      const SizedBox(height: 24),
                      _buildComplianceAndFeedback(),
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
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
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
                              ? Colors.blue[100]
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
                                ? Colors.blue[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
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

  Widget _buildPatientBaselineProfile() {
    final age = _patientData!['age']?.toString() ?? 'Not provided';
    final gender = _patientData!['gender']?.toString() ?? 'Not provided';
    final height = _patientData!['height']?.toString() ?? 'Not provided';
    final weight = _patientData!['weight']?.toString() ?? 'Not provided';
    final bloodGroup =
        _patientData!['bloodGroup']?.toString() ?? 'Not provided';
    final phoneNumber =
        _patientData!['phoneNumber']?.toString() ?? 'Not provided';
    final emergencyContact =
        _patientData!['emergencyContact']?.toString() ?? 'Not provided';
    final address = _patientData!['address']?.toString() ?? 'Not provided';
    final occupation =
        _patientData!['occupation']?.toString() ?? 'Not provided';
    final maritalStatus =
        _patientData!['maritalStatus']?.toString() ?? 'Not provided';

    // Medical baseline data
    final allergies = _patientData!['allergies']?.toString() ?? 'None reported';
    final currentMedications =
        _patientData!['currentMedications']?.toString() ?? 'None reported';
    final medicalHistory =
        _patientData!['medicalHistory']?.toString() ?? 'Not provided';
    final smokingStatus =
        _patientData!['smokingStatus']?.toString() ?? 'Not provided';
    final alcoholConsumption =
        _patientData!['alcoholConsumption']?.toString() ?? 'Not provided';
    final exerciseHabits =
        _patientData!['exerciseHabits']?.toString() ?? 'Not provided';

    // Calculate BMI if height and weight available
    String bmi = 'Not calculated';
    String bmiCategory = '';
    if (height != 'Not provided' && weight != 'Not provided') {
      try {
        final heightM = double.parse(height) / 100; // Convert cm to m
        final weightKg = double.parse(weight);
        final bmiValue = weightKg / (heightM * heightM);
        bmi = bmiValue.toStringAsFixed(1);

        if (bmiValue < 18.5) {
          bmiCategory = 'Underweight';
        } else if (bmiValue < 25) {
          bmiCategory = 'Normal';
        } else if (bmiValue < 30) {
          bmiCategory = 'Overweight';
        } else {
          bmiCategory = 'Obese';
        }
      } catch (e) {
        bmi = 'Invalid data';
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  '👤 Patient Baseline Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Demographics Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Demographics & Contact',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBaselineInfoGrid([
                    ['👤 Age', '$age years'],
                    ['⚧ Gender', gender],
                    ['📱 Phone', phoneNumber],
                    ['🚨 Emergency', emergencyContact],
                    ['🏠 Address', address],
                    ['💼 Occupation', occupation],
                    ['💑 Marital Status', maritalStatus],
                    ['🩸 Blood Group', bloodGroup],
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Physical Measurements Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.straighten,
                          color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Physical Measurements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Column(
                            children: [
                              Text('📏 Height',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                              Text('$height cm',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Column(
                            children: [
                              Text('⚖️ Weight',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                              Text('$weight kg',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _getBMIColor(bmiCategory)),
                          ),
                          child: Column(
                            children: [
                              Text('📊 BMI',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                              Text(bmi,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              if (bmiCategory.isNotEmpty)
                                Text(
                                  bmiCategory,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getBMIColor(bmiCategory),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Medical History Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Medical History & Lifestyle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBaselineInfoGrid([
                    ['🤧 Allergies', allergies],
                    ['💊 Current Medications', currentMedications],
                    ['📋 Medical History', medicalHistory],
                    ['🚬 Smoking Status', smokingStatus],
                    ['🍷 Alcohol Consumption', alcoholConsumption],
                    ['🏃 Exercise Habits', exerciseHabits],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaselineInfoGrid(List<List<String>> items) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item[0],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item[1],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Color _getBMIColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.blue[600]!;
      case 'normal':
        return Colors.green[600]!;
      case 'overweight':
        return Colors.orange[600]!;
      case 'obese':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildVitalSignsCharts() {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_heart, color: Colors.red[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '📊 Weekly Vital Signs Monitoring',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Track blood pressure and sugar levels for patient ${widget.patientName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Weekly Vitals Chart for this specific patient
        WeeklyVitalsChartWidget(patientId: widget.patientId),
      ],
    );
  }

  Widget _buildBPChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: widget.patientId)
          .where('type', isEqualTo: 'blood_pressure')
          .orderBy('timestamp', descending: false)
          .limit(7) // Last 7 readings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data?.docs ?? [];

        if (readings.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No BP readings yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add readings to see trends',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent BP Readings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[800])),
                  Text('${readings.length} readings',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final data = readings[index].data() as Map<String, dynamic>;
                    final systolic = data['systolic']?.toString() ?? '0';
                    final diastolic = data['diastolic']?.toString() ?? '0';
                    final timestamp = data['timestamp'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getBPColor(int.tryParse(systolic) ?? 0,
                            int.tryParse(diastolic) ?? 0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$systolic/$diastolic',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp)
                                .split(' ')[0], // Just date
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSugarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: widget.patientId)
          .where('type', isEqualTo: 'blood_sugar')
          .orderBy('timestamp', descending: false)
          .limit(7) // Last 7 readings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data?.docs ?? [];

        if (readings.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No sugar readings yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add readings to see trends',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Sugar Readings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800])),
                  Text('${readings.length} readings',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final data = readings[index].data() as Map<String, dynamic>;
                    final value = data['value']?.toString() ?? '0';
                    final unit = data['unit']?.toString() ?? 'mg/dL';
                    final timestamp = data['timestamp'] as String? ?? '';
                    final mealType = data['mealType']?.toString() ?? 'Random';

                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _getSugarColor(int.tryParse(value) ?? 0, mealType),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$value $unit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            mealType,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp)
                                .split(' ')[0], // Just date
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalSummaryCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBPColor(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return Colors.red[600]!;
    if (systolic >= 130 || diastolic >= 80) return Colors.orange[600]!;
    if (systolic >= 120) return Colors.amber[600]!;
    return Colors.green[600]!;
  }

  Color _getSugarColor(int value, String mealType) {
    if (mealType.toLowerCase().contains('fasting')) {
      if (value >= 126) return Colors.red[600]!;
      if (value >= 100) return Colors.orange[600]!;
      return Colors.green[600]!;
    } else {
      if (value >= 200) return Colors.red[600]!;
      if (value >= 140) return Colors.orange[600]!;
      return Colors.green[600]!;
    }
  }

  void _showAddVitalDialog(String type) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController value2Controller = TextEditingController();
    String selectedMealType = 'Fasting';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              'Add ${type == 'blood_pressure' ? 'Blood Pressure' : 'Blood Sugar'} Reading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'blood_pressure') ...[
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Systolic (mmHg)',
                      hintText: 'e.g., 120',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: value2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic (mmHg)',
                      hintText: 'e.g., 80',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ] else ...[
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Sugar (mg/dL)',
                      hintText: 'e.g., 95',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                    items: ['Fasting', 'Post-meal', 'Random', 'Bedtime']
                        .map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedMealType = value!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveVitalReading(type, valueController.text,
                  value2Controller.text, selectedMealType),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVitalReading(
      String type, String value1, String value2, String mealType) async {
    if (value1.isEmpty || (type == 'blood_pressure' && value2.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final data = {
        'patientId': widget.patientId,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'doctorId': _auth.currentUser?.uid,
      };

      if (type == 'blood_pressure') {
        data['systolic'] = value1;
        data['diastolic'] = value2;
      } else {
        data['value'] = value1;
        data['unit'] = 'mg/dL';
        data['mealType'] = mealType;
      }

      await _firestore.collection('vital_signs').add(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${type == 'blood_pressure' ? 'Blood pressure' : 'Blood sugar'} reading saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reading: $e')),
        );
      }
    }
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
                    color: Colors.blue[900],
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
                      backgroundColor: Colors.blue[600],
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
                      backgroundColor: Colors.blue[600],
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
                      backgroundColor: Colors.blue[600],
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
                  backgroundColor: Colors.blue[600],
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
                    color: Colors.blue[900],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  hasDetailedAssessment ? Icons.check_circle : Icons.cancel,
                  color: hasDetailedAssessment
                      ? Colors.blue[600]
                      : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Detailed Assessment: ${hasDetailedAssessment ? "Completed" : "Not Completed"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasDetailedAssessment
                            ? Colors.blue[600]
                            : Colors.red[600],
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
                    backgroundColor: Colors.blue[600],
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
                    color: Colors.blue[900],
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', _getStringValue(_patientData!['name'])),
            _buildInfoRow('Age', _getStringValue(_patientData!['age'])),
            _buildInfoRow('Gender', _getStringValue(_patientData!['gender'])),
            _buildInfoRow('Phone', _getStringValue(_patientData!['phone'])),
            _buildInfoRow('Email', _getStringValue(_patientData!['email'])),
            _buildInfoRow('Address', _getStringValue(_patientData!['address'])),
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
                    color: Colors.blue[900],
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
                    color: Colors.blue[900],
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
                      color: Colors.blue[50],
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
                                        color: Colors.blue[900],
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
                            }),
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
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  '🍽️ Comprehensive Diet Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('diet_plans')
                  .where('patientId', isEqualTo: widget.patientId)
                  .orderBy('startDate', descending: true)
                  .limit(2)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Diet Plans Created Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a comprehensive diet plan for this patient',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createDietPlan,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Diet Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final startDateStr = data['startDate'] ?? '';
                    final endDateStr = data['endDate'] ?? '';
                    final meals = data['meals'] as List? ?? [];
                    final goals = data['goals'] as List? ?? [];
                    final notes = data['notes'] ?? '';
                    final totalCalories =
                        data['totalCalories']?.toString() ?? '0';
                    final difficulty = data['difficulty'] ?? 'Medium';
                    final dietType = data['dietType'] ?? 'Balanced';

                    DateTime? startDate;
                    DateTime? endDate;
                    try {
                      startDate = DateTime.parse(startDateStr);
                      if (endDateStr.isNotEmpty)
                        endDate = DateTime.parse(endDateStr);
                    } catch (e) {
                      startDate = null;
                    }

                    // Calculate plan status
                    final now = DateTime.now();
                    String status = 'Active';
                    Color statusColor = Colors.green[600]!;
                    if (endDate != null && now.isAfter(endDate)) {
                      status = 'Completed';
                      statusColor = Colors.blue[600]!;
                    } else if (startDate != null && now.isBefore(startDate)) {
                      status = 'Upcoming';
                      statusColor = Colors.orange[600]!;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with date and status
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        startDate != null
                                            ? 'Plan from ${DateFormat('MMM dd, yyyy').format(startDate)}'
                                            : 'Diet Plan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                      if (endDate != null)
                                        Text(
                                          'Valid until ${DateFormat('MMM dd, yyyy').format(endDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Plan overview cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDietInfoCard(
                                      '🥗 Diet Type', dietType, Colors.green),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDietInfoCard('🔥 Calories',
                                      '$totalCalories kcal', Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDietInfoCard(
                                      '📊 Level', difficulty, Colors.blue),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Goals section
                            if (goals.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.flag,
                                            size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Diet Goals',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...goals.take(3).map((goal) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  size: 12,
                                                  color: Colors.blue[600]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  goal.toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue[700]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Meals section
                            if (meals.isNotEmpty) ...[
                              Text(
                                'Daily Meal Plan (${meals.length} meals)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...meals.take(6).map((meal) {
                                if (meal is Map<String, dynamic>) {
                                  final mealType = meal['type'] ?? 'Meal';
                                  final mealName = meal['name'] ?? 'N/A';
                                  final mealTime = meal['time'] ?? '';
                                  final calories =
                                      meal['calories']?.toString() ?? '';
                                  final description = meal['description'] ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.green[300]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    _getMealTypeColor(mealType),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                mealType.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (mealTime.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '⏰ $mealTime',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            if (calories.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$calories cal',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.orange[800],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          mealName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              if (meals.length > 6) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    '+ ${meals.length - 6} more meals...',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],

                            // Notes section
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.notes,
                                            size: 16, color: Colors.amber[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Special Instructions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[800],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      notes,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _viewDetailedDietPlan(doc.id),
                                    icon:
                                        const Icon(Icons.visibility, size: 16),
                                    label: const Text('View Details',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _editDietPlan(doc.id),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit Plan',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
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

  Widget _buildDietInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewDetailedDietPlan(String planId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening detailed view for plan: $planId')),
    );
    // TODO: Navigate to detailed diet plan view
  }

  void _editDietPlan(String planId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening editor for plan: $planId')),
    );
    // TODO: Navigate to diet plan editor
  }

  Widget _buildComplianceAndFeedback() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🩺 Patient Feedback & Compliance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
            ),
            const SizedBox(height: 16),
            // Tabs for different feedback types
            DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: Colors.blue[800],
                    unselectedLabelColor: Colors.grey[600],
                    tabs: const [
                      Tab(text: '🍽️ Meals'),
                      Tab(text: '💊 Medicines'),
                      Tab(text: '🏃 Exercise'),
                      Tab(text: '📋 Bimonthly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildMealFeedbackForPatient(),
                        _buildMedicineFeedbackForPatient(),
                        _buildExerciseFeedbackForPatient(),
                        _buildBimonthlyFeedbackForPatient(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual feedback builders for patient details page
  Widget _buildMealFeedbackForPatient() {
    // Debug: Print index creation URL for diet_plan_feedback
    print('🔥 CREATE THIS INDEX FOR MEALS:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2RpZXRfcGxhbl9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZBABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('diet_plan_feedback')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
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
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading meal feedback',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text('No Meal Feedback Yet',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    'Patient will log their meals here\nCheck back after they start logging!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Meal feedback will appear here',
                        style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as String? ?? '';
            final feedback = data['feedback'] as String? ?? '';
            final dietPlanId = data['dietPlanId'] as String? ?? '';
            final mealType = data['mealType'] as String? ?? 'Meal';
            final eatenAsPrescribed =
                data['eatenAsPrescribed'] as bool? ?? false;
            final alternativeFood = data['alternativeFood'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with meal type and compliance status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getMealTypeColor(mealType),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getMealTypeIcon(mealType),
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                mealType.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: eatenAsPrescribed
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                eatenAsPrescribed
                                    ? Icons.check_circle
                                    : Icons.warning,
                                size: 14,
                                color: eatenAsPrescribed
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                eatenAsPrescribed ? 'FOLLOWED' : 'MODIFIED',
                                style: TextStyle(
                                  color: eatenAsPrescribed
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Feedback content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Feedback:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feedback,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!eatenAsPrescribed &&
                              alternativeFood.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.restaurant,
                                          size: 14, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'What they ate instead:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alternativeFood,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Footer with timestamp and diet plan info
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        if (dietPlanId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Plan: ${dietPlanId.length > 8 ? dietPlanId.substring(0, 8) : dietPlanId}...',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.blue[600]),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicineFeedbackForPatient() {
    // Debug: Print index creation URL for prescription_feedback
    print('💊 CREATE THIS INDEX FOR MEDICINES:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl9wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3ByZXNjcmlwdGlvbl9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZBABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescription_feedback')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
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
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading medicine feedback',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                Icon(Icons.medical_services, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text('No Medicine Feedback Yet',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    'Patient will log their medications here\nCheck back after they start taking medicines!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Medicine feedback will appear here',
                        style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as String? ?? '';
            final feedback = data['feedback'] as String? ?? '';
            final prescriptionId = data['prescriptionId'] as String? ?? '';
            final medicationName =
                data['medicationName'] as String? ?? 'Medicine';
            final taken = data['taken'] as bool? ?? false;
            final notes = data['notes'] as String? ?? '';
            final time = data['time'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with medicine name and compliance status
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.medication,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    medicationName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: taken ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                taken ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color:
                                    taken ? Colors.green[700] : Colors.red[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                taken ? 'TAKEN' : 'MISSED',
                                style: TextStyle(
                                  color: taken
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Scheduled Time: $time',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Feedback content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Status:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feedback,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!taken && notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notes,
                                          size: 14, color: Colors.red[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Reason for missing:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notes,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Footer with timestamp and prescription info
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        if (prescriptionId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rx: ${prescriptionId.length > 8 ? prescriptionId.substring(0, 8) : prescriptionId}...',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.blue[600]),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseFeedbackForPatient() {
    // Debug: Print index creation URL for exercise_feedback
    print('🏃 CREATE THIS INDEX FOR EXERCISE:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2V4ZXJjaXNlX2ZlZWRiYWNrL2luZGV4ZXMvXxABGgoKBmRvY3RvcklkEAEaCwoHcGF0aWVudElkEAEaDQoJdGltZXN0YW1wEAI=');
    print('====================================');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exercise_feedback')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
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
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading exercise feedback',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text('No Exercise Feedback Yet',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    'Patient will log their exercise progress here\nCheck back after they start exercising!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Exercise progress will appear here',
                        style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as String? ?? '';
            final totalCompleted = data['totalCompleted'] as int? ?? 0;
            final totalTarget = data['totalTarget'] as int? ?? 0;
            final completionRate = data['completionRate'] as int? ?? 0;
            final weekStart = data['weekStart'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with week info and completion rate
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fitness_center,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'BIMONTHLY PROGRESS',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCompletionRateColor(completionRate),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '$completionRate%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress visualization
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[50]!, Colors.orange[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '$totalCompleted',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                  Text(
                                    'COMPLETED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                child: Stack(
                                  children: [
                                    CircularProgressIndicator(
                                      value: totalTarget > 0
                                          ? totalCompleted / totalTarget
                                          : 0,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.orange[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCompletionRateColor(completionRate),
                                      ),
                                    ),
                                    Center(
                                      child: Icon(
                                        _getCompletionIcon(completionRate),
                                        color: _getCompletionRateColor(
                                            completionRate),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$totalTarget',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'TARGET',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: totalTarget > 0
                                ? totalCompleted / totalTarget
                                : 0,
                            backgroundColor: Colors.orange[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCompletionRateColor(completionRate),
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMotivationalMessage(completionRate),
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer with timing info
                    Row(
                      children: [
                        Icon(Icons.calendar_month,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          weekStart.isNotEmpty
                              ? 'Week of ${_formatTimestamp(weekStart)}'
                              : 'This week',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Logged: ${_formatTimestamp(timestamp)}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBimonthlyFeedbackForPatient() {
    // Debug: Print index creation URL for bimonthly_feedback
    print('📋 CREATE THIS INDEX FOR BIMONTHLY:');
    print(
        'https://console.firebase.google.com/project/fir-chat-app-821a5/firestore/indexes?create_composite=Cl5wcm9qZWN0cy9maXItY2hhdC1hcHAtODIxYTUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2JpbW9udGhseV9mZWVkYmFjay9pbmRleGVzL18QARoKCgZkb2N0b3JJZBABGgsKB3BhdGllbnRJZBABGg0KCXRpbWVzdGFtcBAC');
    print('====================================');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bimonthly_feedback')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No bimonthly feedback yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('Patient will submit bimonthly assessments here',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as String? ?? '';
            final feedback = data['feedback'] as Map<String, dynamic>? ?? {};

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  child: const Icon(Icons.assignment, color: Colors.purple),
                ),
                title: Text('Bimonthly Health Assessment'),
                subtitle: Text(_formatTimestamp(timestamp)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: feedback.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${_formatFieldName(entry.key)}:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(child: Text(entry.value.toString())),
                            ],
                          ),
                        );
                      }).toList(),
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

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange[600]!;
      case 'lunch':
        return Colors.green[600]!;
      case 'dinner':
        return Colors.purple[600]!;
      case 'snack':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _getCompletionRateColor(int completionRate) {
    if (completionRate >= 80) return Colors.green[600]!;
    if (completionRate >= 60) return Colors.orange[600]!;
    if (completionRate >= 40) return Colors.amber[600]!;
    return Colors.red[600]!;
  }

  IconData _getCompletionIcon(int completionRate) {
    if (completionRate >= 80) return Icons.star;
    if (completionRate >= 60) return Icons.thumb_up;
    if (completionRate >= 40) return Icons.trending_up;
    return Icons.trending_down;
  }

  String _getMotivationalMessage(int completionRate) {
    if (completionRate >= 90) return "🏆 Excellent! Outstanding progress!";
    if (completionRate >= 80) return "🌟 Great job! Keep it up!";
    if (completionRate >= 60) return "👍 Good progress! Almost there!";
    if (completionRate >= 40) return "💪 Making progress! Don't give up!";
    return "🎯 Let's work on consistency!";
  }
}
