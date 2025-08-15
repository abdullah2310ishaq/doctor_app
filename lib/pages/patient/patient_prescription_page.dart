import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/models/prescription.dart';

class PatientPrescriptionPage extends StatefulWidget {
  const PatientPrescriptionPage({super.key});

  @override
  State<PatientPrescriptionPage> createState() =>
      _PatientPrescriptionPageState();
}

class _PatientPrescriptionPageState extends State<PatientPrescriptionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPrescriptionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      final prescriptions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        try {
          return Prescription.fromJson(data);
        } catch (e) {
          print('Error parsing prescription ${doc.id}: $e');
          // Return a default prescription if parsing fails
          return Prescription(
            id: doc.id,
            doctorId: data['doctorId'] ?? data['doctor_id'] ?? '',
            patientId: data['patientId'] ?? data['patient_id'] ?? '',
            patientName: data['patientName'] ?? 'Unknown Patient',
            date: data['date'] ?? DateTime.now().toIso8601String(),
            medications: [],
            instructions: data['instructions'],
          );
        }
      }).toList();

      setState(() {
        _prescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading prescriptions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logMedicine(String medName, String time, bool taken,
      [String? notes]) async {
    final user = _auth.currentUser;
    if (user == null || _prescriptions.isEmpty) return;

    if (_selectedPrescriptionIndex >= _prescriptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No prescription selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPrescription = _prescriptions[_selectedPrescriptionIndex];

    final log = {
      'medicationName': medName,
      'date': DateTime.now().toIso8601String(),
      'time': time,
      'taken': taken,
      'notes': notes ?? '', // Ensure notes is never null
    };

    try {
      if (currentPrescription.id.isNotEmpty) {
        // First check if the document exists and has logs array
        final docRef =
            _firestore.collection('prescriptions').doc(currentPrescription.id);
        final doc = await docRef.get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          List<dynamic> logs = data['logs'] ?? [];
          logs.add(log);

          await docRef.update({'logs': logs});
        } else {
          // If document doesn't exist, create it with the log
          await docRef.set({
            'logs': [log]
          }, SetOptions(merge: true));
        }
      }

      // Send feedback to doctor
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          doctorId = userDoc.data()?['assignedDoctorId'];
        }
        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          if (patientDoc.exists) {
            doctorId = patientDoc.data()?['assignedDoctorId'];
          }
        }
      } catch (e) {
        print('Error getting assigned doctor: $e');
      }

      final targetDoctorId = doctorId ?? currentPrescription.doctorId;

      if (targetDoctorId != null && targetDoctorId.isNotEmpty) {
        await _firestore.collection('prescription_feedback').add({
          'prescriptionId': currentPrescription.id,
          'patientId': user.uid,
          'doctorId': targetDoctorId,
          'feedback':
              taken ? 'Medication taken as prescribed' : 'Medication not taken',
          'medicationName': medName,
          'time': time,
          'taken': taken,
          'notes': notes,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medicine log saved and feedback sent to doctor!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the data
      _loadPrescriptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine log: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMedicineLogDialog(String medName, String time) {
    final TextEditingController notesController = TextEditingController();
    bool taken = true;
    String? sideEffects;
    String? missedReason;
    String effectiveness = 'Normal';
    bool willContinue = true;

    final List<String> effectivenessOptions = [
      'Very effective',
      'Effective',
      'Normal',
      'Not very effective',
      'No effect'
    ];
    final List<String> sideEffectOptions = [
      'None',
      'Nausea/Vomiting',
      'Dizziness',
      'Drowsiness',
      'Headache',
      'Stomach upset',
      'Allergic reaction',
      'Other (specify in notes)'
    ];
    final List<String> missedReasonOptions = [
      'Forgot to take',
      'Ran out of medicine',
      'Side effects too severe',
      'Feeling better, thought not needed',
      'Too busy/distracted',
      'Away from home',
      'Other (specify in notes)'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.medication, color: Colors.red[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log Medicine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicine: $medName',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scheduled time: $time',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Current time: ${TimeOfDay.now().format(context)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Did you take the medicine?
                  Text('Did you take this medicine?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile<bool>(
                        title: Text('✅ Yes, I took the medicine'),
                        value: true,
                        groupValue: taken,
                        onChanged: (value) {
                          setDialogState(() {
                            taken = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: Text('❌ No, I missed this dose'),
                        value: false,
                        groupValue: taken,
                        onChanged: (value) {
                          setDialogState(() {
                            taken = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  // If taken - effectiveness and side effects
                  if (taken) ...[
                    SizedBox(height: 16),
                    Text('How effective was the medicine?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: effectiveness,
                          isExpanded: true,
                          items: effectivenessOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              effectiveness = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Any side effects?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sideEffects ?? 'None',
                          isExpanded: true,
                          items: sideEffectOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              sideEffects = value;
                            });
                          },
                        ),
                      ),
                    ),
                    if (sideEffects != null && sideEffects != 'None') ...[
                      SizedBox(height: 16),
                      Text('Will you continue taking this medicine?',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<bool>(
                            title: Text('Yes, I will continue'),
                            value: true,
                            groupValue: willContinue,
                            onChanged: (value) {
                              setDialogState(() {
                                willContinue = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<bool>(
                            title: Text('No, side effects are too severe'),
                            value: false,
                            groupValue: willContinue,
                            onChanged: (value) {
                              setDialogState(() {
                                willContinue = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ],

                  // If missed - reason
                  if (!taken) ...[
                    SizedBox(height: 16),
                    Text('Why did you miss this dose?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: missedReason ?? missedReasonOptions[0],
                          isExpanded: true,
                          items: missedReasonOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              missedReason = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 16),

                  // Additional notes
                  Text('Additional notes (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: taken
                          ? 'Any additional comments...'
                          : 'Additional details about why you missed...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logEnhancedMedicine(
                  medName,
                  time,
                  taken,
                  effectiveness,
                  sideEffects,
                  missedReason,
                  willContinue,
                  notesController.text.isEmpty ? null : notesController.text,
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Save Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced medicine logging with comprehensive data
  Future<void> _logEnhancedMedicine(
    String medName,
    String time,
    bool taken,
    String effectiveness,
    String? sideEffects,
    String? missedReason,
    bool willContinue,
    String? notes,
  ) async {
    final user = _auth.currentUser;
    if (user == null || _prescriptions.isEmpty) return;

    if (_selectedPrescriptionIndex >= _prescriptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No prescription selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPrescription = _prescriptions[_selectedPrescriptionIndex];

    final log = {
      'medicationName': medName,
      'date': DateTime.now().toIso8601String(),
      'scheduledTime': time,
      'actualTime': TimeOfDay.now().format(context),
      'taken': taken,
      'effectiveness': taken ? effectiveness : null,
      'sideEffects': taken ? sideEffects : null,
      'missedReason': !taken ? missedReason : null,
      'willContinue': taken && sideEffects != null && sideEffects != 'None'
          ? willContinue
          : null,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // First check if the document exists and has logs array
      final docRef =
          _firestore.collection('prescriptions').doc(currentPrescription.id);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> logs = data['logs'] ?? [];
        logs.add(log);

        await docRef.update({'logs': logs});
      } else {
        // If document doesn't exist, create it with the log
        await docRef.set({
          'logs': [log]
        }, SetOptions(merge: true));
      }

      // Create notification to doctor about medicine log
      String doctorMessage = taken
          ? 'Patient took ${medName} at ${TimeOfDay.now().format(context)}.'
          : 'Patient missed ${medName} dose scheduled for ${time}.';

      if (taken && sideEffects != null && sideEffects != 'None') {
        doctorMessage += ' Reported side effects: ${sideEffects}.';
        if (!willContinue) {
          doctorMessage += ' Patient wants to stop due to side effects.';
        }
      }

      if (currentPrescription.doctorId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': currentPrescription.doctorId,
          'title': taken ? '💊 Medicine Taken' : '⚠️ Medicine Missed',
          'message': doctorMessage,
          'type': 'medicine_log_update',
          'relatedId': currentPrescription.id,
          'patientId': user.uid,
          'medicationName': medName,
          'taken': taken,
          'hasSideEffects':
              taken && sideEffects != null && sideEffects != 'None',
          'wantsToContinue': willContinue,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medicine log saved and sent to doctor!'),
          backgroundColor: taken ? Colors.green[600] : Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the data
      _loadPrescriptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine log: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendFeedbackToDoctor(
      String feedback, List<String> issues) async {
    final user = _auth.currentUser;
    if (user == null || _prescriptions.isEmpty) return;

    if (_selectedPrescriptionIndex >= _prescriptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No prescription selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPrescription = _prescriptions[_selectedPrescriptionIndex];

    try {
      // Get assigned doctor ID from patient profile
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          doctorId = userDoc.data()?['assignedDoctorId'];
        }
        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          if (patientDoc.exists) {
            doctorId = patientDoc.data()?['assignedDoctorId'];
          }
        }
      } catch (e) {
        print('Error getting assigned doctor: $e');
      }

      // Use assigned doctor ID if available, otherwise use prescription doctor ID
      final targetDoctorId = doctorId ?? currentPrescription.doctorId;

      if (targetDoctorId != null && targetDoctorId.isNotEmpty) {
        await _firestore.collection('prescription_feedback').add({
          'prescriptionId': currentPrescription.id,
          'patientId': user.uid,
          'doctorId': targetDoctorId,
          'feedback': feedback,
          'issues': issues,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback sent to doctor successfully!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    final List<String> availableIssues = [
      'Side effects experienced',
      'Difficulty swallowing pills',
      'Medication too expensive',
      'Unclear instructions',
      'Medicine not available',
      'Allergic reaction',
      'Not feeling better',
      'Dosage concerns',
    ];
    final Set<String> selectedIssues = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Prescription Feedback'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select any issues you\'re experiencing:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: availableIssues
                        .map((issue) => CheckboxListTile(
                              title:
                                  Text(issue, style: TextStyle(fontSize: 14)),
                              value: selectedIssues.contains(issue),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value!) {
                                    selectedIssues.add(issue);
                                  } else {
                                    selectedIssues.remove(issue);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    labelText: 'Additional feedback',
                    border: OutlineInputBorder(),
                    hintText: 'Describe any other concerns or suggestions...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendFeedbackToDoctor(
                    feedbackController.text, selectedIssues.toList());
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child:
                  Text('Send Feedback', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('My Prescriptions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.feedback),
            onPressed: _prescriptions.isNotEmpty ? _showFeedbackDialog : null,
            tooltip: 'Send Feedback',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
          : _errorMessage != null
              ? _buildErrorWidget()
              : _prescriptions.isEmpty
                  ? _buildEmptyWidget()
                  : _buildPrescriptionContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPrescriptions,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.blue[300]),
            SizedBox(height: 16),
            Text(
              'No Prescriptions Yet',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Your doctor will prescribe medications for you here.',
              style: TextStyle(fontSize: 16, color: Colors.blue[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionContent() {
    return Column(
      children: [
        // Prescription Selection
        if (_prescriptions.length > 1) ...[
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Prescription',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700]),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _prescriptions.length,
                        itemBuilder: (context, index) {
                          final prescription = _prescriptions[index];
                          final isSelected =
                              index == _selectedPrescriptionIndex;
                          final prescriptionDate =
                              DateTime.parse(prescription.date);

                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(prescriptionDate),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPrescriptionIndex = index;
                                  });
                                }
                              },
                              selectedColor: Colors.blue[700],
                              backgroundColor: Colors.blue[100],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Prescription Details
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _buildPrescriptionDetails(
                _prescriptions[_selectedPrescriptionIndex]),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionDetails(Prescription prescription) {
    final prescriptionDate = DateTime.parse(prescription.date);
    final today = DateTime.now();
    final isActive = true; // Assume all prescriptions are active for now

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prescription Overview Card
        Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Icon(Icons.medical_services,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Prescription Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Prescribed Date',
                      DateFormat('MMM dd, yyyy').format(prescriptionDate)),
                  _buildInfoRow('Status', isActive ? 'Active' : 'Completed'),
                  _buildInfoRow('Total Medications',
                      '${prescription.medications.length}'),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Instructions
        if (prescription.instructions != null &&
            prescription.instructions!.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor\'s Instructions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700]),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      prescription.instructions!,
                      style: TextStyle(fontSize: 14, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Medications Section
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medications',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700]),
                ),
                SizedBox(height: 16),
                ...prescription.medications.map(
                    (medication) => _buildMedicationCard(medication, isActive)),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Note: Medicine logs will be displayed in a future update
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication, bool isActive) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      Text(
                        'Dosage: ${medication.dosage}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Medication Details
            Text(
              'Frequency: ${medication.frequency}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              'Duration: ${medication.duration}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.yellow[200]!),
                ),
                child: Text(
                  'Notes: ${medication.notes}',
                  style: TextStyle(fontSize: 12, color: Colors.yellow[800]),
                ),
              ),
            ],

            // Medicine Times with Log Buttons
            if (medication.times != null && medication.times!.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Daily Schedule:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: medication.times!
                    .map((time) => Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.blue[600]),
                              SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold),
                              ),
                              if (isActive) ...[
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showMedicineLogDialog(
                                      medication.name, time),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[500],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Log',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(MedicationLog log) {
    final logDate = DateFormat('MMM dd, yyyy - HH:mm').format(log.date);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: log.taken ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: log.taken ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.taken ? Icons.check_circle : Icons.cancel,
                color: log.taken ? Colors.green[600] : Colors.red[600],
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '${log.medicationName} at ${log.time} - $logDate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: log.taken ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              log.taken ? 'Notes: ${log.notes}' : 'Reason: ${log.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
