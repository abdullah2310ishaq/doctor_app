import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ComprehensivePatientDetails extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ComprehensivePatientDetails({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ComprehensivePatientDetails> createState() => _ComprehensivePatientDetailsState();
}

class _ComprehensivePatientDetailsState extends State<ComprehensivePatientDetails> {
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

  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Profile: ${widget.patientName}'),
        backgroundColor: Colors.blue[50],
        actions: [
          IconButton(
            onPressed: () => _showPrintDialog(),
            icon: const Icon(Icons.print),
            tooltip: 'Print/Export',
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
                      // Patient Header with Photo
                      _buildPatientHeader(),
                      const SizedBox(height: 20),
                      
                      // Quick Stats Row
                      _buildQuickStats(),
                      const SizedBox(height: 20),
                      
                      // Personal Information
                      _buildSection('👤 Personal Information', _buildPersonalInfo()),
                      const SizedBox(height: 20),
                      
                      // Medical Information
                      _buildSection('🏥 Medical Information', _buildMedicalInfo()),
                      const SizedBox(height: 20),
                      
                      // Family History
                      _buildSection('👨‍👩‍👧‍👦 Family History', _buildFamilyHistory()),
                      const SizedBox(height: 20),
                      
                      // Lifestyle & Activity
                      _buildSection('🏃‍♂️ Lifestyle & Activity', _buildLifestyleInfo()),
                      const SizedBox(height: 20),
                      
                      // Diet Assessment
                      _buildSection('🍎 Diet Assessment', _buildDietAssessment()),
                      const SizedBox(height: 20),
                      
                      // Muscle Strength Assessment
                      _buildSection('💪 Muscle Strength Assessment', _buildStrengthAssessment()),
                      const SizedBox(height: 20),
                      
                      // App Usability Assessment
                      _buildSection('📱 App Usability Assessment', _buildUsabilityAssessment()),
                      const SizedBox(height: 20),
                      
                      // Emergency Contact
                      _buildSection('🚨 Emergency Contact', _buildEmergencyContact()),
                      const SizedBox(height: 20),
                      
                      // Medical History Timeline
                      _buildSection('📋 Medical History Timeline', _buildMedicalTimeline()),
                      const SizedBox(height: 20),
                      
                      // Recent Prescriptions
                      _buildSection('💊 Recent Prescriptions', _buildRecentPrescriptions()),
                      const SizedBox(height: 20),
                      
                      // Recent Diet Plans
                      _buildSection('🥗 Recent Diet Plans', _buildRecentDietPlans()),
                      const SizedBox(height: 20),
                      
                      // Additional Notes
                      _buildSection('📝 Additional Information', _buildAdditionalInfo()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientHeader() {
    final age = _calculateAge(_patientData!['dateOfBirth']);
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
                        _buildInfoChip('Age: ${age > 0 ? age : 'N/A'}', Colors.blue),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          _patientData!['profileCompleted'] == true ? 'Complete' : 'Incomplete',
                          _patientData!['profileCompleted'] == true ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(_safeToString(_patientData!['gender']), Colors.purple),
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
    return Row(
      children: [
        Expanded(child: _buildStatCard('Blood Group', _safeToString(_patientData!['bloodGroup']), Icons.bloodtype, Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Height', _safeToString(_patientData!['height']), Icons.height, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Weight', _safeToString(_patientData!['weight']), Icons.monitor_weight, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        _buildDetailRow('Full Name', _safeToString(_patientData!['fullName'])),
        _buildDetailRow('Date of Birth', _safeToString(_patientData!['dateOfBirth'])),
        _buildDetailRow('Age', '${_calculateAge(_patientData!['dateOfBirth'])} years'),
        _buildDetailRow('Gender', _safeToString(_patientData!['gender'])),
        _buildDetailRow('Phone Number', _safeToString(_patientData!['phone'])),
        _buildDetailRow('Email', _safeToString(_patientData!['email'])),
        _buildDetailRow('Address', _safeToString(_patientData!['address'])),
        _buildDetailRow('Blood Group', _safeToString(_patientData!['bloodGroup'])),
        _buildDetailRow('Height', _safeToString(_patientData!['height'])),
        _buildDetailRow('Weight', _safeToString(_patientData!['weight'])),
        _buildDetailRow('Marital Status', _safeToString(_patientData!['maritalStatus'])),
        _buildDetailRow('Occupation', _safeToString(_patientData!['occupation'])),
        _buildDetailRow('Education Level', _safeToString(_patientData!['educationLevel'])),
        _buildDetailRow('Nationality', _safeToString(_patientData!['nationality'])),
        _buildDetailRow('Religion', _safeToString(_patientData!['religion'])),
        _buildDetailRow('Language', _safeToString(_patientData!['language'])),
        _buildDetailRow('Insurance Provider', _safeToString(_patientData!['insuranceProvider'])),
        _buildDetailRow('Insurance Number', _safeToString(_patientData!['insuranceNumber'])),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Column(
      children: [
        _buildDetailRow('Medical History', _safeToString(_patientData!['medicalHistory'])),
        _buildDetailRow('Current Medications', _safeToString(_patientData!['currentMedications'])),
        _buildDetailRow('Allergies', _safeToString(_patientData!['allergies'])),
        _buildDetailRow('Chronic Conditions', _safeToString(_patientData!['chronicConditions'])),
        _buildDetailRow('Previous Surgeries', _safeToString(_patientData!['previousSurgeries'])),
        _buildDetailRow('Immunization History', _safeToString(_patientData!['immunizationHistory'])),
        _buildDetailRow('Mental Health History', _safeToString(_patientData!['mentalHealthHistory'])),
        _buildDetailRow('Reproductive Health', _safeToString(_patientData!['reproductiveHealth'])),
        _buildDetailRow('Smoking Status', _safeToString(_patientData!['smokingStatus'])),
        _buildDetailRow('Alcohol Consumption', _safeToString(_patientData!['alcoholConsumption'])),
        _buildDetailRow('Drug Use History', _safeToString(_patientData!['drugUseHistory'])),
        _buildDetailRow('Blood Pressure', _safeToString(_patientData!['bloodPressure'])),
        _buildDetailRow('Heart Rate', _safeToString(_patientData!['heartRate'])),
        _buildDetailRow('Cholesterol Level', _safeToString(_patientData!['cholesterolLevel'])),
        _buildDetailRow('Blood Sugar Level', _safeToString(_patientData!['bloodSugarLevel'])),
        _buildDetailRow('Vision Problems', _safeToString(_patientData!['visionProblems'])),
        _buildDetailRow('Hearing Problems', _safeToString(_patientData!['hearingProblems'])),
      ],
    );
  }

  Widget _buildFamilyHistory() {
    return Column(
      children: [
        _buildDetailRow('Family Medical History', _safeToString(_patientData!['familyMedicalHistory'])),
        _buildDetailRow('Genetic Conditions', _safeToString(_patientData!['geneticConditions'])),
        _buildDetailRow('Father\'s Health', _safeToString(_patientData!['fatherHealth'])),
        _buildDetailRow('Mother\'s Health', _safeToString(_patientData!['motherHealth'])),
        _buildDetailRow('Siblings Health', _safeToString(_patientData!['siblingsHealth'])),
        _buildDetailRow('Grandparents Health', _safeToString(_patientData!['grandparentsHealth'])),
        _buildDetailRow('Family Cancer History', _safeToString(_patientData!['familyCancerHistory'])),
        _buildDetailRow('Family Heart Disease', _safeToString(_patientData!['familyHeartDisease'])),
        _buildDetailRow('Family Diabetes', _safeToString(_patientData!['familyDiabetes'])),
        _buildDetailRow('Family Mental Health', _safeToString(_patientData!['familyMentalHealth'])),
      ],
    );
  }

  Widget _buildLifestyleInfo() {
    return Column(
      children: [
        _buildDetailRow('Physical Activity Level', _safeToString(_patientData!['physicalActivityLevel'])),
        _buildDetailRow('Exercise Frequency', _safeToString(_patientData!['exerciseFrequency'])),
        _buildDetailRow('Exercise Type', _safeToString(_patientData!['exerciseType'])),
        _buildDetailRow('Sleep Hours', _safeToString(_patientData!['sleepHours'])),
        _buildDetailRow('Sleep Quality', _safeToString(_patientData!['sleepQuality'])),
        _buildDetailRow('Stress Level', _safeToString(_patientData!['stressLevel'])),
        _buildDetailRow('Work Environment', _safeToString(_patientData!['workEnvironment'])),
        _buildDetailRow('Social Support', _safeToString(_patientData!['socialSupport'])),
        _buildDetailRow('Hobbies', _safeToString(_patientData!['hobbies'])),
        _buildDetailRow('Travel History', _safeToString(_patientData!['travelHistory'])),
        _buildDetailRow('Diet Preferences', _safeToString(_patientData!['dietPreferences'])),
        _buildDetailRow('Smoking History', _safeToString(_patientData!['smokingHistory'])),
        _buildDetailRow('Alcohol History', _safeToString(_patientData!['alcoholHistory'])),
        _buildDetailRow('Substance Use', _safeToString(_patientData!['substanceUse'])),
        _buildDetailRow('Environmental Exposures', _safeToString(_patientData!['environmentalExposures'])),
      ],
    );
  }

  Widget _buildDietAssessment() {
    final dietaryHabits = _patientData!['dietaryHabits'] as Map<String, dynamic>?;
    if (dietaryHabits == null) {
      return Column(
        children: [
          _buildDetailRow('Diet Type', _safeToString(_patientData!['dietType'])),
          _buildDetailRow('Meal Frequency', _safeToString(_patientData!['mealFrequency'])),
          _buildDetailRow('Water Intake', _safeToString(_patientData!['waterIntake'])),
          _buildDetailRow('Food Allergies', _safeToString(_patientData!['foodAllergies'])),
          const Text('No detailed dietary assessment available'),
        ],
      );
    }

    return Column(
      children: [
        _buildDetailRow('Overall Diet Quality', _safeToString(dietaryHabits['overallDietQuality'])),
        _buildDetailRow('Meal Frequency', _safeToString(dietaryHabits['mealFrequency'])),
        _buildDetailRow('Breakfast Frequency', _safeToString(dietaryHabits['breakfastFrequency'])),
        _buildDetailRow('Fruit Intake', _safeToString(dietaryHabits['fruitIntake'])),
        _buildDetailRow('Vegetable Intake', _safeToString(dietaryHabits['vegetableIntake'])),
        _buildDetailRow('Whole Grain Intake', _safeToString(dietaryHabits['wholeGrainIntake'])),
        _buildDetailRow('Protein Sources', _safeToString(dietaryHabits['proteinSources'])),
        _buildDetailRow('Dairy Intake', _safeToString(dietaryHabits['dairyIntake'])),
        _buildDetailRow('Water Intake', _safeToString(dietaryHabits['waterIntake'])),
        _buildDetailRow('Sugary Drinks', _safeToString(dietaryHabits['sugaryDrinks'])),
        _buildDetailRow('Fast Food Frequency', _safeToString(dietaryHabits['fastFoodFrequency'])),
        _buildDetailRow('Cooking Frequency', _safeToString(dietaryHabits['cookingFrequency'])),
        _buildDetailRow('Snacking Habits', _safeToString(dietaryHabits['snackingHabits'])),
        _buildDetailRow('Portion Sizes', _safeToString(dietaryHabits['portionSizes'])),
        _buildDetailRow('Eating Speed', _safeToString(dietaryHabits['eatingSpeed'])),
        _buildDetailRow('Mindful Eating', _safeToString(dietaryHabits['mindfulEating'])),
        _buildDetailRow('Food Cravings', _safeToString(dietaryHabits['foodCravings'])),
        _buildDetailRow('Dietary Restrictions', _safeToString(dietaryHabits['dietaryRestrictions'])),
        _buildDetailRow('Supplement Use', _safeToString(dietaryHabits['supplementUse'])),
        _buildDetailRow('Meal Planning', _safeToString(dietaryHabits['mealPlanning'])),
      ],
    );
  }

  Widget _buildStrengthAssessment() {
    final muscleStrength = _patientData!['muscleStrength'] as Map<String, dynamic>?;
    if (muscleStrength == null) {
      return Column(
        children: [
          _buildDetailRow('Exercise Level', _safeToString(_patientData!['exerciseLevel'])),
          _buildDetailRow('Strength Training', _safeToString(_patientData!['strengthTraining'])),
          const Text('No detailed strength assessment available'),
        ],
      );
    }

    return Column(
      children: [
        _buildDetailRow('Overall Strength Level', _safeToString(muscleStrength['overallStrengthLevel'])),
        _buildDetailRow('Upper Body Strength', _safeToString(muscleStrength['upperBodyStrength'])),
        _buildDetailRow('Lower Body Strength', _safeToString(muscleStrength['lowerBodyStrength'])),
        _buildDetailRow('Core Strength', _safeToString(muscleStrength['coreStrength'])),
        _buildDetailRow('Grip Strength', _safeToString(muscleStrength['gripStrength'])),
        _buildDetailRow('Flexibility', _safeToString(muscleStrength['flexibility'])),
        _buildDetailRow('Balance', _safeToString(muscleStrength['balance'])),
        _buildDetailRow('Endurance', _safeToString(muscleStrength['endurance'])),
        _buildDetailRow('Exercise Frequency', _safeToString(muscleStrength['exerciseFrequency'])),
        _buildDetailRow('Exercise Duration', _safeToString(muscleStrength['exerciseDuration'])),
        _buildDetailRow('Exercise Types', _safeToString(muscleStrength['exerciseTypes'])),
        _buildDetailRow('Strength Training Frequency', _safeToString(muscleStrength['strengthTrainingFrequency'])),
        _buildDetailRow('Cardio Frequency', _safeToString(muscleStrength['cardioFrequency'])),
        _buildDetailRow('Sports Participation', _safeToString(muscleStrength['sportsParticipation'])),
        _buildDetailRow('Physical Limitations', _safeToString(muscleStrength['physicalLimitations'])),
        _buildDetailRow('Injury History', _safeToString(muscleStrength['injuryHistory'])),
        _buildDetailRow('Recovery Time', _safeToString(muscleStrength['recoveryTime'])),
        _buildDetailRow('Exercise Goals', _safeToString(muscleStrength['exerciseGoals'])),
        _buildDetailRow('Motivation Level', _safeToString(muscleStrength['motivationLevel'])),
        _buildDetailRow('Equipment Access', _safeToString(muscleStrength['equipmentAccess'])),
      ],
    );
  }

  Widget _buildUsabilityAssessment() {
    final appUsability = _patientData!['applicationUsability'] as Map<String, dynamic>?;
    if (appUsability == null) {
      return const Text('No app usability assessment available');
    }

    return Column(
      children: [
        _buildDetailRow('Overall App Rating', _safeToString(appUsability['overallAppRating'])),
        _buildDetailRow('Ease of Use', _safeToString(appUsability['easeOfUse'])),
        _buildDetailRow('Navigation Clarity', _safeToString(appUsability['navigationClarity'])),
        _buildDetailRow('Feature Usefulness', _safeToString(appUsability['featureUsefulness'])),
        _buildDetailRow('App Speed', _safeToString(appUsability['appSpeed'])),
        _buildDetailRow('Visual Design', _safeToString(appUsability['visualDesign'])),
        _buildDetailRow('Information Clarity', _safeToString(appUsability['informationClarity'])),
        _buildDetailRow('Error Frequency', _safeToString(appUsability['errorFrequency'])),
        _buildDetailRow('Help Accessibility', _safeToString(appUsability['helpAccessibility'])),
        _buildDetailRow('Customization Options', _safeToString(appUsability['customizationOptions'])),
        _buildDetailRow('Notification Usefulness', _safeToString(appUsability['notificationUsefulness'])),
        _buildDetailRow('Data Security Confidence', _safeToString(appUsability['dataSecurityConfidence'])),
        _buildDetailRow('Recommendation Likelihood', _safeToString(appUsability['recommendationLikelihood'])),
        _buildDetailRow('Most Useful Feature', _safeToString(appUsability['mostUsefulFeature'])),
        _buildDetailRow('Least Useful Feature', _safeToString(appUsability['leastUsefulFeature'])),
        _buildDetailRow('Missing Features', _safeToString(appUsability['missingFeatures'])),
        _buildDetailRow('Usage Frequency', _safeToString(appUsability['usageFrequency'])),
        _buildDetailRow('Session Duration', _safeToString(appUsability['sessionDuration'])),
        _buildDetailRow('Technical Issues', _safeToString(appUsability['technicalIssues'])),
        _buildDetailRow('Additional Comments', _safeToString(appUsability['additionalComments'])),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return Column(
      children: [
        _buildDetailRow('Contact Name', _safeToString(_patientData!['emergencyContactName'])),
        _buildDetailRow('Relationship', _safeToString(_patientData!['emergencyContactRelationship'])),
        _buildDetailRow('Phone Number', _safeToString(_patientData!['emergencyContactPhone'])),
        _buildDetailRow('Email', _safeToString(_patientData!['emergencyContactEmail'])),
        _buildDetailRow('Address', _safeToString(_patientData!['emergencyContactAddress'])),
      ],
    );
  }

  Widget _buildMedicalTimeline() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('appointmentTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No appointment history available');
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.blue[50],
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(data['appointmentType'] ?? 'General Appointment'),
                subtitle: Text(data['appointmentTime'] ?? 'No time set'),
                trailing: data['status'] != null 
                    ? Chip(
                        label: Text(data['status']),
                        backgroundColor: data['status'] == 'completed' 
                            ? Colors.green[100] 
                            : Colors.orange[100],
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentPrescriptions() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('createdAt', descending: true)
          .limit(10)
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
            
            DateTime? date;
            try {
              date = DateTime.parse(dateStr);
            } catch (e) {
              date = null;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.green[50],
              child: ExpansionTile(
                leading: const Icon(Icons.medical_services, color: Colors.green),
                title: Text(
                  date != null 
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Date not available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${medications.length} medications'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...medications.map((med) {
                          if (med is Map<String, dynamic>) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med['name'] ?? 'Unknown medication',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('Dosage: ${med['dosage'] ?? 'N/A'}'),
                                        Text('Frequency: ${med['frequency'] ?? 'N/A'}'),
                                        Text('Duration: ${med['duration'] ?? 'N/A'}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Text('• $med');
                        }).toList(),
                        if (data['instructions'] != null && data['instructions'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Instructions: ${data['instructions']}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentDietPlans() {
    return StreamBuilder<QuerySnapshot>(
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
            
            DateTime? startDate;
            try {
              startDate = DateTime.parse(startDateStr);
            } catch (e) {
              startDate = null;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.orange[50],
              child: ExpansionTile(
                leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
                title: Text(
                  startDate != null 
                      ? DateFormat('MMM dd, yyyy').format(startDate)
                      : 'Date not available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${meals.length} meals planned'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...meals.map((meal) {
                          if (meal is Map<String, dynamic>) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${meal['type'] ?? 'Meal'}: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(meal['name'] ?? meal['description'] ?? 'N/A'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Text('• $meal');
                        }).toList(),
                        if (data['nutritionGuidelines'] != null && data['nutritionGuidelines'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Guidelines: ${data['nutritionGuidelines']}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        _buildDetailRow('Profile Version', _safeToString(_patientData!['profileVersion'])),
        _buildDetailRow('Registration Date', _safeToString(_patientData!['createdAt'])),
        _buildDetailRow('Last Updated', _safeToString(_patientData!['updatedAt'])),
        _buildDetailRow('Health Goals', _safeToString(_patientData!['healthGoal'])),
        _buildDetailRow('Special Notes', _safeToString(_patientData!['specialNotes'])),
        _buildDetailRow('Preferred Language', _safeToString(_patientData!['preferredLanguage'])),
        _buildDetailRow('Insurance Information', _safeToString(_patientData!['insuranceInfo'])),
        _buildDetailRow('Preferred Contact Method', _safeToString(_patientData!['preferredContactMethod'])),
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
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Patient Data'),
        content: const Text('This feature will be available soon for exporting patient data to PDF or printing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
