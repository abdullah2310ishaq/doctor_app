import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ComprehensivePatientDetails extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ComprehensivePatientDetails({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ComprehensivePatientDetails> createState() =>
      _ComprehensivePatientDetailsState();
}

class _ComprehensivePatientDetailsState
    extends State<ComprehensivePatientDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
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

  String _safeToString(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is String) return value.isEmpty ? 'Not provided' : value;
    if (value is List) {
      if (value.isEmpty) return 'None';
      return value.join(', ');
    }
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }

  Future<void> _generatePDF() async {
    if (_patientData == null) return;

    try {
      final pdf = pw.Document();

      // Get health and family data
      final healthLifestyle =
          _patientData!['healthLifestyle'] as Map<String, dynamic>?;
      final medicalHistory =
          _patientData!['medicalHistory'] as Map<String, dynamic>?;
      final familyHistory =
          _patientData!['familyHistory'] as Map<String, dynamic>?;
      final activityData =
          _patientData!['activityData'] as Map<String, dynamic>?;
      final dietaryHabits =
          _patientData!['dietaryHabits'] as Map<String, dynamic>?;
      final muscleStrength =
          _patientData!['muscleStrength'] as Map<String, dynamic>?;
      final appUsability =
          _patientData!['applicationUsability'] as Map<String, dynamic>?;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Patient Medical Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Patient Info Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      widget.patientName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text('Age: ${_safeToString(_patientData!['age'])}'),
                        pw.SizedBox(width: 20),
                        pw.Text(
                            'Gender: ${_safeToString(_patientData!['gender'])}'),
                        pw.SizedBox(width: 20),
                        pw.Text(
                            'Blood Group: ${_safeToString(_patientData!['bloodGroup'])}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Email: ${_safeToString(_patientData!['email'])}'),
                    pw.Text('Phone: ${_safeToString(_patientData!['phone'])}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Personal Information
              _buildPDFSection('Personal Information', [
                'Full Name: ${_safeToString(_patientData!['name'])}',
                'Age: ${_safeToString(_patientData!['age'])}',
                'Gender: ${_safeToString(_patientData!['gender'])}',
                'Blood Group: ${_safeToString(_patientData!['bloodGroup'])}',
                'Phone: ${_safeToString(_patientData!['phone'])}',
                'Address: ${_safeToString(_patientData!['address'])}',
                'Emergency Contact: ${_safeToString(_patientData!['emergencyContact'])}',
                'Email: ${_safeToString(_patientData!['email'])}',
              ]),

              pw.SizedBox(height: 16),

              // Health & Lifestyle Information
              _buildPDFSection('Health & Lifestyle Information', [
                'Height: ${_safeToString(healthLifestyle?['height'])}',
                'Weight: ${_safeToString(healthLifestyle?['weight'])}',
                'Smoking History: ${_safeToString(healthLifestyle?['smokingHistory'])}',
                'Alcohol Consumption: ${_safeToString(healthLifestyle?['alcoholConsumption'])}',
                'Daily Activity Level: ${_safeToString(healthLifestyle?['dailyActivityLevel'])}',
                'Medical Conditions: ${_safeToString(medicalHistory?['conditions'])}',
                'Current Medications: ${_safeToString(medicalHistory?['currentMedications'])}',
                'Allergies: ${_safeToString(medicalHistory?['allergies'])}',
                'Recent Surgeries: ${_safeToString(medicalHistory?['recentSurgeries'])}',
                'Assistive Devices: ${_safeToString(medicalHistory?['assistiveDevices'])}',
                'Tuberculosis History: ${_safeToString(medicalHistory?['tuberculosisHistory'])}',
                'Mental Health Care: ${_safeToString(medicalHistory?['mentalHealthClinicianCare'])}',
                'Restricted Eating History: ${_safeToString(medicalHistory?['restrictedEatingHistory'])}',
              ]),

              pw.SizedBox(height: 16),

              // Family History
              _buildPDFSection('Family History', [
                'Family Medical History: ${_safeToString(familyHistory?['familyMedicalHistory'])}',
                'Genetic Conditions: ${_safeToString(familyHistory?['geneticConditions'])}',
                'Family Cancer History: ${_safeToString(familyHistory?['familyCancerHistory'])}',
                'Family Heart Disease: ${_safeToString(familyHistory?['familyHeartDisease'])}',
                'Family Diabetes: ${_safeToString(familyHistory?['familyDiabetes'])}',
                'Family Mental Health: ${_safeToString(familyHistory?['familyMentalHealth'])}',
              ]),

              pw.SizedBox(height: 16),

              // Activity Information
              _buildPDFSection('Activity Information', [
                'Physical Activity Level: ${_safeToString(activityData?['physicalActivityLevel'])}',
                'Exercise Frequency: ${_safeToString(activityData?['exerciseFrequency'])}',
                'Exercise Types: ${_safeToString(activityData?['exerciseTypes'])}',
                'Sports Participation: ${_safeToString(activityData?['sportsParticipation'])}',
                'Physical Limitations: ${_safeToString(activityData?['physicalLimitations'])}',
              ]),

              pw.SizedBox(height: 16),

              // Diet Assessment
              if (dietaryHabits != null) ...[
                _buildPDFSection(
                    'Diet Assessment (Food Frequency Questionnaire)', [
                  'Q1. Vegetables: ${_safeToString(dietaryHabits['Q1'])}',
                  'Q2. Fruits/Berries: ${_safeToString(dietaryHabits['Q2'])}',
                  'Q3. Nuts: ${_safeToString(dietaryHabits['Q3'])}',
                  'Q4. Fish/Shellfish: ${_safeToString(dietaryHabits['Q4'])}',
                  'Q5. Red Meat: ${_safeToString(dietaryHabits['Q5'])}',
                  'Q6. White Meat: ${_safeToString(dietaryHabits['Q6'])}',
                  'Q7. Junk Food: ${_safeToString(dietaryHabits['Q7'])}',
                  'Q8. Breakfast: ${_safeToString(dietaryHabits['Q8'])}',
                  'Q9b. Bread Type: ${_safeToString(dietaryHabits['Q9b'])}',
                  'Q10. Dairy: ${_safeToString(dietaryHabits['Q10'])}',
                  'Q11. Milk Type: ${_safeToString(dietaryHabits['Q11'])}',
                  'Q12. Spread Type: ${_safeToString(dietaryHabits['Q12'])}',
                  'Q13. Cooking Fat: ${_safeToString(dietaryHabits['Q13'])}',
                  'Q14. Salt Usage: ${_safeToString(dietaryHabits['Q14'])}',
                ]),
                pw.SizedBox(height: 16),
              ],

              // Muscle Strength Assessment
              if (muscleStrength != null) ...[
                _buildPDFSection('Muscle Strength Assessment (SARC-F)', [
                  'Strength (Lifting 10 pounds): ${_safeToString(muscleStrength['Strength'])}',
                  'Walking Assistance: ${_safeToString(muscleStrength['Assistance in walking'])}',
                  'Rising from Chair: ${_safeToString(muscleStrength['Rise from a chair'])}',
                  'Climbing Stairs: ${_safeToString(muscleStrength['Climb stairs'])}',
                  'Falls in Last Year: ${_safeToString(muscleStrength['Falls'])}',
                ]),
                pw.SizedBox(height: 16),
              ],

              // App Usability Assessment
              if (appUsability != null) ...[
                _buildPDFSection('App Usability Assessment (SUS)', [
                  'Frequent Use: ${_safeToString(appUsability['I think that I would like to use this system frequently'])}',
                  'System Complexity: ${_safeToString(appUsability['I found the system unnecessarily complex'])}',
                  'Ease of Use: ${_safeToString(appUsability['I thought the system was easy to use'])}',
                  'Technical Support Need: ${_safeToString(appUsability['I think that I would need the support of a technical person to be able to use this system'])}',
                  'Function Integration: ${_safeToString(appUsability['I found the various functions in this system were well integrated'])}',
                  'System Inconsistency: ${_safeToString(appUsability['I thought there was too much inconsistency in this system'])}',
                  'Learning Speed: ${_safeToString(appUsability['I would imagine that most people would learn to use this system very quickly'])}',
                  'System Cumbersome: ${_safeToString(appUsability['I found the system very cumbersome to use'])}',
                  'Confidence Level: ${_safeToString(appUsability['I felt very confident using the system'])}',
                  'Learning Requirement: ${_safeToString(appUsability['I needed to learn a lot of things before I could get going with this system'])}',
                ]),
              ],

              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'This report was generated automatically from the patient management system. '
                  'For any questions or clarifications, please contact the healthcare provider.',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );

      // Show print/save dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Patient_Report_${widget.patientName}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPDFSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: items
                .map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(item,
                          style: const pw.TextStyle(fontSize: 11)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Profile: ${widget.patientName}'),
        backgroundColor: Colors.blue[50],
        actions: [
          IconButton(
            onPressed: _patientData != null ? _generatePDF : null,
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF Report',
          ),
          IconButton(
            onPressed: _patientData != null ? () => _showExportOptions() : null,
            icon: const Icon(Icons.share),
            tooltip: 'Share/Export',
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
                      const SizedBox(height: 20),

                      // Quick Stats Row
                      _buildQuickStats(),
                      const SizedBox(height: 20),

                      // Personal Information (Form 1)
                      _buildSection(
                          '👤 Personal Information', _buildPersonalInfo()),
                      const SizedBox(height: 20),

                      // Health & Lifestyle Information (Form 2)
                      _buildSection('🏥 Health & Lifestyle Information',
                          _buildHealthLifestyleInfo()),
                      const SizedBox(height: 20),

                      // Family & Activity Information (Form 3)
                      _buildSection('👨‍👩‍👧‍👦 Family & Activity Information',
                          _buildFamilyActivityInfo()),
                      const SizedBox(height: 20),

                      // Diet Assessment (Form 4 - Part 1)
                      _buildSection(
                          '🍎 Diet Assessment (Food Frequency Questionnaire)',
                          _buildDietAssessment()),
                      const SizedBox(height: 20),

                      // Muscle Strength Assessment (Form 4 - Part 2)
                      _buildSection('💪 Muscle Strength Assessment (SARC-F)',
                          _buildStrengthAssessment()),
                      const SizedBox(height: 20),

                      // App Usability Assessment (Form 4 - Part 3)
                      _buildSection('📱 App Usability Assessment (SUS)',
                          _buildUsabilityAssessment()),
                      const SizedBox(height: 20),

                      // Recent Medical Records
                      _buildSection(
                          '📋 Recent Medical Records', _buildMedicalRecords()),
                    ],
                  ),
                ),
      floatingActionButton: _patientData != null
          ? FloatingActionButton.extended(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Download as PDF'),
              subtitle: const Text('Save complete patient report'),
              onTap: () {
                Navigator.pop(context);
                _generatePDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Print Report'),
              subtitle: const Text('Print patient details'),
              onTap: () {
                Navigator.pop(context);
                _generatePDF(); // Same function handles both
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Report'),
              subtitle: const Text('Share via email or messaging'),
              onTap: () {
                Navigator.pop(context);
                _generatePDF(); // PDF can be shared from print dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  // ... (rest of the existing methods remain the same)
  Widget _buildPatientHeader() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[200],
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
                    const SizedBox(height: 4),
                    Text(
                      _safeToString(_patientData!['email']),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                            'Age: ${_safeToString(_patientData!['age'])}',
                            Colors.blue),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          _patientData!['profileCompleted'] == true
                              ? 'Complete'
                              : 'Incomplete',
                          _patientData!['profileCompleted'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(_safeToString(_patientData!['gender']),
                            Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    // Get height and weight from healthLifestyle section
    final healthLifestyle =
        _patientData!['healthLifestyle'] as Map<String, dynamic>?;
    final height = healthLifestyle?['height'] ?? 'Not provided';
    final weight = healthLifestyle?['weight'] ?? 'Not provided';

    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Blood Group',
                _safeToString(_patientData!['bloodGroup']),
                Icons.bloodtype,
                Colors.red)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Height', _safeToString(height), Icons.height, Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Weight', _safeToString(weight),
                Icons.monitor_weight, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildSection(String title, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  // Form 1: Personal Information
  Widget _buildPersonalInfo() {
    return Column(
      children: [
        _buildDetailRow('Full Name', _safeToString(_patientData!['name'])),
        _buildDetailRow('Age', _safeToString(_patientData!['age'])),
        _buildDetailRow('Gender', _safeToString(_patientData!['gender'])),
        _buildDetailRow(
            'Blood Group', _safeToString(_patientData!['bloodGroup'])),
        _buildDetailRow('Phone Number', _safeToString(_patientData!['phone'])),
        _buildDetailRow('Address', _safeToString(_patientData!['address'])),
        _buildDetailRow('Emergency Contact',
            _safeToString(_patientData!['emergencyContact'])),
        _buildDetailRow('Email', _safeToString(_patientData!['email'])),
      ],
    );
  }

  // Form 2: Health & Lifestyle Information
  Widget _buildHealthLifestyleInfo() {
    final healthLifestyle =
        _patientData!['healthLifestyle'] as Map<String, dynamic>?;
    final medicalHistory =
        _patientData!['medicalHistory'] as Map<String, dynamic>?;

    return Column(
      children: [
        // Physical measurements
        const Text('Physical Measurements:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDetailRow('Height', _safeToString(healthLifestyle?['height'])),
        _buildDetailRow('Weight', _safeToString(healthLifestyle?['weight'])),

        const SizedBox(height: 16),
        const Text('Lifestyle Information:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDetailRow('Smoking History',
            _safeToString(healthLifestyle?['smokingHistory'])),
        _buildDetailRow('Alcohol Consumption',
            _safeToString(healthLifestyle?['alcoholConsumption'])),
        _buildDetailRow('Daily Activity Level',
            _safeToString(healthLifestyle?['dailyActivityLevel'])),

        const SizedBox(height: 16),
        const Text('Medical Information:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDetailRow(
            'Medical Conditions', _safeToString(medicalHistory?['conditions'])),
        _buildDetailRow('Current Medications',
            _safeToString(medicalHistory?['currentMedications'])),
        _buildDetailRow(
            'Allergies', _safeToString(medicalHistory?['allergies'])),
        _buildDetailRow('Recent Surgeries',
            _safeToString(medicalHistory?['recentSurgeries'])),
        if (medicalHistory?['recentSurgeriesSpecify'] != null)
          _buildDetailRow('Surgery Details',
              _safeToString(medicalHistory?['recentSurgeriesSpecify'])),
        _buildDetailRow('Assistive Devices',
            _safeToString(medicalHistory?['assistiveDevices'])),
        _buildDetailRow('Tuberculosis History',
            _safeToString(medicalHistory?['tuberculosisHistory'])),
        _buildDetailRow('Mental Health Clinician Care',
            _safeToString(medicalHistory?['mentalHealthClinicianCare'])),
        _buildDetailRow('Restricted Eating History',
            _safeToString(medicalHistory?['restrictedEatingHistory'])),
      ],
    );
  }

  // Form 3: Family & Activity Information
  Widget _buildFamilyActivityInfo() {
    final familyHistory =
        _patientData!['familyHistory'] as Map<String, dynamic>?;
    final activityData = _patientData!['activityData'] as Map<String, dynamic>?;

    return Column(
      children: [
        const Text('Family History:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDetailRow('Family Medical History',
            _safeToString(familyHistory?['familyMedicalHistory'])),
        _buildDetailRow('Genetic Conditions',
            _safeToString(familyHistory?['geneticConditions'])),
        _buildDetailRow('Family Cancer History',
            _safeToString(familyHistory?['familyCancerHistory'])),
        _buildDetailRow('Family Heart Disease',
            _safeToString(familyHistory?['familyHeartDisease'])),
        _buildDetailRow(
            'Family Diabetes', _safeToString(familyHistory?['familyDiabetes'])),
        _buildDetailRow('Family Mental Health Issues',
            _safeToString(familyHistory?['familyMentalHealth'])),
        const SizedBox(height: 16),
        const Text('Activity Information:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDetailRow('Physical Activity Level',
            _safeToString(activityData?['physicalActivityLevel'])),
        _buildDetailRow('Exercise Frequency',
            _safeToString(activityData?['exerciseFrequency'])),
        _buildDetailRow(
            'Exercise Types', _safeToString(activityData?['exerciseTypes'])),
        _buildDetailRow('Sports Participation',
            _safeToString(activityData?['sportsParticipation'])),
        _buildDetailRow('Physical Limitations',
            _safeToString(activityData?['physicalLimitations'])),
      ],
    );
  }

  // Form 4 - Part 1: Diet Assessment
  Widget _buildDietAssessment() {
    final dietaryHabits =
        _patientData!['dietaryHabits'] as Map<String, dynamic>?;
    if (dietaryHabits == null) {
      return const Text('No dietary assessment data available');
    }

    return Column(
      children: [
        _buildDetailRow('Q1. How often do you eat vegetables?',
            _safeToString(dietaryHabits['Q1'])),
        _buildDetailRow('Q2. How often do you eat fruit and/or berries?',
            _safeToString(dietaryHabits['Q2'])),
        _buildDetailRow('Q3. How often do you eat nuts?',
            _safeToString(dietaryHabits['Q3'])),
        _buildDetailRow('Q4. How often do you eat fish or shellfish?',
            _safeToString(dietaryHabits['Q4'])),
        _buildDetailRow('Q5. How often do you eat red meat?',
            _safeToString(dietaryHabits['Q5'])),
        _buildDetailRow('Q6. How often do you eat white meat?',
            _safeToString(dietaryHabits['Q6'])),
        _buildDetailRow(
            'Q7. How often do you eat buns/cakes, chocolate/sweets, crisps or soda/juice?',
            _safeToString(dietaryHabits['Q7'])),
        _buildDetailRow('Q8. How often do you eat breakfast?',
            _safeToString(dietaryHabits['Q8'])),
        _buildDetailRow('Q9b. What type(s) of bread do you eat?',
            _safeToString(dietaryHabits['Q9b'])),
        _buildDetailRow(
            'Q10. How often do you drink/eat milk, sour milk and/or yoghurt?',
            _safeToString(dietaryHabits['Q10'])),
        _buildDetailRow(
            'Q11. What type of milk, sour milk and/or yoghurt do you usually drink/eat?',
            _safeToString(dietaryHabits['Q11'])),
        _buildDetailRow(
            'Q12. What kind of spread do you usually use on sandwiches?',
            _safeToString(dietaryHabits['Q12'])),
        _buildDetailRow(
            'Q13. What kind of fat do you usually use for cooking at home?',
            _safeToString(dietaryHabits['Q13'])),
        _buildDetailRow('Q14. Do you usually add salt to your food?',
            _safeToString(dietaryHabits['Q14'])),
      ],
    );
  }

  // Form 4 - Part 2: Muscle Strength Assessment
  Widget _buildStrengthAssessment() {
    final muscleStrength =
        _patientData!['muscleStrength'] as Map<String, dynamic>?;
    if (muscleStrength == null) {
      return const Text('No muscle strength assessment data available');
    }

    return Column(
      children: [
        _buildDetailRow(
            'Strength (How much difficulty do you have in lifting or carrying 10 pounds?)',
            _safeToString(muscleStrength['Strength'])),
        _buildDetailRow(
            'Assistance in walking (How much difficulty do you have walking across a room?)',
            _safeToString(muscleStrength['Assistance in walking'])),
        _buildDetailRow(
            'Rise from a chair (How much difficulty do you have transferring from a chair or bed?)',
            _safeToString(muscleStrength['Rise from a chair'])),
        _buildDetailRow(
            'Climb stairs (How much difficulty do you have climbing a flight of 10 stairs?)',
            _safeToString(muscleStrength['Climb stairs'])),
        _buildDetailRow(
            'Falls (How many times have you fallen in the last year?)',
            _safeToString(muscleStrength['Falls'])),
      ],
    );
  }

  // Form 4 - Part 3: App Usability Assessment
  Widget _buildUsabilityAssessment() {
    final appUsability =
        _patientData!['applicationUsability'] as Map<String, dynamic>?;
    if (appUsability == null) {
      return const Text('No app usability assessment data available');
    }

    return Column(
      children: [
        _buildDetailRow(
            'I think that I would like to use this system frequently',
            _safeToString(appUsability[
                'I think that I would like to use this system frequently'])),
        _buildDetailRow(
            'I found the system unnecessarily complex',
            _safeToString(
                appUsability['I found the system unnecessarily complex'])),
        _buildDetailRow(
            'I thought the system was easy to use',
            _safeToString(
                appUsability['I thought the system was easy to use'])),
        _buildDetailRow(
            'I think that I would need the support of a technical person to be able to use this system',
            _safeToString(appUsability[
                'I think that I would need the support of a technical person to be able to use this system'])),
        _buildDetailRow(
            'I found the various functions in this system were well integrated',
            _safeToString(appUsability[
                'I found the various functions in this system were well integrated'])),
        _buildDetailRow(
            'I thought there was too much inconsistency in this system',
            _safeToString(appUsability[
                'I thought there was too much inconsistency in this system'])),
        _buildDetailRow(
            'I would imagine that most people would learn to use this system very quickly',
            _safeToString(appUsability[
                'I would imagine that most people would learn to use this system very quickly'])),
        _buildDetailRow(
            'I found the system very cumbersome to use',
            _safeToString(
                appUsability['I found the system very cumbersome to use'])),
        _buildDetailRow(
            'I felt very confident using the system',
            _safeToString(
                appUsability['I felt very confident using the system'])),
        _buildDetailRow(
            'I needed to learn a lot of things before I could get going with this system',
            _safeToString(appUsability[
                'I needed to learn a lot of things before I could get going with this system'])),
      ],
    );
  }

  Widget _buildMedicalRecords() {
    return Column(
      children: [
        // Recent Prescriptions
        const Text('Recent Prescriptions:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('prescriptions')
              .where('patientId', isEqualTo: widget.patientId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No prescriptions found');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final medications = data['medications'] as List? ?? [];
                final dateStr = data['date'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.green[50],
                  child: ListTile(
                    leading:
                        const Icon(Icons.medical_services, color: Colors.green),
                    title: Text('Date: $dateStr'),
                    subtitle:
                        Text('${medications.length} medications prescribed'),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Recent Diet Plans
        const Text('Recent Diet Plans:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('diet_plans')
              .where('patientId', isEqualTo: widget.patientId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No diet plans found');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final meals = data['meals'] as List? ?? [];
                final startDateStr = data['startDate'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.orange[50],
                  child: ListTile(
                    leading:
                        const Icon(Icons.restaurant_menu, color: Colors.orange),
                    title: Text('Start Date: $startDateStr'),
                    subtitle: Text('${meals.length} meals planned'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                fontWeight: FontWeight.w600,
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

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }
}
