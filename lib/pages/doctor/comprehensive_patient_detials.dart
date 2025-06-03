import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
      setState(() {
        _patientData = doc.exists ? doc.data() : null;
        _isLoading = false;
      });
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
    if (value is List) return value.isEmpty ? 'None' : value.join(', ');
    if (value is Map)
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return value.toString();
  }

  Future<Map<String, dynamic>?> _generatePDF({bool forSharing = false}) async {
    if (_patientData == null) return null;

    try {
      final pdf = pw.Document();

      final healthLifestyle =
          _patientData!['healthLifestyle'] as Map<String, dynamic>?;
      final medicalHistory =
          _patientData!['medicalHistory'] as Map<String, dynamic>?;
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
          build: (pw.Context context) => [
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
                      color: PdfColors.teal800,
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
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    widget.patientName,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold),
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
            _buildPDFSection('Personal Information', [
              'Full Name: ${_safeToString(_patientData!['name'])}',
              'Date of Birth: ${_safeToString(_patientData!['dateOfBirth'])}',
              'Age: ${_safeToString(_patientData!['age'])}',
              'Gender: ${_safeToString(_patientData!['gender'])}',
              'Marital Status: ${_safeToString(_patientData!['maritalStatus'])}',
              'Living Situation: ${_safeToString(_patientData!['livingSituation'])}',
              'Phone: ${_safeToString(_patientData!['phone'])}',
              'Email: ${_safeToString(_patientData!['email'])}',
              'Address: ${_safeToString(_patientData!['address'])}',
              'Blood Group: ${_safeToString(_patientData!['bloodGroup'])}',
              'Emergency Contact Name: ${_safeToString(_patientData!['emergencyContactName'])}',
              'Emergency Contact Relationship: ${_safeToString(_patientData!['emergencyContactRelationship'])}',
              'Emergency Contact Phone: ${_safeToString(_patientData!['emergencyContactPhone'])}',
            ]),
            pw.SizedBox(height: 16),
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
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName =
          'Patient_Report_${widget.patientName}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

      if (forSharing) {
        // Save PDF to temporary directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        return {'filePath': file.path, 'fileName': fileName};
      } else {
        // Trigger download
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fileName,
        );
        return null;
      }
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
      return null;
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
            color: PdfColors.teal800,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile: ${widget.patientName}'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: _patientData != null ? _generatePDF : null,
        //     icon: const Icon(Icons.picture_as_pdf, color: Colors.teal),
        //     tooltip: 'Download PDF Report',
        //   ),
        //   IconButton(
        //     onPressed: _patientData != null ? () => _showExportOptions() : null,
        //     icon: const Icon(Icons.share, color: Colors.teal),
        //     tooltip: 'Share/Export',
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
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
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientHeader(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildQuickStats(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildSection('👤 Personal Information',
                          _buildPersonalInfo(isSmallScreen)),
                      const SizedBox(height: 16),
                      _buildSection('🏥 Health & Lifestyle Information',
                          _buildHealthLifestyleInfo(isSmallScreen)),
                      const SizedBox(height: 16),
                      _buildSection(
                          '🍎 Diet Assessment (Food Frequency Questionnaire)',
                          _buildDietAssessment(isSmallScreen)),
                      const SizedBox(height: 16),
                      _buildSection('💪 Muscle Strength Assessment (SARC-F)',
                          _buildStrengthAssessment(isSmallScreen)),
                      const SizedBox(height: 16),
                      _buildSection('📱 App Usability Assessment (SUS)',
                          _buildUsabilityAssessment(isSmallScreen)),
                      const SizedBox(height: 16),
                      _buildSection('📋 Recent Medical Records',
                          _buildMedicalRecords(isSmallScreen)),
                    ],
                  ),
                ),
      // floatingActionButton: _patientData != null
      //     ? FloatingActionButton(
      //         onPressed: _generatePDF,
      //         backgroundColor: Colors.teal,
      //         foregroundColor: Colors.white,
      //         tooltip: 'Download PDF',
      //         child: const Icon(Icons.picture_as_pdf),
      //       )
      //     : null,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.teal),
              title: const Text('Download as PDF'),
              subtitle: const Text('Save complete patient report'),
              onTap: () {
                Navigator.pop(context);
                _generatePDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.teal),
              title: const Text('Share via WhatsApp'),
              subtitle: const Text('Send report via WhatsApp'),
              onTap: () async {
                Navigator.pop(context);
                final result = await _generatePDF(forSharing: true);
                if (result != null) {
                  final filePath = result['filePath'] as String;
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'Patient Report for ${widget.patientName}',
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to share report'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.teal[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 40 : 50,
              backgroundColor: Colors.teal[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _safeToString(_patientData!['email']),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isSmallScreen ? 12 : 16,
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                          'Age: ${_safeToString(_patientData!['age'])}'),
                      _buildInfoChip(
                        _patientData!['profileCompleted'] == true
                            ? 'Complete'
                            : 'Incomplete',
                        _patientData!['profileCompleted'] == true
                            ? Colors.teal
                            : Colors.orange,
                      ),
                      _buildInfoChip(_safeToString(_patientData!['gender'])),
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

  Widget _buildQuickStats(bool isSmallScreen) {
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
            isSmallScreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
              'Height', _safeToString(height), Icons.height, isSmallScreen),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Weight', _safeToString(weight),
              Icons.monitor_weight, isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: isSmallScreen ? 24 : 32, color: Colors.teal[600]),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(color: Colors.teal, thickness: 0.5),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(bool isSmallScreen) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDetailRow(
            'Full Name', _safeToString(_patientData!['name']), isSmallScreen),
        _buildDetailRow('Date of Birth',
            _safeToString(_patientData!['dateOfBirth']), isSmallScreen),
        _buildDetailRow(
            'Age', _safeToString(_patientData!['age']), isSmallScreen),
        _buildDetailRow(
            'Gender', _safeToString(_patientData!['gender']), isSmallScreen),
        _buildDetailRow('Marital Status',
            _safeToString(_patientData!['maritalStatus']), isSmallScreen),
        _buildDetailRow('Living Situation',
            _safeToString(_patientData!['livingSituation']), isSmallScreen),
        _buildDetailRow('Phone Number', _safeToString(_patientData!['phone']),
            isSmallScreen),
        _buildDetailRow(
            'Email', _safeToString(_patientData!['email']), isSmallScreen),
        _buildDetailRow(
            'Address', _safeToString(_patientData!['address']), isSmallScreen),
        _buildDetailRow('Blood Group',
            _safeToString(_patientData!['bloodGroup']), isSmallScreen),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHealthLifestyleInfo(bool isSmallScreen) {
    final healthLifestyle =
        _patientData!['healthLifestyle'] as Map<String, dynamic>?;
    final medicalHistory =
        _patientData!['medicalHistory'] as Map<String, dynamic>?;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text(
          'Physical Measurements:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
            'Height', _safeToString(healthLifestyle?['height']), isSmallScreen),
        _buildDetailRow(
            'Weight', _safeToString(healthLifestyle?['weight']), isSmallScreen),
        const SizedBox(height: 12),
        Text(
          'Lifestyle Information:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Smoking History',
            _safeToString(healthLifestyle?['smokingHistory']), isSmallScreen),
        _buildDetailRow(
            'Alcohol Consumption',
            _safeToString(healthLifestyle?['alcoholConsumption']),
            isSmallScreen),
        _buildDetailRow(
            'Daily Activity Level',
            _safeToString(healthLifestyle?['dailyActivityLevel']),
            isSmallScreen),
        const SizedBox(height: 12),
        Text(
          'Medical Information:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Medical Conditions',
            _safeToString(medicalHistory?['conditions']), isSmallScreen),
        _buildDetailRow(
            'Current Medications',
            _safeToString(medicalHistory?['currentMedications']),
            isSmallScreen),
        _buildDetailRow('Allergies',
            _safeToString(medicalHistory?['allergies']), isSmallScreen),
        _buildDetailRow('Recent Surgeries',
            _safeToString(medicalHistory?['recentSurgeries']), isSmallScreen),
        if (medicalHistory?['recentSurgeriesSpecify'] != null)
          _buildDetailRow(
              'Surgery Details',
              _safeToString(medicalHistory?['recentSurgeriesSpecify']),
              isSmallScreen),
        _buildDetailRow('Assistive Devices',
            _safeToString(medicalHistory?['assistiveDevices']), isSmallScreen),
        _buildDetailRow(
            'Tuberculosis History',
            _safeToString(medicalHistory?['tuberculosisHistory']),
            isSmallScreen),
        _buildDetailRow(
            'Mental Health Care',
            _safeToString(medicalHistory?['mentalHealthClinicianCare']),
            isSmallScreen),
        _buildDetailRow(
            'Restricted Eating History',
            _safeToString(medicalHistory?['restrictedEatingHistory']),
            isSmallScreen),
      ],
    );
  }

  Widget _buildDietAssessment(bool isSmallScreen) {
    final dietaryHabits =
        _patientData!['dietaryHabits'] as Map<String, dynamic>?;
    if (dietaryHabits == null) {
      return Text(
        'No dietary assessment data available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
            ),
      );
    }

    final questions = {
      'Q1': 'How often do you eat vegetables?',
      'Q2': 'How often do you eat fruit and/or berries?',
      'Q3': 'How often do you eat nuts?',
      'Q4': 'How often do you eat fish or shellfish?',
      'Q5': 'How often do you eat red meat?',
      'Q6': 'How often do you eat white meat?',
      'Q7':
          'How often do you eat buns/cakes, chocolate/sweets, crisps or soda/juice?',
      'Q8': 'How often do you eat breakfast?',
      'Q9b': 'What type(s) of bread do you eat?',
      'Q10': 'How often do you drink/eat milk, sour milk and/or yoghurt?',
      'Q11':
          'What type of milk, sour milk and/or yoghurt do you usually drink/eat?',
      'Q12': 'What kind of spread do you usually use on sandwiches?',
      'Q13': 'What kind of fat do you usually use for cooking at home?',
      'Q14': 'Do you usually add salt to your food?',
    };

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final key = questions.keys.elementAt(index);
        final question = questions[key]!;
        return _buildDetailRow('$key. $question',
            _safeToString(dietaryHabits[key]), isSmallScreen);
      },
    );
  }

  Widget _buildStrengthAssessment(bool isSmallScreen) {
    final muscleStrength =
        _patientData!['muscleStrength'] as Map<String, dynamic>?;
    if (muscleStrength == null) {
      return Text(
        'No muscle strength assessment data available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
            ),
      );
    }

    final questions = {
      'Strength':
          'How much difficulty do you have in lifting or carrying 10 pounds?',
      'Assistance in walking':
          'How much difficulty do you have walking across a room?',
      'Rise from a chair':
          'How much difficulty do you have transferring from a chair or bed?',
      'Climb stairs':
          'How much difficulty do you have climbing a flight of 10 stairs?',
      'Falls': 'How many times have you fallen in the last year?',
    };

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final key = questions.keys.elementAt(index);
        final question = questions[key]!;
        return _buildDetailRow(
            question, _safeToString(muscleStrength[key]), isSmallScreen);
      },
    );
  }

  Widget _buildUsabilityAssessment(bool isSmallScreen) {
    final appUsability =
        _patientData!['applicationUsability'] as Map<String, dynamic>?;
    if (appUsability == null) {
      return Text(
        'No app usability assessment data available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
            ),
      );
    }

    final questions = [
      'I think that I would like to use this system frequently',
      'I found the system unnecessarily complex',
      'I thought the system was easy to use',
      'I think that I would need the support of a technical person to be able to use this system',
      'I found the various functions in this system were well integrated',
      'I thought there was too much inconsistency in this system',
      'I would imagine that most people would learn to use this system very quickly',
      'I found the system very cumbersome to use',
      'I felt very confident using the system',
      'I needed to learn a lot of things before I could get going with this system',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildDetailRow(
            question, _safeToString(appUsability[question]), isSmallScreen);
      },
    );
  }

  Widget _buildMedicalRecords(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Prescriptions:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
        ),
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
              return Text(
                'No prescriptions found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final medications = data['medications'] as List? ?? [];
                final dateStr = data['date'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: Colors.teal[50],
                  child: ListTile(
                    leading:
                        const Icon(Icons.medical_services, color: Colors.teal),
                    title: Text(
                      'Date: $dateStr',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${medications.length} medications prescribed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Recent Diet Plans:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
        ),
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
              return Text(
                'No diet plans found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final meals = data['meals'] as List? ?? [];
                final startDateStr = data['startDate'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: Colors.teal[50],
                  child: ListTile(
                    leading:
                        const Icon(Icons.restaurant_menu, color: Colors.teal),
                    title: Text(
                      'Start Date: $startDateStr',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${meals.length} meals planned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 120 : 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal[800],
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.teal[800],
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
