import 'package:doctor_app/pages/patient/patient_diet_strength_form.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientFamilyActivityForm extends StatefulWidget {
  const PatientFamilyActivityForm({super.key});

  @override
  State<PatientFamilyActivityForm> createState() =>
      _PatientFamilyActivityFormState();
}

class _PatientFamilyActivityFormState extends State<PatientFamilyActivityForm> {
  final _formKey = GlobalKey<FormState>();

  // Family Health History
  final Map<String, FamilyMemberData> _familyMembers = {
    'Mother': FamilyMemberData(),
    'Father': FamilyMemberData(),
    'Brother': FamilyMemberData(),
    'Sister': FamilyMemberData(),
  };
  final _familyHealthInfoController = TextEditingController();

  // Physical Activity (Godin Leisure-Time Exercise Questionnaire)
  final _strenuousExerciseController = TextEditingController();
  final _moderateExerciseController = TextEditingController();
  final _mildExerciseController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _familyHealthInfoController.dispose();
    _strenuousExerciseController.dispose();
    _moderateExerciseController.dispose();
    _mildExerciseController.dispose();
    _familyMembers.forEach((key, value) => value.dispose());
    super.dispose();
  }

  void _saveFamilyActivityData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fill all required fields.';
      });
      return;
    }

    // Validate all family member data
    for (var entry in _familyMembers.entries) {
      if (entry.value.ageController.text.isEmpty ||
          entry.value.inGoodHealth == null ||
          entry.value.alive == null) {
        setState(() {
          _errorMessage = 'Please complete all fields for ${entry.key}.';
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
      Map<String, dynamic> familyHealthData = {};
      _familyMembers.forEach((role, data) {
        familyHealthData[role.toLowerCase()] = {
          'age': int.tryParse(data.ageController.text.trim()),
          'inGoodHealth': data.inGoodHealth,
          'knownHealthProblems': data.knownHealthProblemsController.text.trim(),
          'alive': data.alive,
        };
      });

      await _firestore.collection('patients').doc(user.uid).set({
        'familyHealthHistory': {
          'members': familyHealthData,
          'additionalInfo': _familyHealthInfoController.text.trim(),
        },
        'physicalActivity': {
          'strenuousExerciseTimesPerWeek': int.tryParse(
              _strenuousExerciseController.text.trim() == ''
                  ? '0'
                  : _strenuousExerciseController.text.trim()),
          'moderateExerciseTimesPerWeek': int.tryParse(
              _moderateExerciseController.text.trim() == ''
                  ? '0'
                  : _moderateExerciseController.text.trim()),
          'mildExerciseTimesPerWeek': int.tryParse(
              _mildExerciseController.text.trim() == ''
                  ? '0'
                  : _mildExerciseController.text.trim()),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family & Activity data saved successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _saveFamilyActivityData();
      // Navigate to Diet Strength Form
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PatientDietStrengthForm(),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family & Activity Info'),
        backgroundColor: Colors.blue[50],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Family Health History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._familyMembers.entries.map((entry) {
                  final role = entry.key;
                  final data = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: data.ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 0) return 'Invalid age';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('In Good Health?'),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Yes'),
                                  value: true,
                                  groupValue: data.inGoodHealth,
                                  onChanged: (value) =>
                                      setState(() => data.inGoodHealth = value),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('No'),
                                  value: false,
                                  groupValue: data.inGoodHealth,
                                  onChanged: (value) =>
                                      setState(() => data.inGoodHealth = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: data.knownHealthProblemsController,
                            decoration: const InputDecoration(
                              labelText: 'Known Health Problems',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          const Text('Alive?'),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Yes'),
                                  value: true,
                                  groupValue: data.alive,
                                  onChanged: (value) =>
                                      setState(() => data.alive = value),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('No'),
                                  value: false,
                                  groupValue: data.alive,
                                  onChanged: (value) =>
                                      setState(() => data.alive = value),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _familyHealthInfoController,
                  decoration: const InputDecoration(
                    labelText:
                        'Additional family health information (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Physical Activity (Godin Leisure-Time Exercise Questionnaire)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _strenuousExerciseController,
                  decoration: const InputDecoration(
                    labelText: 'STRENUOUS EXERCISE (Times per week)',
                    hintText:
                        'e.g., running, jogging, hockey (for more than 15 minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null || int.parse(value) < 0)
                      return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _moderateExerciseController,
                  decoration: const InputDecoration(
                    labelText: 'MODERATE EXERCISE (Times per week)',
                    hintText:
                        'e.g., fast walking, baseball, tennis (for more than 15 minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null || int.parse(value) < 0)
                      return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mildExerciseController,
                  decoration: const InputDecoration(
                    labelText: 'MILD/LIGHT EXERCISE (Times per week)',
                    hintText:
                        'e.g., yoga, archery, golf (for more than 15 minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null || int.parse(value) < 0)
                      return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveFamilyActivityData,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save & Continue to Diet Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class to manage controllers and state for each family member
class FamilyMemberData {
  final ageController = TextEditingController();
  final knownHealthProblemsController = TextEditingController();
  bool? inGoodHealth;
  bool? alive;

  void dispose() {
    ageController.dispose();
    knownHealthProblemsController.dispose();
  }
}
