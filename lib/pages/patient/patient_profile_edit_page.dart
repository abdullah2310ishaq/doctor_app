import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientProfileEditPage extends StatefulWidget {
  const PatientProfileEditPage({super.key});

  @override
  State<PatientProfileEditPage> createState() => _PatientProfileEditPageState();
}

class _PatientProfileEditPageState extends State<PatientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for form fields
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
  final _occupationController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  String? _selectedSmokingStatus;
  String? _selectedAlcoholConsumption;
  String? _selectedExerciseHabits;

  DateTime? _selectedDateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _patientData;

  // Dropdown options
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
  final List<String> _smokingStatuses = [
    'Never',
    'Former',
    'Current',
    'Occasional'
  ];
  final List<String> _alcoholConsumption = [
    'Never',
    'Occasional',
    'Moderate',
    'Heavy'
  ];
  final List<String> _exerciseHabits = [
    'None',
    'Light',
    'Moderate',
    'Heavy',
    'Athletic'
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
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
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('patients').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patientData = data;
          _populateFormFields(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Patient profile not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading patient data: $e';
        _isLoading = false;
      });
    }
  }

  void _populateFormFields(Map<String, dynamic> data) {
    _nameController.text = data['fullName'] ?? data['name'] ?? '';
    _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? '';
    _addressController.text = data['address'] ?? '';
    _occupationController.text = data['occupation'] ?? '';
    _heightController.text = data['height']?.toString() ?? '';
    _weightController.text = data['weight']?.toString() ?? '';
    _allergiesController.text = data['allergies'] ?? '';
    _currentMedicationsController.text = data['currentMedications'] ?? '';
    _medicalHistoryController.text = data['medicalHistory'] ?? '';

    // Set dropdown values
    _selectedGender = data['gender'];
    _selectedBloodGroup = data['bloodGroup'];
    _selectedMaritalStatus = data['maritalStatus'];
    _selectedSmokingStatus = data['smokingStatus'];
    _selectedAlcoholConsumption = data['alcoholConsumption'];
    _selectedExerciseHabits = data['exerciseHabits'];

    // Set date of birth
    if (data['dateOfBirth'] != null) {
      if (data['dateOfBirth'] is Timestamp) {
        _selectedDateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
      } else if (data['dateOfBirth'] is String) {
        _selectedDateOfBirth = DateTime.parse(data['dateOfBirth']);
      }
    }

    // Set emergency contact
    if (data['emergencyContact'] != null) {
      final emergencyContact = data['emergencyContact'] as Map<String, dynamic>;
      _emergencyContactNameController.text = emergencyContact['name'] ?? '';
      _emergencyContactPhoneController.text = emergencyContact['phone'] ?? '';
      _emergencyContactRelationshipController.text =
          emergencyContact['relationship'] ?? '';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateData = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'height': _heightController.text.trim().isEmpty
            ? null
            : _heightController.text.trim(),
        'weight': _weightController.text.trim().isEmpty
            ? null
            : _weightController.text.trim(),
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
        'maritalStatus': _selectedMaritalStatus,
        'smokingStatus': _selectedSmokingStatus,
        'alcoholConsumption': _selectedAlcoholConsumption,
        'exerciseHabits': _selectedExerciseHabits,
        'allergies': _allergiesController.text.trim(),
        'currentMedications': _currentMedicationsController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'emergencyContact': {
          'name': _emergencyContactNameController.text.trim(),
          'phone': _emergencyContactPhoneController.text.trim(),
          'relationship': _emergencyContactRelationshipController.text.trim(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_selectedDateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(_selectedDateOfBirth!);
        updateData['age'] = _calculateAge(_selectedDateOfBirth!);
      }

      await _firestore.collection('patients').doc(user.uid).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving profile: $e';
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[600]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.red[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPatientData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                            'Personal Information', Icons.person),
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'Physical Measurements', Icons.height),
                        _buildPhysicalMeasurementsSection(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'Medical Information', Icons.medical_services),
                        _buildMedicalInfoSection(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'Emergency Contact', Icons.emergency),
                        _buildEmergencyContactSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700], size: 24),
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
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: _genders.map((gender) {
                      return DropdownMenuItem(
                          value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select gender';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDateOfBirth != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(_selectedDateOfBirth!)
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedDateOfBirth != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.bloodtype),
                      border: OutlineInputBorder(),
                    ),
                    items: _bloodGroups.map((group) {
                      return DropdownMenuItem(value: group, child: Text(group));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBloodGroup = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMaritalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Marital Status',
                      prefixIcon: Icon(Icons.favorite),
                      border: OutlineInputBorder(),
                    ),
                    items: _maritalStatuses.map((status) {
                      return DropdownMenuItem(
                          value: status, child: Text(status));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedMaritalStatus = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalMeasurementsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
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
                    value: _selectedSmokingStatus,
                    decoration: const InputDecoration(
                      labelText: 'Smoking Status',
                      prefixIcon: Icon(Icons.smoking_rooms),
                      border: OutlineInputBorder(),
                    ),
                    items: _smokingStatuses.map((status) {
                      return DropdownMenuItem(
                          value: status, child: Text(status));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSmokingStatus = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAlcoholConsumption,
                    decoration: const InputDecoration(
                      labelText: 'Alcohol Consumption',
                      prefixIcon: Icon(Icons.local_bar),
                      border: OutlineInputBorder(),
                    ),
                    items: _alcoholConsumption.map((consumption) {
                      return DropdownMenuItem(
                          value: consumption, child: Text(consumption));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAlcoholConsumption = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedExerciseHabits,
              decoration: const InputDecoration(
                labelText: 'Exercise Habits',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
              items: _exerciseHabits.map((habit) {
                return DropdownMenuItem(value: habit, child: Text(habit));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedExerciseHabits = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (if any)',
                prefixIcon: Icon(Icons.warning),
                border: OutlineInputBorder(),
                hintText: 'e.g., Peanuts, Penicillin, Latex',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentMedicationsController,
              decoration: const InputDecoration(
                labelText: 'Current Medications',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
                hintText: 'List any medications you are currently taking',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medicalHistoryController,
              decoration: const InputDecoration(
                labelText: 'Medical History',
                prefixIcon: Icon(Icons.history),
                border: OutlineInputBorder(),
                hintText: 'Any significant medical conditions or surgeries',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _emergencyContactNameController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter emergency contact name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emergencyContactPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter emergency contact phone';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emergencyContactRelationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: Icon(Icons.family_restroom),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Spouse, Parent, Friend',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter relationship';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
