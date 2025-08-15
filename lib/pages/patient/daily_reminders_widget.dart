import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/diet_plan.dart';
import '../../models/prescription.dart';

class DailyRemindersWidget extends StatefulWidget {
  const DailyRemindersWidget({super.key});

  @override
  State<DailyRemindersWidget> createState() => _DailyRemindersWidgetState();
}

class _DailyRemindersWidgetState extends State<DailyRemindersWidget> {
  DietPlan? _todayDietPlan;
  Prescription? _todayPrescription;
  bool _plansLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayPlans();
  }

  Future<void> _loadTodayPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      // Load today's diet plan
      final dietSnapshot = await FirebaseFirestore.instance
          .collection('diet_plans')
          .where('patientId', isEqualTo: user.uid)
          .where('startDate', isLessThanOrEqualTo: todayStr)
          .where('endDate', isGreaterThanOrEqualTo: todayStr)
          .limit(1)
          .get();

      if (dietSnapshot.docs.isNotEmpty) {
        final data = dietSnapshot.docs.first.data();
        data['id'] = dietSnapshot.docs.first.id;
        _todayDietPlan = DietPlan.fromJson(data);
      }

      // Load today's prescription
      final prescriptionSnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();

      if (prescriptionSnapshot.docs.isNotEmpty) {
        final data = prescriptionSnapshot.docs.first.data();
        data['id'] = prescriptionSnapshot.docs.first.id;
        _todayPrescription = Prescription.fromJson(data);
      }

      setState(() {
        _plansLoading = false;
      });
    } catch (e) {
      print('Error loading today\'s plans: $e');
      setState(() {
        _plansLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: Colors.orange[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'Today\'s Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Today's Meal Plan
            if (_todayDietPlan != null && _todayDietPlan!.meals.isNotEmpty)
              _buildMealPlanSection(),

            SizedBox(height: 12),

            // Today's Medication Plan
            if (_todayPrescription != null &&
                _todayPrescription!.medications.isNotEmpty)
              _buildMedicationPlanSection(),

            SizedBox(height: 12),

            // Existing Reminders
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('isImmediate', isEqualTo: true)
                  .where('isRead', isEqualTo: false)
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[600], size: 48),
                      SizedBox(height: 8),
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'No pending reminders for today',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] ?? '';
                    final title = data['title'] ?? '';
                    final message = data['message'] ?? '';
                    final scheduledTime = data['scheduledTime'] ?? '';

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getReminderColor(type),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _getReminderBorderColor(type)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getReminderIcon(type),
                            color: _getReminderIconColor(type),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  message,
                                  style: TextStyle(fontSize: 11),
                                ),
                                if (scheduledTime.isNotEmpty)
                                  Text(
                                    'Time: $scheduledTime',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await doc.reference.update({'isRead': true});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reminder marked as read'),
                                  backgroundColor: Colors.green[600],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(Icons.check,
                                color: Colors.green[600], size: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orange[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Today\'s Meals',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ..._todayDietPlan!.meals
              .map((meal) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${meal.type.toUpperCase()}: ${meal.name}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        if (meal.time != null)
                          Text(
                            meal.time!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildMedicationPlanSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.red[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Today\'s Medications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ..._todayPrescription!.medications
              .map((med) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${med.name} - ${med.dosage}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        if (med.times != null && med.times!.isNotEmpty)
                          Text(
                            med.times!.join(', '),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Color _getReminderColor(String type) {
    switch (type) {
      case 'meal_reminder':
        return Colors.orange[50]!;
      case 'medicine_reminder':
        return Colors.red[50]!;
      case 'exercise_reminder':
        return Colors.green[50]!;
      case 'weekly_feedback_reminder':
        return Colors.blue[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getReminderBorderColor(String type) {
    switch (type) {
      case 'meal_reminder':
        return Colors.orange[200]!;
      case 'medicine_reminder':
        return Colors.red[200]!;
      case 'exercise_reminder':
        return Colors.green[200]!;
      case 'weekly_feedback_reminder':
        return Colors.blue[200]!;
      default:
        return Colors.grey[200]!;
    }
  }

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'meal_reminder':
        return Icons.restaurant;
      case 'medicine_reminder':
        return Icons.medication;
      case 'exercise_reminder':
        return Icons.fitness_center;
      case 'weekly_feedback_reminder':
        return Icons.feedback;
      default:
        return Icons.notifications;
    }
  }

  Color _getReminderIconColor(String type) {
    switch (type) {
      case 'meal_reminder':
        return Colors.orange[600]!;
      case 'medicine_reminder':
        return Colors.red[600]!;
      case 'exercise_reminder':
        return Colors.green[600]!;
      case 'weekly_feedback_reminder':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
