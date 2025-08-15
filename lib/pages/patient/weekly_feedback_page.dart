import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WeeklyFeedbackPage extends StatefulWidget {
  const WeeklyFeedbackPage({super.key});

  @override
  State<WeeklyFeedbackPage> createState() => _WeeklyFeedbackPageState();
}

class _WeeklyFeedbackPageState extends State<WeeklyFeedbackPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _hasSubmittedThisPeriod = false;
  DateTime _periodStart = DateTime.now();

  // REMOVED: Health ratings questionnaire (as requested)
  // Only keeping _overallHealthRating for backward compatibility in notifications
  int _overallHealthRating = 5;

  // GODIN EXERCISE QUESTIONNAIRE
  int _strenuousExercise = 0; // times per week (×9)
  int _moderateExercise = 0; // times per week (×5)
  int _lightExercise = 0; // times per week (×3)

  // COMPREHENSIVE FOOD FREQUENCY QUESTIONNAIRE (10 questions)
  String _vegetableFreq = 'A few times a week';
  String _fruitFreq = 'A few times a week';
  String _fishFreq = 'A few times a week';
  String _breakfastFreq = 'Everyday';

  List<String> _selectedSymptoms = [];
  List<String> _selectedSideEffects = [];
  String _symptomsNotes = '';
  String _concerns = '';
  String _improvements = '';

