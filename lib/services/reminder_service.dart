import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // Added for BuildContext

class ReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== DAILY MEAL REMINDERS ==========

  static Future<void> createDailyMealReminders(String patientId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != patientId) return;

    try {
      // Get today's diet plan
      final dietSnapshot = await _firestore
          .collection('diet_plans')
          .where('patientId', isEqualTo: patientId)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (dietSnapshot.docs.isEmpty) return;

      final dietPlan = dietSnapshot.docs.first.data();
      final meals = dietPlan['meals'] as List? ?? [];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Create reminders for each meal with timing
      for (var mealData in meals) {
        final meal = mealData as Map<String, dynamic>;
        final mealType = meal['type'] ?? 'meal';
        final mealName = meal['name'] ?? 'Meal';
        final mealTime = meal['time'] ?? _getDefaultMealTime(mealType);

        await _createMealReminder(
          patientId: patientId,
          mealType: mealType,
          mealName: mealName,
          scheduledTime: mealTime,
          reminderDate: today,
        );
      }
    } catch (e) {
      print('Error creating daily meal reminders: $e');
    }
  }

  static String _getDefaultMealTime(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '08:00';
      case 'lunch':
        return '12:00';
      case 'dinner':
        return '19:00';
      case 'snack':
        return '15:00';
      default:
        return '12:00';
    }
  }

  static Future<void> _createMealReminder({
    required String patientId,
    required String mealType,
    required String mealName,
    required String scheduledTime,
    required String reminderDate,
  }) async {
    try {
      // Check if reminder already exists for today
      final existingReminder = await _firestore
          .collection('daily_reminders')
          .where('patientId', isEqualTo: patientId)
          .where('type', isEqualTo: 'meal')
          .where('mealType', isEqualTo: mealType)
          .where('reminderDate', isEqualTo: reminderDate)
          .limit(1)
          .get();

      if (existingReminder.docs.isNotEmpty) return;

      // Create new meal reminder
      await _firestore.collection('daily_reminders').add({
        'patientId': patientId,
        'type': 'meal',
        'mealType': mealType,
        'mealName': mealName,
        'scheduledTime': scheduledTime,
        'reminderDate': reminderDate,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create immediate notification
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '🍽️ Meal Time - ${mealType.toUpperCase()}',
        'message':
            'Time for $mealName at $scheduledTime! Don\'t forget to log what you eat.',
        'type': 'meal_reminder',
        'mealType': mealType.toLowerCase(),
        'mealName': mealName,
        'scheduledTime': scheduledTime,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'isImmediate': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating meal reminder: $e');
    }
  }

  // ========== DAILY MEDICINE REMINDERS ==========

  static Future<void> createDailyMedicineReminders(String patientId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != patientId) return;

    try {
      // Get active prescriptions
      final prescriptionSnapshot = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (prescriptionSnapshot.docs.isEmpty) return;

      final prescription = prescriptionSnapshot.docs.first.data();
      final medications = prescription['medications'] as List? ?? [];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Create reminders for each medicine with timing
      for (var medicationData in medications) {
        final medication = medicationData as Map<String, dynamic>;
        final medicineName = medication['name'] ?? 'Medicine';
        final dosage = medication['dosage'] ?? '';
        final times = medication['times'] as List? ?? [];

        for (var time in times) {
          await _createMedicineReminder(
            patientId: patientId,
            medicineName: medicineName,
            dosage: dosage,
            scheduledTime: time.toString(),
            reminderDate: today,
          );
        }
      }
    } catch (e) {
      print('Error creating daily medicine reminders: $e');
    }
  }

  static Future<void> _createMedicineReminder({
    required String patientId,
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    required String reminderDate,
  }) async {
    try {
      // Check if reminder already exists for today
      final existingReminder = await _firestore
          .collection('daily_reminders')
          .where('patientId', isEqualTo: patientId)
          .where('type', isEqualTo: 'medicine')
          .where('medicineName', isEqualTo: medicineName)
          .where('scheduledTime', isEqualTo: scheduledTime)
          .where('reminderDate', isEqualTo: reminderDate)
          .limit(1)
          .get();

      if (existingReminder.docs.isNotEmpty) return;

      // Create new medicine reminder
      await _firestore.collection('daily_reminders').add({
        'patientId': patientId,
        'type': 'medicine',
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': scheduledTime,
        'reminderDate': reminderDate,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create immediate notification
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '💊 Medicine Time',
        'message': 'Time to take $medicineName ($dosage) at $scheduledTime!',
        'type': 'medicine_reminder',
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': scheduledTime,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'isImmediate': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating medicine reminder: $e');
    }
  }

  // ========== WEEKLY EXERCISE REMINDERS ==========

  static Future<void> createWeeklyExerciseReminders(String patientId) async {
    // Exercise reminders temporarily disabled to prevent login notifications
    return;
  }

  static Future<int> _getWeeklyExerciseCount(
      String patientId, String exerciseId, String weekStart) async {
    try {
      final weekEnd = DateTime.parse(weekStart).add(Duration(days: 7));
      final weekEndStr = DateFormat('yyyy-MM-dd').format(weekEnd);

      final logsSnapshot = await _firestore
          .collection('exercise_logs')
          .where('patientId', isEqualTo: patientId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .where('date', isLessThan: weekEndStr)
          .where('completed', isEqualTo: true)
          .get();

      return logsSnapshot.docs.length;
    } catch (e) {
      print('Error getting weekly exercise count: $e');
      return 0;
    }
  }

  static Future<void> _createExerciseReminder({
    required String patientId,
    required String exerciseId,
    required int remainingCount,
    required int targetCount,
    required String weekStart,
  }) async {
    try {
      // Get exercise details
      final exerciseDoc =
          await _firestore.collection('exercises').doc(exerciseId).get();
      final exerciseName = exerciseDoc.exists
          ? exerciseDoc.data() != null
              ? exerciseDoc.data()!['title']
              : 'Exercise'
          : 'Exercise';

      // Check if reminder already exists for this week
      final existingReminder = await _firestore
          .collection('weekly_reminders')
          .where('patientId', isEqualTo: patientId)
          .where('type', isEqualTo: 'exercise')
          .where('exerciseId', isEqualTo: exerciseId)
          .where('weekStart', isEqualTo: weekStart)
          .limit(1)
          .get();

      if (existingReminder.docs.isNotEmpty) {
        // Update existing reminder
        await existingReminder.docs.first.reference.update({
          'remainingCount': remainingCount,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new exercise reminder
        await _firestore.collection('weekly_reminders').add({
          'patientId': patientId,
          'type': 'exercise',
          'exerciseId': exerciseId,
          'exerciseName': exerciseName,
          'remainingCount': remainingCount,
          'targetCount': targetCount,
          'weekStart': weekStart,
          'createdAt': DateTime.now().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Create immediate notification
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '🏃‍♂️ Exercise Reminder',
        'message':
            'You have $remainingCount $exerciseName sessions remaining this week!',
        'type': 'exercise_reminder',
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'remainingCount': remainingCount,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'isImmediate': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating exercise reminder: $e');
    }
  }

  // ========== PERSISTENT WEEKLY FEEDBACK REMINDERS ==========

  static Future<void> createWeeklyFeedbackReminder(String patientId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != patientId) return;

    try {
      final weekStart = _getWeekStart(DateTime.now());
      final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);

      // Check if feedback already submitted for this week
      final feedbackSnapshot = await _firestore
          .collection('weekly_feedback')
          .where('patientId', isEqualTo: patientId)
          .where('weekStart', isEqualTo: weekStartStr)
          .limit(1)
          .get();

      if (feedbackSnapshot.docs.isNotEmpty) {
        // Feedback already submitted, remove any existing reminders
        await _removeWeeklyFeedbackReminders(patientId, weekStartStr);
        return;
      }

      // Check if reminder already exists
      final existingReminder = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: patientId)
          .where('type', isEqualTo: 'weekly_feedback_reminder')
          .where('weekStartDate', isEqualTo: weekStartStr)
          .limit(1)
          .get();

      if (existingReminder.docs.isEmpty) {
        // Create persistent weekly feedback reminder
        await _firestore.collection('notifications').add({
          'userId': patientId,
          'title': '📋 Weekly Feedback Due',
          'message':
              'Please fill out your weekly health feedback form. Your doctor is waiting!',
          'type': 'weekly_feedback_reminder',
          'relatedId': weekStartStr,
          'weekStartDate': weekStartStr,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'isPersistent': true,
          'isImmediate': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating weekly feedback reminder: $e');
    }
  }

  static Future<void> _removeWeeklyFeedbackReminders(
      String patientId, String weekStart) async {
    try {
      final reminders = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: patientId)
          .where('type', isEqualTo: 'weekly_feedback_reminder')
          .where('weekStartDate', isEqualTo: weekStart)
          .get();

      final batch = _firestore.batch();
      for (var doc in reminders.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error removing weekly feedback reminders: $e');
    }
  }

  // ========== MASTER REMINDER SCHEDULER ==========

  static Future<void> scheduleAllDailyReminders(String patientId) async {
    await Future.wait([
      createDailyMealReminders(patientId),
      createDailyMedicineReminders(patientId),
    ]);
  }

  static Future<void> scheduleAllWeeklyReminders(String patientId) async {
    await Future.wait([
      createWeeklyExerciseReminders(patientId),
      createWeeklyFeedbackReminder(patientId),
    ]);
  }

  static Future<void> scheduleAllReminders(String patientId) async {
    await Future.wait([
      scheduleAllDailyReminders(patientId),
      scheduleAllWeeklyReminders(patientId),
    ]);
  }

  // ========== UTILITY METHODS ==========

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  // Mark reminder as completed
  static Future<void> markReminderCompleted(
      String reminderId, String type) async {
    try {
      if (type == 'daily') {
        await _firestore.collection('daily_reminders').doc(reminderId).update({
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        });
      } else if (type == 'weekly') {
        await _firestore.collection('weekly_reminders').doc(reminderId).update({
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error marking reminder as completed: $e');
    }
  }

  // Get today's reminders for patient
  static Stream<QuerySnapshot> getTodaysReminders(String patientId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _firestore
        .collection('daily_reminders')
        .where('patientId', isEqualTo: patientId)
        .where('reminderDate', isEqualTo: today)
        .where('isCompleted', isEqualTo: false)
        .orderBy('scheduledTime')
        .snapshots();
  }

  // Get this week's exercise reminders
  static Stream<QuerySnapshot> getWeeklyExerciseReminders(String patientId) {
    final weekStart =
        DateFormat('yyyy-MM-dd').format(_getWeekStart(DateTime.now()));
    return _firestore
        .collection('weekly_reminders')
        .where('patientId', isEqualTo: patientId)
        .where('type', isEqualTo: 'exercise')
        .where('weekStart', isEqualTo: weekStart)
        .snapshots();
  }

  // Get all daily reminders for patient (stream version for UI)
  static Stream<List<Map<String, dynamic>>> getDailyReminders(
      String patientId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _firestore
        .collection('daily_reminders')
        .where('patientId', isEqualTo: patientId)
        .where('reminderDate', isEqualTo: today)
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Mark any reminder as completed (simplified interface)
  static Future<void> markAsCompleted(
      String reminderId, BuildContext context) async {
    try {
      // First try daily reminders
      final dailyDoc =
          await _firestore.collection('daily_reminders').doc(reminderId).get();
      if (dailyDoc.exists) {
        await _firestore.collection('daily_reminders').doc(reminderId).update({
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        });
        return;
      }

      // Then try weekly reminders
      final weeklyDoc =
          await _firestore.collection('weekly_reminders').doc(reminderId).get();
      if (weeklyDoc.exists) {
        await _firestore.collection('weekly_reminders').doc(reminderId).update({
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        });
        return;
      }

      // Finally try notifications
      final notificationDoc =
          await _firestore.collection('notifications').doc(reminderId).get();
      if (notificationDoc.exists) {
        await _firestore.collection('notifications').doc(reminderId).update({
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Error marking reminder as completed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error completing reminder')),
        );
      }
    }
  }
}
