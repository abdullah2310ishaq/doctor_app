import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _vitalSigns = [];
  bool _isEditing = false;

  // Controllers for editing
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  String? _selectedOccupation;
  String? _selectedSmokingHistory;
  String? _selectedAlcoholConsumption;
  String? _selectedActivityLevel;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown'
  ];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Widowed',
    'Divorced'
  ];
  final List<String> _occupations = [
    'Student',
    'Employed',
    'Self-employed',
    'Retired',
    'Unemployed',
    'Other'
  ];
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

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadVitalSigns();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _currentMedicationsController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('patients').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patientData = data;
          _populateControllers(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading patient data: $e');
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _nameController.text = data['fullName'] ?? data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _addressController.text = data['address'] ?? '';

    if (data['emergencyContact'] != null) {
      final emergency = data['emergencyContact'] as Map<String, dynamic>;
      _emergencyContactNameController.text = emergency['name'] ?? '';
      _emergencyContactPhoneController.text = emergency['phone'] ?? '';
      _emergencyContactRelationshipController.text =
          emergency['relationship'] ?? '';
    }

    _heightController.text = data['height']?.toString() ?? '';
    _weightController.text = data['weight']?.toString() ?? '';
    _allergiesController.text = data['allergies'] ?? '';
    _currentMedicationsController.text = data['currentMedications'] ?? '';
    _medicalHistoryController.text = data['medicalHistory'] ?? '';

    _selectedGender = data['gender'];
    _selectedBloodGroup = data['bloodGroup'];
    _selectedMaritalStatus = data['maritalStatus'];
    _selectedOccupation = data['occupation'];
    _selectedSmokingHistory = data['smokingHistory'];
    _selectedAlcoholConsumption = data['alcoholConsumption'];
    _selectedActivityLevel = data['dailyActivityLevel'];
  }

  Future<void> _loadVitalSigns() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      setState(() {
        _vitalSigns = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading vital signs: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updateData = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': {
          'name': _emergencyContactNameController.text.trim(),
          'phone': _emergencyContactPhoneController.text.trim(),
          'relationship': _emergencyContactRelationshipController.text.trim(),
        },
        'height': _heightController.text.trim().isNotEmpty
            ? double.tryParse(_heightController.text.trim())
            : null,
        'weight': _weightController.text.trim().isNotEmpty
            ? double.tryParse(_weightController.text.trim())
            : null,
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
        'maritalStatus': _selectedMaritalStatus,
        'occupation': _selectedOccupation,
        'allergies': _allergiesController.text.trim(),
        'currentMedications': _currentMedicationsController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'smokingHistory': _selectedSmokingHistory,
        'alcoholConsumption': _selectedAlcoholConsumption,
        'dailyActivityLevel': _selectedActivityLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('patients').doc(user.uid).update(updateData);

      await _loadPatientData();
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addVitalReading() async {
    final TextEditingController systolicController = TextEditingController();
    final TextEditingController diastolicController = TextEditingController();
    final TextEditingController sugarController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vital Signs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicController,
                      decoration: const InputDecoration(
                        labelText: 'Systolic BP',
                        hintText: '120',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic BP',
                        hintText: '80',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sugarController,
                decoration: const InputDecoration(
                  labelText: 'Blood Sugar (mg/dL)',
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional notes...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final systolic = int.tryParse(systolicController.text);
              final diastolic = int.tryParse(diastolicController.text);
              final sugar = int.tryParse(sugarController.text);

              if (systolic == null || diastolic == null || sugar == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user == null) return;

                await _firestore.collection('vital_signs').add({
                  'patientId': user.uid,
                  'systolic': systolic.toString(),
                  'diastolic': diastolic.toString(),
                  'sugar': sugar.toString(),
                  'notes': notesController.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.of(context).pop();
                await _loadVitalSigns();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vital signs added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding vital signs: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getBPColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return Colors.green;
    if (systolic < 130 && diastolic < 80) return Colors.yellow;
    if (systolic < 140 && diastolic < 90) return Colors.orange;
    return Colors.red;
  }

  Color _getSugarColor(int sugar) {
    if (sugar < 100) return Colors.green;
    if (sugar < 126) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.teal[100],
                            child: Text(
                              _patientData?['fullName']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'P',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _patientData?['fullName'] ?? 'Patient Name',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _patientData?['email'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                if (_patientData?['age'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Age: ${_patientData!['age']} years',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personal Information
                  _buildSection(
                    'Personal Information',
                    Icons.person,
                    _buildPersonalInfoSection(),
                  ),
                  const SizedBox(height: 16),

                  // Physical Measurements
                  _buildSection(
                    'Physical Measurements',
                    Icons.height,
                    _buildPhysicalMeasurementsSection(),
                  ),
                  const SizedBox(height: 16),

                  // Medical History
                  _buildSection(
                    'Medical History',
                    Icons.medical_services,
                    _buildMedicalHistorySection(),
                  ),
                  const SizedBox(height: 16),

                  // Vital Signs
                  _buildSection(
                    'Vital Signs',
                    Icons.favorite,
                    _buildVitalSignsSection(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    if (_isEditing) {
      return Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                  ),
                  items: _bloodGroups.map((group) {
                    return DropdownMenuItem(value: group, child: Text(group));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodGroup = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMaritalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Marital Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _maritalStatuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMaritalStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOccupation,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder(),
                  ),
                  items: _occupations.map((occupation) {
                    return DropdownMenuItem(
                        value: occupation, child: Text(occupation));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOccupation = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Emergency Contact',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emergencyContactNameController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emergencyContactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emergencyContactRelationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _populateControllers(_patientData!);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildInfoRow('Name', _patientData?['fullName'] ?? 'Not provided'),
        _buildInfoRow('Phone', _patientData?['phone'] ?? 'Not provided'),
        _buildInfoRow('Address', _patientData?['address'] ?? 'Not provided'),
        _buildInfoRow('Gender', _patientData?['gender'] ?? 'Not provided'),
        _buildInfoRow(
            'Blood Group', _patientData?['bloodGroup'] ?? 'Not provided'),
        _buildInfoRow(
            'Marital Status', _patientData?['maritalStatus'] ?? 'Not provided'),
        _buildInfoRow(
            'Occupation', _patientData?['occupation'] ?? 'Not provided'),
        if (_patientData?['emergencyContact'] != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Emergency Contact',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _buildInfoRow('Name',
              _patientData!['emergencyContact']['name'] ?? 'Not provided'),
          _buildInfoRow('Phone',
              _patientData!['emergencyContact']['phone'] ?? 'Not provided'),
          _buildInfoRow(
              'Relationship',
              _patientData!['emergencyContact']['relationship'] ??
                  'Not provided'),
        ],
      ],
    );
  }

  Widget _buildPhysicalMeasurementsSection() {
    if (_isEditing) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSmokingHistory,
                  decoration: const InputDecoration(
                    labelText: 'Smoking History',
                    border: OutlineInputBorder(),
                  ),
                  items: _smokingOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSmokingHistory = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAlcoholConsumption,
                  decoration: const InputDecoration(
                    labelText: 'Alcohol Consumption',
                    border: OutlineInputBorder(),
                  ),
                  items: _alcoholOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAlcoholConsumption = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            decoration: const InputDecoration(
              labelText: 'Activity Level',
              border: OutlineInputBorder(),
            ),
            items: _activityOptions.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value;
              });
            },
          ),
        ],
      );
    }

    final height = _patientData?['height'];
    final weight = _patientData?['weight'];
    double? bmi;
    if (height != null && weight != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
    }

    return Column(
      children: [
        if (height != null)
          _buildInfoRow('Height', '${height.toStringAsFixed(1)} cm'),
        if (weight != null)
          _buildInfoRow('Weight', '${weight.toStringAsFixed(1)} kg'),
        if (bmi != null) ...[
          _buildInfoRow(
              'BMI', '${bmi.toStringAsFixed(1)} (${_getBMICategory(bmi)})'),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getBMIColor(bmi).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BMI Category: ${_getBMICategory(bmi)}',
              style: TextStyle(
                color: _getBMIColor(bmi),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        _buildInfoRow('Smoking History',
            _patientData?['smokingHistory'] ?? 'Not provided'),
        _buildInfoRow('Alcohol Consumption',
            _patientData?['alcoholConsumption'] ?? 'Not provided'),
        _buildInfoRow('Activity Level',
            _patientData?['dailyActivityLevel'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildMedicalHistorySection() {
    if (_isEditing) {
      return Column(
        children: [
          TextField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              labelText: 'Allergies',
              border: OutlineInputBorder(),
              hintText: 'List any allergies...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentMedicationsController,
            decoration: const InputDecoration(
              labelText: 'Current Medications',
              border: OutlineInputBorder(),
              hintText: 'List current medications...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _medicalHistoryController,
            decoration: const InputDecoration(
              labelText: 'Medical History',
              border: OutlineInputBorder(),
              hintText: 'Previous medical conditions, surgeries...',
            ),
            maxLines: 3,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildInfoRow(
            'Allergies', _patientData?['allergies'] ?? 'None reported'),
        _buildInfoRow('Current Medications',
            _patientData?['currentMedications'] ?? 'None reported'),
        _buildInfoRow('Medical History',
            _patientData?['medicalHistory'] ?? 'None reported'),
      ],
    );
  }

  Widget _buildVitalSignsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Readings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addVitalReading,
              icon: const Icon(Icons.add),
              label: const Text('Add Reading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_vitalSigns.isEmpty)
          const Center(
            child: Text(
              'No vital signs recorded yet.\nTap "Add Reading" to record your first reading.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: _vitalSigns.map((reading) {
              final date = DateTime.tryParse(reading['date'] ?? '');
              final systolic = int.tryParse(reading['systolic'] ?? '');
              final diastolic = int.tryParse(reading['diastolic'] ?? '');
              final sugar = int.tryParse(reading['sugar'] ?? '');
              final notes = reading['notes'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date != null
                                ? DateFormat('MMM dd, yyyy').format(date)
                                : 'Unknown date',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (date != null)
                            Text(
                              DateFormat('hh:mm a').format(date),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (systolic != null && diastolic != null) ...[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getBPColor(systolic, diastolic)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Blood Pressure',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '$systolic/$diastolic',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getBPColor(systolic, diastolic),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (sugar != null) ...[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getSugarColor(sugar).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Blood Sugar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '$sugar mg/dL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getSugarColor(sugar),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: $notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
