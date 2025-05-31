import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDietStrengthDetails extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDietStrengthDetails({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDietStrengthDetails> createState() => _PatientDietStrengthDetailsState();
}

class _PatientDietStrengthDetailsState extends State<PatientDietStrengthDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
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
        title: Text('${widget.patientName} - Diet & Strength Assessment'),
        backgroundColor: Colors.green[50],
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
                      
                      // Assessment Status
                      _buildAssessmentStatus(),
                      const SizedBox(height: 24),
                      
                      // Dietary Habits Section
                      if (_patientData!['dietaryHabits'] != null)
                        _buildDietaryHabitsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Muscle Strength Section
                      if (_patientData!['muscleStrength'] != null)
                        _buildMuscleStrengthSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Application Usability Section
                      if (_patientData!['applicationUsability'] != null)
                        _buildApplicationUsabilitySection(),
                      
                      const SizedBox(height: 24),
                      
                      // Simple Diet & Fitness Info (if available)
                      _buildSimpleDietFitnessInfo(),
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
              radius: 30,
              backgroundColor: Colors.green[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
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
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diet & Strength Assessment Report',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryHabitsSection() {
    final dietaryHabits = _patientData!['dietaryHabits'] as Map<String, dynamic>;
    
    final Map<String, String> questionTexts = {
      'Q1': 'How often do you eat vegetables?',
      'Q2': 'How often do you eat fruit and/or berries?',
      'Q3': 'How often do you eat nuts?',
      'Q4': 'How often do you eat fish or shellfish?',
      'Q5': 'How often do you eat red meat?',
      'Q6': 'How often do you eat white meat?',
      'Q7': 'How often do you eat buns/cakes, chocolate/sweets, crisps or soda/juice?',
      'Q8': 'How often do you eat breakfast?',
      'Q9b': 'What type(s) of bread do you eat?',
      'Q10': 'How often do you drink/eat milk, sour milk and/or yoghurt?',
      'Q11': 'What type of milk, sour milk and/or yoghurt do you usually drink/eat?',
      'Q12': 'What kind of spread do you usually use on sandwiches?',
      'Q13': 'What kind of fat do you usually use for cooking at home?',
      'Q14': 'Do you usually add salt to your food?',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Dietary Habits (Food Frequency Questionnaire)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dietaryHabits.entries.map((entry) {
              final questionText = questionTexts[entry.key] ?? entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}. $questionText',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Answer: ${entry.value ?? "Not answered"}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleStrengthSection() {
    final muscleStrength = _patientData!['muscleStrength'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Muscle Strength (SARC-F Questionnaire)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...muscleStrength.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How much difficulty do you have in: ${entry.key}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Answer: ${entry.value ?? "Not answered"}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationUsabilitySection() {
    final appUsability = _patientData!['applicationUsability'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Application Usability (System Usability Scale)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...appUsability.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rating: ${entry.value ?? "Not rated"}/5',
                      style: TextStyle(
                        color: Colors.purple[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDietFitnessInfo() {
    final dietType = _patientData!['dietType'];
    final exerciseLevel = _patientData!['exerciseLevel'];
    final healthGoal = _patientData!['healthGoal'];

    if (dietType == null && exerciseLevel == null && healthGoal == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Basic Diet & Fitness Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dietType != null)
              _buildInfoRow('Diet Type', dietType, Colors.orange),
            if (exerciseLevel != null)
              _buildInfoRow('Exercise Level', exerciseLevel, Colors.orange),
            if (healthGoal != null)
              _buildInfoRow('Health Goal', healthGoal, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color?.withOpacity(0.3) ?? Colors.grey),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
