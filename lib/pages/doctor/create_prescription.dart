import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/services/notification_service.dart';

class CreatePrescriptionPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onPrescriptionCreated;

  const CreatePrescriptionPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onPrescriptionCreated,
  });

  @override
  State<CreatePrescriptionPage> createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLoading = false;

  List<TimeOfDay> _medicationTimes = [const TimeOfDay(hour: 8, minute: 0)];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _medicationTimes[index],
    );
    if (picked != null) {
      setState(() {
        _medicationTimes[index] = picked;
      });
    }
  }

  void _addTime() {
    setState(() {
      _medicationTimes.add(const TimeOfDay(hour: 8, minute: 0));
    });
  }

  void _removeTime(int index) {
    setState(() {
      if (_medicationTimes.length > 1) {
        _medicationTimes.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _createPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      final doctorName = doctorDoc.exists
          ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
          : 'Doctor';

      final prescriptionRef = await _firestore.collection('prescriptions').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'date': DateTime.now().toIso8601String(),
        'medications': [
          {
            'name': _medicineController.text.trim(),
            'dosage': _dosageController.text.trim(),
            'frequency': _frequencyController.text.trim(),
            'duration': _durationController.text.trim(),
            'notes': '',
            'times': _medicationTimes.map((t) => t.format(context)).toList(),
          }
        ],
        'instructions': _instructionsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createPrescriptionNotification(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        prescriptionId: prescriptionRef.id,
      );

      if (!mounted) return;
      widget.onPrescriptionCreated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating prescription: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prescribe for ${widget.patientName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prescription Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _medicineController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.medical_services,
                          color: Colors.blue),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter medicine name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage (e.g., 500mg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.local_pharmacy, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _frequencyController,
                    decoration: InputDecoration(
                      labelText: 'Frequency (e.g., Twice daily)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.schedule, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Duration (e.g., 7 days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.calendar_today, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Times to take this medicine:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_medicationTimes.length, (index) {
                      return Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, color: Colors.blue),
                            label: Text(_medicationTimes[index].format(context)),
                            onPressed: () => _pickTime(context, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeTime(index),
                          ),
                        ],
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      label: const Text('Add Time'),
                      onPressed: _addTime,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      labelText: 'Instructions',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note, color: Colors.teal),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPrescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Prescription',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
