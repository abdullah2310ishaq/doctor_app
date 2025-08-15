import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/models/vital_reading.dart';
import 'package:intl/intl.dart';

class BPSugarInputWidget extends StatefulWidget {
  const BPSugarInputWidget({Key? key}) : super(key: key);

  @override
  State<BPSugarInputWidget> createState() => _BPSugarInputWidgetState();
}

class _BPSugarInputWidgetState extends State<BPSugarInputWidget> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _sugarController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _sugarController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReading() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reading = VitalReading(
        id: '',
        patientId: user.uid,
        systolicBP: _systolicController.text.isNotEmpty
            ? double.tryParse(_systolicController.text)
            : null,
        diastolicBP: _diastolicController.text.isNotEmpty
            ? double.tryParse(_diastolicController.text)
            : null,
        sugarLevel: _sugarController.text.isNotEmpty
            ? double.tryParse(_sugarController.text)
            : null,
        recordedAt: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await _firestore.collection('vital_readings').add(reading.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vital signs recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _systolicController.clear();
    _diastolicController.clear();
    _sugarController.clear();
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: Colors.red[600], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Record Vitals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Blood Pressure Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blood Pressure (mmHg)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _systolicController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Systolic',
                                  hintText: '120',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final number = double.tryParse(value);
                                    if (number == null ||
                                        number < 60 ||
                                        number > 250) {
                                      return 'Enter valid systolic BP (60-250)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('/',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _diastolicController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Diastolic',
                                  hintText: '80',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final number = double.tryParse(value);
                                    if (number == null ||
                                        number < 40 ||
                                        number > 150) {
                                      return 'Enter valid diastolic BP (40-150)';
                                    }
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
                  const SizedBox(height: 12),
                  // Sugar Level Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blood Sugar Level (mg/dL)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sugarController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Sugar Level',
                            hintText: '100',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final number = double.tryParse(value);
                              if (number == null ||
                                  number < 50 ||
                                  number > 600) {
                                return 'Enter valid sugar level (50-600)';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes Section
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any additional notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitReading,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Recording...' : 'Record Vitals',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
