class Exercise {
  final String id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String imageUrl;
  final String difficulty;
  final int duration; // in minutes
  final List<String> benefits;
  final List<String> instructions;
  final bool isRecommended;

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.imageUrl,
    required this.difficulty,
    required this.duration,
    required this.benefits,
    required this.instructions,
    this.isRecommended = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'duration': duration,
      'benefits': benefits,
      'instructions': instructions,
      'isRecommended': isRecommended,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      difficulty: map['difficulty'] ?? '',
      duration: map['duration']?.toInt() ?? 0,
      benefits: List<String>.from(map['benefits'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      isRecommended: map['isRecommended'] ?? false,
    );
  }
}

class ExerciseCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  ExerciseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ExerciseRecommendation {
  final String patientId;
  final String patientName;
  final List<String> exerciseIds;
  final String notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final Map<String, int>? frequencyPerWeek; // exerciseId: times per week

  ExerciseRecommendation({
    required this.patientId,
    required this.patientName,
    required this.exerciseIds,
    required this.notes,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.frequencyPerWeek,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'exerciseIds': exerciseIds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'frequencyPerWeek': frequencyPerWeek,
    };
  }

  factory ExerciseRecommendation.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    try {
      createdAt =
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime? completedAt;
    if (map['completedAt'] != null) {
      try {
        completedAt = DateTime.parse(map['completedAt']);
      } catch (e) {
        completedAt = null;
      }
    }

    Map<String, int>? freqMap;
    if (map['frequencyPerWeek'] != null) {
      freqMap = Map<String, int>.from(map['frequencyPerWeek']);
    }

    return ExerciseRecommendation(
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      notes: map['notes'] ?? '',
      createdAt: createdAt,
      completedAt: completedAt,
      isCompleted: map['isCompleted'] ?? false,
      frequencyPerWeek: freqMap,
    );
  }
}

class ExerciseLog {
  final String exerciseId;
  final DateTime date;
  final bool completed;
  final String? notes;

  ExerciseLog({
    required this.exerciseId,
    required this.date,
    required this.completed,
    this.notes,
  });

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseId: map['exerciseId'],
      date: DateTime.parse(map['date']),
      completed: map['completed'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'date': date.toIso8601String(),
      'completed': completed,
      'notes': notes,
    };
  }
}
