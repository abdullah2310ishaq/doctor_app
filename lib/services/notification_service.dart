import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create meal reminder notification
  static Future<void> createMealReminder({
    required String patientId,
    required String mealType,
    required String mealName,
    required String time,
    required String dietPlanId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '🍽️ Meal Time - $mealType',
        'message': 'Time for $mealName! Don\'t forget to log what you eat.',
        'type': 'meal_reminder',
        'relatedId': dietPlanId,
        'mealType': mealType.toLowerCase(),
        'mealName': mealName,
        'scheduledTime': time,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating meal reminder: $e');
    }
  }

  // Create medicine reminder notification
  static Future<void> createMedicineReminder({
    required String patientId,
    required String medicineName,
    required String dosage,
    required String time,
    required String prescriptionId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '💊 Medicine Time',
        'message': 'Time to take $medicineName ($dosage). Don\'t forget!',
        'type': 'medicine_reminder',
        'relatedId': prescriptionId,
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': time,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating medicine reminder: $e');
    }
  }

  // Create exercise reminder notification
  static Future<void> createExerciseReminder({
    required String patientId,
    required String exerciseType,
    required int remainingCount,
    required String exerciseId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '🏃‍♂️ Exercise Reminder',
        'message': 'You have $remainingCount $exerciseType sessions remaining this week!',
        'type': 'exercise_reminder',
        'relatedId': exerciseId,
        'exerciseType': exerciseType,
        'remainingCount': remainingCount,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating exercise reminder: $e');
    }
  }

  // Create weekly feedback reminder
  static Future<void> createWeeklyFeedbackReminder({
    required String patientId,
    required String weekStartDate,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': '📋 Weekly Feedback Due',
        'message': 'Please fill out your weekly health feedback form. Your doctor is waiting!',
        'type': 'weekly_feedback_reminder',
        'relatedId': weekStartDate,
        'weekStartDate': weekStartDate,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'isPersistent': true, // This will keep showing until completed
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating weekly feedback reminder: $e');
    }
  }

  // Create notification when prescription is created
  static Future<void> createPrescriptionNotification({
    required String patientId,
    required String patientName,
    required String doctorName,
    required String prescriptionId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'New Prescription Received',
        'message':
            'Dr. $doctorName has prescribed new medication for you. Please check your prescriptions.',
        'type': 'prescription',
        'relatedId': prescriptionId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating prescription notification: $e');
    }
  }

  // Create notification when diet plan is created
  static Future<void> createDietPlanNotification({
    required String patientId,
    required String patientName,
    required String doctorName,
    required String dietPlanId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'New Diet Plan Created',
        'message':
            'Dr. $doctorName has created a personalized diet plan for you. Check it out now!',
        'type': 'diet_plan',
        'relatedId': dietPlanId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating diet plan notification: $e');
    }
  }

  // Create notification when appointment is booked
  static Future<void> createAppointmentNotification({
    required String doctorId,
    required String patientName,
    required String appointmentId,
    required DateTime appointmentTime,
  }) async {
    try {
      final formattedTime =
          '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';
      final formattedDate =
          '${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}';
      
      await _firestore.collection('notifications').add({
        'userId': doctorId,
        'title': 'New Appointment Request',
        'message':
            '$patientName has requested an appointment on $formattedDate at $formattedTime. Please review and confirm.',
        'type': 'appointment',
        'relatedId': appointmentId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating appointment notification: $e');
    }
  }

  // Create notification when appointment status changes
  static Future<void> createAppointmentStatusNotification({
    required String patientId,
    required String doctorName,
    required String appointmentId,
    required String status,
    required DateTime appointmentTime,
  }) async {
    try {
      String message;
      switch (status) {
        case 'confirmed':
          message =
              'Your appointment with Dr. $doctorName on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} has been confirmed!';
          break;
        case 'cancelled':
          message =
              'Your appointment with Dr. $doctorName on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} has been cancelled.';
          break;
        case 'completed':
          message =
              'Your appointment with Dr. $doctorName has been completed. Thank you for visiting!';
          break;
        default:
          message = 'Your appointment status has been updated.';
      }

      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'Appointment ${status.toUpperCase()}',
        'message': message,
        'type': 'appointment',
        'relatedId': appointmentId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating appointment status notification: $e');
    }
  }

  // Create appointment reminder notification
  static Future<void> createAppointmentReminder({
    required String patientId,
    required String patientName,
    required String doctorName,
    required DateTime appointmentTime,
    required String appointmentId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'Appointment Reminder',
        'message':
            'Your appointment with Dr. $doctorName is scheduled for ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}.',
        'type': 'appointment_reminder',
        'relatedId': appointmentId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating appointment reminder: $e');
    }
  }

  // Create doctor appointment reminder
  static Future<void> createDoctorAppointmentReminder({
    required String doctorId,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': doctorId,
        'title': 'Upcoming Appointment',
        'message':
            'You have an appointment with $patientName on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}.',
        'type': 'doctor_appointment_reminder',
        'relatedId': appointmentId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating doctor appointment reminder: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notifications for a user with proper index
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Create notification when doctor views patient profile
  static Future<void> createProfileViewNotification({
    required String patientId,
    required String patientName,
    required String doctorName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'Profile Viewed',
        'message': 'Dr. $doctorName has viewed your profile.',
        'type': 'profile_view',
        'relatedId': null,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating profile view notification: $e');
    }
  }

  // Create notification for exercise recommendation
  static Future<void> createExerciseRecommendationNotification({
    required String patientId,
    required String patientName,
    required String doctorName,
    required String exerciseId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'title': 'New Exercise Recommendation',
        'message':
            'Dr. $doctorName has recommended new exercises for you. Check them out!',
        'type': 'exercise_recommendation',
        'relatedId': exerciseId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating exercise recommendation notification: $e');
    }
  }
}
