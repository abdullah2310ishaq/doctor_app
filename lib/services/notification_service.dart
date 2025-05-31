import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
        'message': 'Dr. $doctorName has prescribed new medication for you. Please check your prescriptions.',
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
        'message': 'Dr. $doctorName has created a personalized diet plan for you. Check it out now!',
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
      await _firestore.collection('notifications').add({
        'userId': doctorId,
        'title': 'New Appointment Request',
        'message': '$patientName has requested an appointment on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}. Please review.',
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
          message = 'Your appointment with Dr. $doctorName on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} has been confirmed!';
          break;
        case 'cancelled':
          message = 'Your appointment with Dr. $doctorName on ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} has been cancelled.';
          break;
        case 'completed':
          message = 'Your appointment with Dr. $doctorName has been completed. Thank you for visiting!';
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

  // FIXED: Get notifications for a user with proper index
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
