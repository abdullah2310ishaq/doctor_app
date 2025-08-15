import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/pages/patient/patient_dashboard.dart';

class PatientDietStrengthForm extends StatefulWidget {
  const PatientDietStrengthForm({super.key});

  @override
  State<PatientDietStrengthForm> createState() =>
      _PatientDietStrengthFormState();
}

class _PatientDietStrengthFormState extends State<PatientDietStrengthForm> {
  final _formKey = GlobalKey<FormState>();

  // Dietary Habits (Food Frequency Questionnaire)
  final Map<String, String?> _foodFrequencyAnswers = {
    'Q1': null,
    'Q2': null,
    'Q3': null,
    'Q4': null,
    'Q5': null,
    'Q6': null,
    'Q7': null,
    'Q8': null,
    'Q9b': null,
    'Q10': null,
    'Q11': null,
    'Q12': null,
    'Q13': null,
    'Q14': null,
  };

  final Map<String, List<String>> _foodFrequencyOptions = {
    'Q1': [
      'Once a day or more often',
      'A few times a week',
      'Once a week or less often'
    ],
    'Q2': [
      'Once a day or more often',
      'A few times a week',
      'Once a week or less often'
    ],
    'Q3': [
      'Once a day or more often',
      'A few times a week',
      'Once a week or less often'
    ],
    'Q4': [
      'Three times a week or more often',
      'Once or twice a week',
      'A few times a month or less often'
    ],
    'Q5': [
      'Three times a week or more often',
      'Once or twice a week',
      'A few times a month or less often'
    ],
    'Q6': [
      'Three times a week or more often',
      'Once or twice a week',
      'A few times a month or less often'
    ],
    'Q7': [
      'Once a day or more often',
      'A few times a week',
      'Once a week or less often'
    ],
    'Q8': ['Everyday', 'Not Everyday'],
    'Q9b': [
      'White bread',
      'Whole wheat bread/crispbread',
      'Combinations of above'
    ],
    'Q10': [
      'Once a day or more often',
      'A few times a week',
      'Once a week or less often'
    ],
    'Q11': [
      'Full fat (3%)',
      'Semi-skimmed/reduced fat (1.5%)',
      'Skimmed/low-fat/non-fat (<0.5%)'
    ],
    'Q12': [
      'Butter (>75% fat)',
      'Margarine with plant sterols',
      'Margarine (30–70% fat)'
    ],
    'Q13': [
      'Butter/margarine (60–80%)',
      'Margarine made with seed and plant oils/liquid',
      'Vegetable oil'
    ],
    'Q14': ['No/yes sometimes', 'Yes, often/always'],
  };

  final Map<String, String> _foodFrequencyQuestions = {
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

  // Muscle Strength (SARC-F Questionnaire)
  final Map<String, String?> _sarcfAnswers = {
    'Strength': null,
    'Assistance in walking': null,
    'Rise from a chair': null,
    'Climb stairs': null,
    'Falls': null,
  };

  final Map<String, List<String>> _sarcfOptions = {
    'Strength': ['None', 'Some', 'A lot or unable'],
    'Assistance in walking': ['None', 'Some', 'A lot, use aids, or unable'],
    'Rise from a chair': ['None', 'Some', 'A lot or unable without help'],
    'Climb stairs': ['None', 'Some', 'A lot or unable'],
    'Falls': ['None', 'Less than 3 falls', '4 or more falls'],
  };

  // Application Usability (System Usability Scale - SUS)
  final Map<String, int?> _susAnswers = {
    'I think that I would like to use this system frequently': null,
    'I found the system unnecessarily complex': null,
    'I thought the system was easy to use': null,
    'I think that I would need the support of a technical person to be able to use this system': null,
    'I found the various functions in this system were well integrated': null,
    'I thought there was too much inconsistency in this system': null,
    'I would imagine that most people would learn to use this system very quickly': null,
    'I found the system very cumbersome to use': null,
    'I felt very confident using the system': null,
    'I needed to learn a lot of things before I could get going with this system': null,
  };

  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _saveDietStrengthUsabilityData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fill all required fields.';
      });
      return;
    }

    // Validate all radio button selections
    for (var answer in _foodFrequencyAnswers.values) {
      if (answer == null) {
        setState(() {
          _errorMessage = 'Please answer all Dietary Habits questions.';
        });
        return;
      }
    }
    for (var answer in _sarcfAnswers.values) {
      if (answer == null) {
        setState(() {
          _errorMessage = 'Please answer all Muscle Strength questions.';
        });
        return;
      }
    }
    for (var answer in _susAnswers.values) {
      if (answer == null) {
        setState(() {
          _errorMessage = 'Please answer all Application Usability questions.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _firestore.collection('patients').doc(user.uid).set({
        'dietaryHabits': _foodFrequencyAnswers,
        'muscleStrength': _sarcfAnswers,
        'applicationUsability': _susAnswers,
        'profileCompleted': true, // Mark profile as fully completed!
        'profileVersion': 29, // Add version 29
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the PatientDashboard after completing the entire profile
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PatientDashboard()),
      );

    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save data: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when user tries to go back
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Form'),
            content: const Text('Are you sure you want to leave? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Diet, Strength & Usability'),
          backgroundColor: Colors.blue[50],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Dietary Habits (Food Frequency Questionnaire)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Food Frequency Questions
                      ..._foodFrequencyAnswers.keys.map((questionKey) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${questionKey}. ${_foodFrequencyQuestions[questionKey]}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              ..._foodFrequencyOptions[questionKey]!.map((option) {
                                return RadioListTile<String>(
                                  title: Text(option),
                                  value: option,
                                  groupValue: _foodFrequencyAnswers[questionKey],
                                  onChanged: (value) {
                                    setState(() {
                                      _foodFrequencyAnswers[questionKey] = value;
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Muscle Strength (SARC-F Questionnaire)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // SARC-F Questions
                      ..._sarcfAnswers.keys.map((questionKey) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How much difficulty do you have in: $questionKey',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              ..._sarcfOptions[questionKey]!.map((option) {
                                return RadioListTile<String>(
                                  title: Text(option),
                                  value: option,
                                  groupValue: _sarcfAnswers[questionKey],
                                  onChanged: (value) {
                                    setState(() {
                                      _sarcfAnswers[questionKey] = value;
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Application Usability (System Usability Scale - SUS)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rate your agreement with the following statements (1: Strongly Disagree, 5: Strongly Agree)',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      
                      // SUS Questions
                      ..._susAnswers.keys.map((question) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(5, (index) {
                                  final score = index + 1;
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Radio<int>(
                                          value: score,
                                          groupValue: _susAnswers[question],
                                          onChanged: (value) {
                                            setState(() {
                                              _susAnswers[question] = value;
                                            });
                                          },
                                        ),
                                        Text('$score'),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveDietStrengthUsabilityData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Complete Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
