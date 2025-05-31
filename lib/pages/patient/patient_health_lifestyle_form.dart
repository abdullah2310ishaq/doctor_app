import 'package:doctor_app/pages/patient/patient_family_activity_form.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:doctor_app/pages/patient/patient_family_activity_form.dart'; // Placeholder for next page
import 'package:doctor_app/pages/patient/patient_dashboard.dart'; // Temporary navigation for now

class PatientHealthLifestyleForm extends StatefulWidget {
  const PatientHealthLifestyleForm({super.key});

  @override
  State<PatientHealthLifestyleForm> createState() =>
      _PatientHealthLifestyleFormState();
}

class _PatientHealthLifestyleFormState
    extends State<PatientHealthLifestyleForm> {
  final _formKey = GlobalKey<FormState>();

  // Height & Weight
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _weightLbsController = TextEditingController();
  final _weightKgController = TextEditingController();
  bool _useImperialHeight = true; // true for ft/in, false for cm
  bool _useImperialWeight = true; // true for lbs, false for kg

  // Lifestyle
  String? _smokingHistory;
  String? _alcoholConsumption;
  String? _dailyActivityLevel;

  // Medical History
  final List<String> _selectedConditions = [];
  final _otherConditionController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  String? _recentSurgeries;
  final _recentSurgeriesSpecifyController = TextEditingController();
  final List<String> _selectedAssistiveDevices = [];
  final _otherAssistiveDeviceController = TextEditingController();
  String? _tuberculosisHistory;
  String? _mentalHealthClinicianCare;
  String? _restrictedEatingHistory;

  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dropdown/Radio options
  final List<String> _smokingOptions = [
    'Never smoked',
    'Former smoker',
    'Current smoker'
  ];
  final List<String> _alcoholOptions = ['Never', 'Occasionally', 'Frequently'];
  final List<String> _activityOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active'
  ];
  final List<String> _medicalConditions = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Arthritis',
    'Osteoporosis',
    'Asthma or COPD',
    'Depression or Anxiety',
    'Dementia or Cognitive Impairment',
    'Stroke History',
    'Vision or Hearing Impairment'
  ];
  final List<String> _assistiveDevices = [
    'None',
    'Cane',
    'Walker',
    'Wheelchair',
    'Hearing Aid'
  ];

  @override
  void dispose() {
    _heightFtController.dispose();
    _heightInController.dispose();
    _heightCmController.dispose();
    _weightLbsController.dispose();
    _weightKgController.dispose();
    _otherConditionController.dispose();
    _currentMedicationsController.dispose();
    _allergiesController.dispose();
    _recentSurgeriesSpecifyController.dispose();
    _otherAssistiveDeviceController.dispose();
    super.dispose();
  }

  void _saveHealthLifestyleData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fill all required fields.';
      });
      return;
    }
    if (_smokingHistory == null ||
        _alcoholConsumption == null ||
        _dailyActivityLevel == null ||
        _recentSurgeries == null ||
        _tuberculosisHistory == null ||
        _mentalHealthClinicianCare == null ||
        _restrictedEatingHistory == null) {
      setState(() {
        _errorMessage = 'Please select all required options.';
      });
      return;
    }
    if (_selectedConditions.isEmpty &&
        _otherConditionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Please select at least one medical condition or specify "Other".';
      });
      return;
    }
    if (_selectedAssistiveDevices.isEmpty &&
        _otherAssistiveDeviceController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Please select at least one assistive device or specify "Other".';
      });
      return;
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
      // Prepare medical conditions list
      List<String> finalConditions = List.from(_selectedConditions);
      if (_otherConditionController.text.trim().isNotEmpty) {
        finalConditions.add('Other: ${_otherConditionController.text.trim()}');
      }

      // Prepare assistive devices list
      List<String> finalAssistiveDevices = List.from(_selectedAssistiveDevices);
      if (_otherAssistiveDeviceController.text.trim().isNotEmpty) {
        finalAssistiveDevices
            .add('Other: ${_otherAssistiveDeviceController.text.trim()}');
      }

      await _firestore.collection('patients').doc(user.uid).set({
        'healthLifestyle': {
          'height': _useImperialHeight
              ? '${_heightFtController.text.trim()} ft ${_heightInController.text.trim()} in'
              : '${_heightCmController.text.trim()} cm',
          'weight': _useImperialWeight
              ? '${_weightLbsController.text.trim()} lbs'
              : '${_weightKgController.text.trim()} kg',
          'smokingHistory': _smokingHistory,
          'alcoholConsumption': _alcoholConsumption,
          'dailyActivityLevel': _dailyActivityLevel,
        },
        'medicalHistory': {
          'conditions': finalConditions,
          'currentMedications': _currentMedicationsController.text.trim(),
          'allergies': _allergiesController.text.trim(),
          'recentSurgeries': _recentSurgeries,
          'recentSurgeriesSpecify': _recentSurgeries == 'Yes'
              ? _recentSurgeriesSpecifyController.text.trim()
              : null,
          'assistiveDevices': finalAssistiveDevices,
          'tuberculosisHistory': _tuberculosisHistory,
          'mentalHealthClinicianCare': _mentalHealthClinicianCare,
          'restrictedEatingHistory': _restrictedEatingHistory,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge: true to update existing fields

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Health & Lifestyle data saved successfully!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PatientFamilyActivityForm()),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Failed to save data: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
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
        title: const Text('Patient Profile: Health & Lifestyle'),
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
                  'Personal Health & Lifestyle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Height Input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _useImperialHeight
                            ? _heightFtController
                            : _heightCmController,
                        decoration: InputDecoration(
                          labelText: _useImperialHeight
                              ? 'Height (ft)'
                              : 'Height (cm)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    if (_useImperialHeight) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _heightInController,
                          decoration: const InputDecoration(
                            labelText: 'Inches',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Required';
                            final int? inches = int.tryParse(value);
                            if (inches == null || inches < 0 || inches > 11)
                              return '0-11';
                            return null;
                          },
                        ),
                      ),
                    ],
                    IconButton(
                      icon: Icon(
                          _useImperialHeight ? Icons.straighten : Icons.height),
                      onPressed: () {
                        setState(() {
                          _useImperialHeight = !_useImperialHeight;
                          _heightFtController.clear();
                          _heightInController.clear();
                          _heightCmController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weight Input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _useImperialWeight
                            ? _weightLbsController
                            : _weightKgController,
                        decoration: InputDecoration(
                          labelText: _useImperialWeight
                              ? 'Weight (lbs)'
                              : 'Weight (kg)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(_useImperialWeight
                          ? Icons.fitness_center
                          : Icons.scale),
                      onPressed: () {
                        setState(() {
                          _useImperialWeight = !_useImperialWeight;
                          _weightLbsController.clear();
                          _weightKgController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smoking History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: _smokingOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _smokingHistory,
                      onChanged: (value) {
                        setState(() {
                          _smokingHistory = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alcohol Consumption',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: _alcoholOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _alcoholConsumption,
                      onChanged: (value) {
                        setState(() {
                          _alcoholConsumption = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daily Activity Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: _activityOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _dailyActivityLevel,
                      onChanged: (value) {
                        setState(() {
                          _dailyActivityLevel = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Medical History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Do you have any of the following conditions? (Check all that apply)',
                  style: TextStyle(fontSize: 16),
                ),
                ..._medicalConditions.map((condition) {
                  return CheckboxListTile(
                    title: Text(condition),
                    value: _selectedConditions.contains(condition),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked!) {
                          _selectedConditions.add(condition);
                        } else {
                          _selectedConditions.remove(condition);
                        }
                      });
                    },
                  );
                }).toList(),
                TextFormField(
                  controller: _otherConditionController,
                  decoration: const InputDecoration(
                    labelText: 'Other Medical Condition (specify)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentMedicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Current Medications (name, doses, timings)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies (medication/food/environmental)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Any recent surgeries or hospitalizations?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: ['Yes', 'No'].map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _recentSurgeries,
                      onChanged: (value) {
                        setState(() {
                          _recentSurgeries = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_recentSurgeries == 'Yes')
                  TextFormField(
                    controller: _recentSurgeriesSpecifyController,
                    decoration: const InputDecoration(
                      labelText: 'Please specify surgeries/hospitalizations',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_recentSurgeries == 'Yes' &&
                          (value == null || value.isEmpty)) {
                        return 'Please specify';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Do you use any assistive devices?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ..._assistiveDevices.map((device) {
                  return CheckboxListTile(
                    title: Text(device),
                    value: _selectedAssistiveDevices.contains(device),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked!) {
                          _selectedAssistiveDevices.add(device);
                        } else {
                          _selectedAssistiveDevices.remove(device);
                        }
                      });
                    },
                  );
                }).toList(),
                TextFormField(
                  controller: _otherAssistiveDeviceController,
                  decoration: const InputDecoration(
                    labelText: 'Other Assistive Device (specify)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Have you ever had tuberculosis or had a positive tuberculosis test?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: ['Yes', 'No'].map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _tuberculosisHistory,
                      onChanged: (value) {
                        setState(() {
                          _tuberculosisHistory = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Have you ever been cared for by a mental health clinician?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: ['Yes', 'No'].map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _mentalHealthClinicianCare,
                      onChanged: (value) {
                        setState(() {
                          _mentalHealthClinicianCare = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Have you ever restricted your eating?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: ['Yes', 'No'].map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _restrictedEatingHistory,
                      onChanged: (value) {
                        setState(() {
                          _restrictedEatingHistory = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveHealthLifestyleData,
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
                        : const Text('Save & Continue'),
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
