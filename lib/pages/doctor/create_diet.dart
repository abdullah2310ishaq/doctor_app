import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/services/notification_service.dart';

class CreateDietPlanPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onDietPlanCreated;

  const CreateDietPlanPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onDietPlanCreated,
  });

  @override
  State<CreateDietPlanPage> createState() => _CreateDietPlanPageState();
}

class _CreateDietPlanPageState extends State<CreateDietPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _restrictionsController = TextEditingController();
  final _guidelinesController = TextEditingController();
  bool _isLoading = false;

  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimePicked) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimePicked(picked);
    }
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _restrictionsController.dispose();
    _guidelinesController.dispose();
    super.dispose();
  }

  void _createDietPlan() async {
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

      final dietPlanRef = await _firestore.collection('diet_plans').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'meals': [
          {
            'type': 'Breakfast',
            'name': _breakfastController.text.trim(),
            'description': _breakfastController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': _breakfastTime.format(context),
          },
          {
            'type': 'Lunch',
            'name': _lunchController.text.trim(),
            'description': _lunchController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': _lunchTime.format(context),
          },
          {
            'type': 'Dinner',
            'name': _dinnerController.text.trim(),
            'description': _dinnerController.text.trim(),
            'portionSize': '1 serving',
            'ingredients': [],
            'time': _dinnerTime.format(context),
          },
        ],
        'restrictions': _restrictionsController.text.trim().split(','),
        'nutritionGuidelines': _guidelinesController.text.trim(),
        'additionalInstructions': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createDietPlanNotification(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        dietPlanId: dietPlanRef.id,
      );

      if (!mounted) return;
      widget.onDietPlanCreated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating diet plan: $e')),
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
          'Diet Plan for ${widget.patientName}',
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
                    'Diet Plan Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _breakfastController,
                          decoration: InputDecoration(
                            labelText: 'Breakfast',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.breakfast_dining,
                                color: Colors.blue),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter breakfast details';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, color: Colors.blue),
                        label: Text(_breakfastTime.format(context)),
                        onPressed: () => _pickTime(context, _breakfastTime, (picked) {
                          setState(() {
                            _breakfastTime = picked;
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lunchController,
                          decoration: InputDecoration(
                            labelText: 'Lunch',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon:
                                const Icon(Icons.lunch_dining, color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, color: Colors.blue),
                        label: Text(_lunchTime.format(context)),
                        onPressed: () => _pickTime(context, _lunchTime, (picked) {
                          setState(() {
                            _lunchTime = picked;
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dinnerController,
                          decoration: InputDecoration(
                            labelText: 'Dinner',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon:
                                const Icon(Icons.dinner_dining, color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, color: Colors.blue),
                        label: Text(_dinnerTime.format(context)),
                        onPressed: () => _pickTime(context, _dinnerTime, (picked) {
                          setState(() {
                            _dinnerTime = picked;
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restrictionsController,
                    decoration: InputDecoration(
                      labelText: 'Restrictions (comma separated)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.block, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guidelinesController,
                    decoration: InputDecoration(
                      labelText: 'Nutrition Guidelines',
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
                      onPressed: _isLoading ? null : _createDietPlan,
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
                              'Create Diet Plan',
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
