import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in again')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
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
        actions: [
          IconButton(
            onPressed: () {
              // Create a test notification
              _firestore.collection('notifications').add({
                'userId': user.uid,
                'title': 'Test Notification',
                'message':
                    'This is a test notification to verify the system is working.',
                'type': 'appointment',
                'relatedId': 'test-123',
                'createdAt': DateTime.now().toIso8601String(),
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification created!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create test notification',
          ),
          IconButton(
            onPressed: () {
              NotificationService.markAllAsRead(user.uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50] ?? Colors.blue,
              Colors.white,
              Colors.blue[25] ?? Colors.blue,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: NotificationService.getUserNotifications(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll see notifications here when patients book appointments or take other actions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data!.docs;

            return RefreshIndicator(
              onRefresh: () async {
                // Refresh will happen automatically with StreamBuilder
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notificationData =
                      notifications[index].data() as Map<String, dynamic>;
                  final notificationId = notifications[index].id;
                  final isRead = notificationData['isRead'] as bool? ?? false;
                  final title = notificationData['title'] as String? ?? '';
                  final message = notificationData['message'] as String? ?? '';
                  final type = notificationData['type'] as String? ?? '';
                  final createdAt =
                      notificationData['createdAt'] as String? ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isRead ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isRead ? Colors.grey[50] : Colors.blue[50],
                    child: InkWell(
                      onTap: () {
                        // Mark as read when tapped
                        NotificationService.markAsRead(notificationId);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: isRead
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getNotificationTypeLabel(type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getNotificationColor(type),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  TextButton(
                                    onPressed: () {
                                      NotificationService.markAsRead(
                                          notificationId);
                                    },
                                    child: const Text(
                                      'Mark as read',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'prescription':
        return Icons.medication;
      case 'diet_plan':
        return Icons.restaurant;
      case 'appointment_reminder':
        return Icons.alarm;
      case 'doctor_appointment_reminder':
        return Icons.schedule;
      case 'profile_view':
        return Icons.person;
      case 'exercise_recommendation':
        return Icons.fitness_center;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment':
        return Colors.blue[700]!;
      case 'prescription':
        return Colors.blue[600]!;
      case 'diet_plan':
        return Colors.blue[500]!;
      case 'appointment_reminder':
        return Colors.blue[800]!;
      case 'doctor_appointment_reminder':
        return Colors.blue[700]!;
      case 'profile_view':
        return Colors.blue[600]!;
      case 'exercise_recommendation':
        return Colors.blue[500]!;
      default:
        return Colors.blue[700]!;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'appointment':
        return 'Appointment';
      case 'prescription':
        return 'Prescription';
      case 'diet_plan':
        return 'Diet Plan';
      case 'appointment_reminder':
        return 'Reminder';
      case 'doctor_appointment_reminder':
        return 'Appointment';
      case 'profile_view':
        return 'Profile';
      case 'exercise_recommendation':
        return 'Exercise';
      default:
        return 'Notification';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
