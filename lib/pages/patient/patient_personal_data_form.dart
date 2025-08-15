import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/pages/patient/patient_health_lifestyle_form.dart';

class PatientPersonalDataForm extends StatefulWidget {
  const PatientPersonalDataForm({super.key});

  @override
  State<PatientPersonalDataForm> createState() =>
      _PatientPersonalDataFormState();
}

class _PatientPersonalDataFormState extends State<PatientPersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  String? _selectedLivingSituation;
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  final List<String> _livingSituations = [
    'Alone',
    'With Family',
    'Assisted Living',
    'Nursing Home'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _savePersonalData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateOfBirth == null ||
        _selectedGender == null ||
        _selectedBloodGroup == null ||
        _selectedMaritalStatus == null ||
        _selectedLivingSituation == null) {
      setState(() {
        _errorMessage = 'Please fill all required fields.';
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
      final personalData = {
        'name': _nameController.text.trim(),
        'fullName': _nameController.text
            .trim(), // Also save as fullName for consistency
        'dateOfBirth': Timestamp.fromDate(_selectedDateOfBirth!),
        'age': _calculateAge(_selectedDateOfBirth!),
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
        'maritalStatus': _selectedMaritalStatus,
        'livingSituation': _selectedLivingSituation,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': {
          'name': _emergencyContactNameController.text.trim(),
          'relationship': _emergencyContactRelationshipController.text.trim(),
          'phone': _emergencyContactPhoneController.text.trim(),
        },
        'email': user.email,
        'userId': user.uid,
        'userType': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
        'personalDataCompleted': true,
      };

      await _firestore
          .collection('patients')
          .doc(user.uid)
          .set(personalData, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => const PatientHealthLifestyleForm()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error saving data: $e';
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
                content: const Text(
                    'Are you sure you want to leave? Your progress will be lost.'),
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
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Information'),
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
                        'Personal Data',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient\'s Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (Display only - from Firebase Auth)
                      TextFormField(
                        initialValue: _auth.currentUser?.email ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 24),

                      // Emergency Contact Section
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Name
                      TextFormField(
                        controller: _emergencyContactNameController,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter emergency contact name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Relationship
                      TextFormField(
                        controller: _emergencyContactRelationshipController,
                        decoration: const InputDecoration(
                          labelText: 'Relationship *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                          hintText: 'e.g., Spouse, Parent, Sibling',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter relationship';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Phone
                      TextFormField(
                        controller: _emergencyContactPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact Phone *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.emergency),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter emergency contact phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Demographic Information Section
                      const Text(
                        'Demographic Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      InkWell(
                        onTap: _selectDateOfBirth,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDateOfBirth == null
                                ? 'Select Date of Birth'
                                : '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}',
                            style: TextStyle(
                              color: _selectedDateOfBirth == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Age (Auto-calculated)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        child: Text(
                          _selectedDateOfBirth == null
                              ? 'Select date of birth first'
                              : '${_calculateAge(_selectedDateOfBirth!)} years',
                          style: TextStyle(
                            color: _selectedDateOfBirth == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        hint: const Text('Select Gender'),
                        items: _genders.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Blood Group
                      DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.bloodtype),
                        ),
                        hint: const Text('Select Blood Group'),
                        items: _bloodGroups.map((String bloodGroup) {
                          return DropdownMenuItem<String>(
                            value: bloodGroup,
                            child: Text(bloodGroup),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBloodGroup = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select blood group';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Marital Status
                      DropdownButtonFormField<String>(
                        value: _selectedMaritalStatus,
                        decoration: const InputDecoration(
                          labelText: 'Marital Status *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.favorite),
                        ),
                        hint: const Text('Select Marital Status'),
                        items: _maritalStatuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMaritalStatus = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select marital status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Living Situation
                      DropdownButtonFormField<String>(
                        value: _selectedLivingSituation,
                        decoration: const InputDecoration(
                          labelText: 'Living Situation *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        hint: const Text('Select Living Situation'),
                        items: _livingSituations.map((String situation) {
                          return DropdownMenuItem<String>(
                            value: situation,
                            child: Text(situation),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLivingSituation = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select living situation';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePersonalData,
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
                                'Save & Continue',
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
