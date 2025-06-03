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
  State<PatientDietStrengthDetails> createState() =>
      _PatientDietStrengthDetailsState();
}

class _PatientDietStrengthDetailsState
    extends State<PatientDietStrengthDetails> {
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
      final doc =
          await _firestore.collection('patients').doc(widget.patientId).get();
      setState(() {
        _patientData = doc.exists ? doc.data() : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName} - Assessment'),
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
                      _buildAssessmentStatus(isSmallScreen),
                      if (_patientData!['dietaryHabits'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDietaryHabitsSection(isSmallScreen),
                      ],
                      if (_patientData!['muscleStrength'] != null) ...[
                        const SizedBox(height: 16),
                        _buildMuscleStrengthSection(isSmallScreen),
                      ],
                      if (_patientData!['applicationUsability'] != null) ...[
                        const SizedBox(height: 16),
                        _buildApplicationUsabilitySection(isSmallScreen),
                      ],
                      if (_patientData!['dietType'] != null ||
                          _patientData!['exerciseLevel'] != null ||
                          _patientData!['healthGoal'] != null) ...[
                        const SizedBox(height: 16),
                        _buildSimpleDietFitnessInfo(isSmallScreen),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientHeader(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 24 : 30,
              backgroundColor: Colors.teal[100],
              child: Text(
                widget.patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
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
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diet & Strength Assessment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentStatus(bool isSmallScreen) {
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
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  hasDetailedAssessment ? Icons.check_circle : Icons.cancel,
                  color: hasDetailedAssessment ? Colors.teal : Colors.red[600],
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detailed Assessment: ${hasDetailedAssessment ? "Completed" : "Not Completed"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: hasDetailedAssessment
                              ? Colors.teal
                              : Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryHabitsSection(bool isSmallScreen) {
    final dietaryHabits =
        _patientData!['dietaryHabits'] as Map<String, dynamic>;
    final Map<String, String> questionTexts = {
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
                Icon(Icons.restaurant,
                    color: Colors.teal[600], size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dietary Habits (Food Frequency Questionnaire)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dietaryHabits.length,
              itemBuilder: (context, index) {
                final entry = dietaryHabits.entries.elementAt(index);
                final questionText = questionTexts[entry.key] ?? entry.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}. $questionText',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Answer: ${entry.value ?? "Not answered"}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleStrengthSection(bool isSmallScreen) {
    final muscleStrength =
        _patientData!['muscleStrength'] as Map<String, dynamic>;

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
                Icon(Icons.fitness_center,
                    color: Colors.teal[600], size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Muscle Strength (SARC-F Questionnaire)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: muscleStrength.length,
              itemBuilder: (context, index) {
                final entry = muscleStrength.entries.elementAt(index);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulty in: ${entry.key}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Answer: ${entry.value ?? "Not answered"}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationUsabilitySection(bool isSmallScreen) {
    final appUsability =
        _patientData!['applicationUsability'] as Map<String, dynamic>;

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
                Icon(Icons.phone_android,
                    color: Colors.teal[600], size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application Usability (System Usability Scale)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appUsability.length,
              itemBuilder: (context, index) {
                final entry = appUsability.entries.elementAt(index);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rating: ${entry.value ?? "Not rated"}/5',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDietFitnessInfo(bool isSmallScreen) {
    final dietType = _patientData!['dietType'];
    final exerciseLevel = _patientData!['exerciseLevel'];
    final healthGoal = _patientData!['healthGoal'];

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
                Icon(Icons.info,
                    color: Colors.teal[600], size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Basic Diet & Fitness Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dietType != null)
              _buildInfoRow('Diet Type', dietType, isSmallScreen),
            if (exerciseLevel != null)
              _buildInfoRow('Exercise Level', exerciseLevel, isSmallScreen),
            if (healthGoal != null)
              _buildInfoRow('Health Goal', healthGoal, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 100 : 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
