class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // e.g., 'appointment', 'prescription', 'diet_plan'
  final String? relatedId; // ID of the related item (appointment, prescription, etc.)
  final String createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  // Factory constructor to create an AppNotification from a Map (e.g., from Firestore)
  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      type: data['type'] as String,
      relatedId: data['relatedId'] as String?,
      createdAt: data['createdAt'] as String,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  // Method to convert AppNotification to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