// COMPLETE FOOD FREQUENCY (10 questions)
  String _nutsFreq = 'A few times a week';
  String _redMeatFreq = 'Once or twice a week';
  String _whiteMeatFreq = 'Once or twice a week';
  String _sweetsFreq = 'A few times a week';
  String _breadType = 'White bread';
  String _dairyFreq = 'Once a day or more often';

  // SARC-F QUESTIONNAIRE (5 questions)
  String _liftingDifficulty = 'None';
  String _walkingDifficulty = 'None';
  String _chairDifficulty = 'None';
  String _stairsDifficulty = 'None';
  String _fallsFrequency = 'None';

  // SUS QUESTIONNAIRE (10 questions, 1-5 scale)
  int _susFrequentUse = 3;
  int _susComplexity = 3;
  int _susEaseOfUse = 3;
  int _susTechnicalSupport = 3;
  int _susIntegration = 3;
  int _susInconsistency = 3;
  int _susLearnQuickly = 3;
  int _susCumbersome = 3;
  int _susConfident = 3;
  int _susLearnFirst = 3;

  final List<String> _symptomOptions = [
    'None',
    'Headache',
    'Nausea',
    'Dizziness',
    'Fatigue',
    'Chest pain',
    'Other'
  ];

  final List<String> _sideEffectOptions = [
    'None',
    'Drowsiness',
    'Dry mouth',
    'Stomach upset',
    'Skin rash',
    'Other'
  ];

  final List<String> _frequencyOptions = [
    'Once a day or more often',
    'A few times a week',
    'Once a week or less often'
  ];

  final List<String> _breakfastOptions = ['Everyday', 'Not Everyday'];

  final List<String> _difficultyOptions = ['None', 'Some', 'A lot or unable'];

  final List<String> _fallsOptions = [
    'None',
    'Less than 3 falls',
    '4 or more falls'
  ];

  @override
  void initState() {
    super.initState();
    _periodStart = _getBimonthlyPeriodStart(DateTime.now());
    _checkBimonthlySubmission();
  }

  DateTime _getBimonthlyPeriodStart(DateTime date) {
    // Calculate start of current bimonthly period
    // Even months: Jan-Feb, Mar-Apr, May-Jun, Jul-Aug, Sep-Oct, Nov-Dec
    int month = date.month;
    int periodMonth = month % 2 == 1 ? month : month - 1; // Start at odd month
    return DateTime(date.year, periodMonth, 1);
  }

  // Calculate Godin Score: (Strenuous×9) + (Moderate×5) + (Light×3)
  int _calculateGodinScore() {
    return (9 * _strenuousExercise) +
        (5 * _moderateExercise) +
        (3 * _lightExercise);
  }

  // Calculate SARC-F Score: 0-10 (higher = more sarcopenia risk)
  int _calculateSarcfScore() {
    int score = 0;
    score += _difficultyOptions.indexOf(_liftingDifficulty);
    score += _difficultyOptions.indexOf(_walkingDifficulty);
    score += _difficultyOptions.indexOf(_chairDifficulty);
    score += _difficultyOptions.indexOf(_stairsDifficulty);
    score += _fallsOptions.indexOf(_fallsFrequency);
    return score;
  }

  // Calculate SUS Score: 0-100 (industry standard usability)
  double _calculateSusScore() {
    int score = 0;
    score += (_susFrequentUse - 1); // Q1 (odd)
    score += (5 - _susComplexity); // Q2 (even)
    score += (_susEaseOfUse - 1); // Q3 (odd)
    score += (5 - _susTechnicalSupport); // Q4 (even)
    score += (_susIntegration - 1); // Q5 (odd)
    score += (5 - _susInconsistency); // Q6 (even)
    score += (_susLearnQuickly - 1); // Q7 (odd)
    score += (5 - _susCumbersome); // Q8 (even)
    score += (_susConfident - 1); // Q9 (odd)
    score += (5 - _susLearnFirst); // Q10 (even)
    return score * 2.5; // Convert to 0-100 scale
  }

  Future<void> _checkBimonthlySubmission() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('bimonthly_feedback')
          .where('patientId', isEqualTo: user.uid)
          .where('periodStart', isEqualTo: _periodStart.toIso8601String())
          .limit(1)
          .get();

      setState(() {
        _hasSubmittedThisPeriod = snapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking bimonthly submission: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Get doctor ID
    String? doctorId;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      doctorId = userDoc.data()?['assignedDoctorId'];
      print('Patient ${user.uid} assigned to doctor: $doctorId');

      // If no assigned doctor, try to get from patients collection
      if (doctorId == null) {
        final patientDoc =
            await _firestore.collection('patients').doc(user.uid).get();
        doctorId = patientDoc.data()?['assignedDoctorId'];
        print('Found doctor ID from patients collection: $doctorId');
      }
    } catch (e) {
      print('Could not get doctor ID: $e');
    }

    final godinScore = _calculateGodinScore();
    final sarcfScore = _calculateSarcfScore();
    final susScore = _calculateSusScore();

    final feedbackData = {
      'patientId': user.uid,
      'doctorId': doctorId,
      'periodStart': _periodStart.toIso8601String(),
      'periodEnd': DateTime(_periodStart.year, _periodStart.month + 2, 1)
          .subtract(Duration(days: 1))
          .toIso8601String(),
      'submittedAt': DateTime.now().toIso8601String(),

      // REMOVED: Health ratings section (as requested)

      // GODIN EXERCISE QUESTIONNAIRE
      'strenuousExercise': _strenuousExercise,
      'moderateExercise': _moderateExercise,
      'lightExercise': _lightExercise,
      'godinScore': godinScore,

      // COMPLETE FOOD FREQUENCY QUESTIONNAIRE (10 questions)
      'vegetableFreq': _vegetableFreq,
      'fruitFreq': _fruitFreq,
      'nutsFreq': _nutsFreq,
      'fishFreq': _fishFreq,
      'redMeatFreq': _redMeatFreq,
      'whiteMeatFreq': _whiteMeatFreq,
      'sweetsFreq': _sweetsFreq,
      'breakfastFreq': _breakfastFreq,
      'breadType': _breadType,
      'dairyFreq': _dairyFreq,

      // SARC-F MUSCLE STRENGTH QUESTIONNAIRE
      'liftingDifficulty': _liftingDifficulty,
      'walkingDifficulty': _walkingDifficulty,
      'chairDifficulty': _chairDifficulty,
      'stairsDifficulty': _stairsDifficulty,
      'fallsFrequency': _fallsFrequency,
      'sarcfScore': sarcfScore,

      // SYSTEM USABILITY SCALE (SUS)
      'susFrequentUse': _susFrequentUse,
      'susComplexity': _susComplexity,
      'susEaseOfUse': _susEaseOfUse,
      'susTechnicalSupport': _susTechnicalSupport,
      'susIntegration': _susIntegration,
      'susInconsistency': _susInconsistency,
      'susLearnQuickly': _susLearnQuickly,
      'susCumbersome': _susCumbersome,
      'susConfident': _susConfident,
      'susLearnFirst': _susLearnFirst,
      'susScore': susScore,

      // Symptoms and side effects
      'symptoms': _selectedSymptoms,
      'sideEffects': _selectedSideEffects,
      'symptomsNotes': _symptomsNotes.isEmpty ? null : _symptomsNotes,
      'concerns': _concerns.isEmpty ? null : _concerns,
      'improvements': _improvements.isEmpty ? null : _improvements,

      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('bimonthly_feedback').add(feedbackData);

      // Create notification to doctor
      if (doctorId != null) {
        await _firestore.collection('notifications').add({
          'userId': doctorId,
          'title': '📋 Bimonthly Patient Feedback',
          'message':
              'Patient submitted bimonthly feedback. Godin Score: $godinScore, SARC-F Score: $sarcfScore, SUS Score: $susScore',
          'type': 'weekly_feedback',
          'relatedId': user.uid,
          'patientId': user.uid,
          'periodStart': _periodStart.toIso8601String(),
          'overallRating': _overallHealthRating,
          'godinScore': godinScore,
          'sarcfScore': sarcfScore,
          'susScore': susScore,
          'hasSymptoms': _selectedSymptoms.isNotEmpty &&
              !_selectedSymptoms.contains('None'),
          'hasConcerns': _concerns.isNotEmpty,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Remove persistent reminder notification
      final reminders = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'weekly_feedback_reminder')
          .where('periodStart', isEqualTo: _periodStart.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in reminders.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _hasSubmittedThisPeriod = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Bimonthly feedback submitted! Godin Score: $godinScore'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodEnd = DateTime(_periodStart.year, _periodStart.month + 2, 1)
        .subtract(Duration(days: 1));
    final periodRange =
        '${DateFormat('MMM dd').format(_periodStart)} - ${DateFormat('MMM dd, yyyy').format(periodEnd)}';

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Bimonthly Health Feedback',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _hasSubmittedThisPeriod
          ? _buildAlreadySubmittedWidget(periodRange)
          : _buildFeedbackForm(periodRange),
    );
  }

  Widget _buildAlreadySubmittedWidget(String periodRange) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green[600]),
            SizedBox(height: 24),
            Text(
              'Feedback Submitted!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You have already submitted your feedback for the period of $periodRange.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Thank you! Your doctor has been notified with your Godin Exercise Score, SARC-F, and SUS scores.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Back to Dashboard',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(String periodRange) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(periodRange),
            SizedBox(height: 20),

            // Health ratings section removed as requested

            // NEW: Godin Exercise Questionnaire
            _buildGodinExerciseSection(),
            SizedBox(height: 20),

            // NEW: Food Frequency (simplified)
            _buildFoodFrequencySection(),
            SizedBox(height: 20),

            // NEW: SARC-F Muscle Strength Questionnaire
            _buildSarcfSection(),
            SizedBox(height: 20),

            // NEW: SUS Usability Questionnaire
            _buildSusSection(),
            SizedBox(height: 20),

            // Symptoms section
            _buildSymptomsSection(),
            SizedBox(height: 20),

            // Concerns and improvements
            _buildConcernsSection(),
            SizedBox(height: 32),

            // Submit button with score display
            _buildSubmitButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String periodRange) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.feedback, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Bimonthly Health Check',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('Period: $periodRange',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 8),
              Text(
                'Professional health questionnaires + bimonthly check-in',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGodinExerciseSection() {
    final godinScore = _calculateGodinScore();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.green[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'Godin Leisure-Time Exercise',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'How many times per week do you exercise for 15+ minutes?',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildExerciseSlider('🏃‍♂️ Strenuous (×9)',
                'Running, swimming, hockey', _strenuousExercise, (value) {
              setState(() => _strenuousExercise = value);
            }),
            _buildExerciseSlider('🚶‍♂️ Moderate (×5)',
                'Fast walking, tennis, cycling', _moderateExercise, (value) {
              setState(() => _moderateExercise = value);
            }),
            _buildExerciseSlider(
                '🧘‍♀️ Light (×3)', 'Yoga, golf, easy walking', _lightExercise,
                (value) {
              setState(() => _lightExercise = value);
            }),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Godin Score:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$godinScore',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSlider(
      String title, String examples, int value, Function(int) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(examples,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getExerciseColor(value),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value/week',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            activeColor: _getExerciseColor(value),
            onChanged: (val) => onChanged(val.round()),
          ),
        ],
      ),
    );
  }

  Color _getExerciseColor(int value) {
    if (value == 0) return Colors.grey[400]!;
    if (value <= 2) return Colors.orange[600]!;
    if (value <= 4) return Colors.yellow[700]!;
    return Colors.green[600]!;
  }

  Widget _buildFoodFrequencySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'Food Frequency (Key Items)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700]),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildFoodDropdown('🥬 Vegetables', _vegetableFreq, (value) {
              setState(() => _vegetableFreq = value!);
            }),
            _buildFoodDropdown('🍎 Fruits', _fruitFreq, (value) {
              setState(() => _fruitFreq = value!);
            }),
            _buildFoodDropdown('🐟 Fish', _fishFreq, (value) {
              setState(() => _fishFreq = value!);
            }),
            _buildBreakfastDropdown('🍳 Breakfast', _breakfastFreq, (value) {
              setState(() => _breakfastFreq = value!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodDropdown(
      String label, String value, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: _frequencyOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakfastDropdown(
      String label, String value, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: _breakfastOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Health ratings section removed as requested

  // Rating slider methods removed as health ratings section was removed

  Widget _buildSarcfSection() {
    final sarcfScore = _calculateSarcfScore();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.purple[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'SARC-F Muscle Strength',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'How difficult is it for you to perform these activities?',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildDifficultyDropdown('Lifting', _liftingDifficulty, (value) {
              setState(() => _liftingDifficulty = value!);
            }),
            _buildDifficultyDropdown('Walking', _walkingDifficulty, (value) {
              setState(() => _walkingDifficulty = value!);
            }),
            _buildDifficultyDropdown('Sitting', _chairDifficulty, (value) {
              setState(() => _chairDifficulty = value!);
            }),
            _buildDifficultyDropdown('Stairs', _stairsDifficulty, (value) {
              setState(() => _stairsDifficulty = value!);
            }),
            _buildFallsDropdown('Falls', _fallsFrequency, (value) {
              setState(() => _fallsFrequency = value!);
            }),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your SARC-F Score:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$sarcfScore',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDropdown(
      String label, String value, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: _difficultyOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallsDropdown(
      String label, String value, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: _fallsOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSusSection() {
    final susScore = _calculateSusScore();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.teal[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'System Usability Scale (SUS)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'How easy is it to use this system?',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildSusQuestion(
                'How often do you use this system?', _susFrequentUse, (value) {
              setState(() => _susFrequentUse = value!);
            }),
            _buildSusQuestion('How complex is this system?', _susComplexity,
                (value) {
              setState(() => _susComplexity = value!);
            }),
            _buildSusQuestion(
                'How easy to learn is this system?', _susEaseOfUse, (value) {
              setState(() => _susEaseOfUse = value!);
            }),
            _buildSusQuestion(
                'How technical support is this system?', _susTechnicalSupport,
                (value) {
              setState(() => _susTechnicalSupport = value!);
            }),
            _buildSusQuestion(
                'How well does this system integrate with other systems?',
                _susIntegration, (value) {
              setState(() => _susIntegration = value!);
            }),
            _buildSusQuestion(
                'How consistent is this system?', _susInconsistency, (value) {
              setState(() => _susInconsistency = value!);
            }),
            _buildSusQuestion('How quickly can you learn to use this system?',
                _susLearnQuickly, (value) {
              setState(() => _susLearnQuickly = value!);
            }),
            _buildSusQuestion('How cumbersome is this system?', _susCumbersome,
                (value) {
              setState(() => _susCumbersome = value!);
            }),
            _buildSusQuestion(
                'How confident are you in using this system?', _susConfident,
                (value) {
              setState(() => _susConfident = value!);
            }),
            _buildSusQuestion(
                'How first-time users feel about this system?', _susLearnFirst,
                (value) {
              setState(() => _susLearnFirst = value!);
            }),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your SUS Score:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$susScore',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSusQuestion(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: value,
                  isExpanded: true,
                  items: [1, 2, 3, 4, 5].map((int option) {
                    return DropdownMenuItem<int>(
                      value: option,
                      child: Text(option.toString(),
                          style: TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) => onChanged(val!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptoms & Side Effects',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
            SizedBox(height: 16),
            Text('Symptoms in this period:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomOptions.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (symptom == 'None') {
                        _selectedSymptoms.clear();
                        if (selected) _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove('None');
                        if (selected) {
                          _selectedSymptoms.add(symptom);
                        } else {
                          _selectedSymptoms.remove(symptom);
                        }
                        if (_selectedSymptoms.isEmpty) {
                          _selectedSymptoms.add('None');
                        }
                      }
                    });
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[700],
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Medication side effects:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sideEffectOptions.map((effect) {
                final isSelected = _selectedSideEffects.contains(effect);
                return FilterChip(
                  label: Text(effect),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (effect == 'None') {
                        _selectedSideEffects.clear();
                        if (selected) _selectedSideEffects.add(effect);
                      } else {
                        _selectedSideEffects.remove('None');
                        if (selected) {
                          _selectedSideEffects.add(effect);
                        } else {
                          _selectedSideEffects.remove(effect);
                        }
                        if (_selectedSideEffects.isEmpty) {
                          _selectedSideEffects.add('None');
                        }
                      }
                    });
                  },
                  selectedColor: Colors.red[100],
                  checkmarkColor: Colors.red[700],
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) => _symptomsNotes = value,
              decoration: InputDecoration(
                labelText: 'Additional notes',
                hintText: 'Describe symptoms or side effects...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Concerns & Improvements',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) => _concerns = value,
              decoration: InputDecoration(
                labelText: 'Any health concerns?',
                hintText: 'Share any worries or problems...',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.warning_amber, color: Colors.orange[600]),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 12),
            TextField(
              onChanged: (value) => _improvements = value,
              decoration: InputDecoration(
                labelText: 'Any improvements?',
                hintText: 'Share positive changes in your health...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up, color: Colors.green[600]),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final godinScore = _calculateGodinScore();
    final sarcfScore = _calculateSarcfScore();
    final susScore = _calculateSusScore();
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📊 Your Godin Exercise Score:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$godinScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💪 Your SARC-F Muscle Strength Score:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$sarcfScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⚙️ Your SUS Usability Score:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$susScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Submit Bimonthly Feedback',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
