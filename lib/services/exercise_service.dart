import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all exercise categories
  List<ExerciseCategory> getCategories() {
    return [
      ExerciseCategory(
        id: 'cardio',
        name: 'Cardio',
        description: 'Cardiovascular exercises for heart health',
        icon: 'fitness_center',
        color: '#FF6B6B',
      ),
      ExerciseCategory(
        id: 'strength',
        name: 'Strength Training',
        description: 'Muscle building and strength exercises',
        icon: 'fitness_center',
        color: '#4ECDC4',
      ),
      ExerciseCategory(
        id: 'flexibility',
        name: 'Flexibility',
        description: 'Stretching and flexibility exercises',
        icon: 'accessibility',
        color: '#45B7D1',
      ),
      ExerciseCategory(
        id: 'balance',
        name: 'Balance',
        description: 'Balance and coordination exercises',
        icon: 'balance',
        color: '#96CEB4',
      ),
      ExerciseCategory(
        id: 'rehabilitation',
        name: 'Rehabilitation',
        description: 'Recovery and rehabilitation exercises',
        icon: 'healing',
        color: '#FFEAA7',
      ),
    ];
  }

  // Get all exercises
  List<Exercise> getAllExercises() {
    return [
      Exercise(
        id: 'walking',
        title: 'Walking',
        description: 'Low-impact cardiovascular exercise',
        category: 'cardio',
        videoUrl:
            'https://www.youtube.com/watch?v=GIz1C3yfE1s&list=PLWplBfOD_MWjL9TUfMzprF159PpoUwzc4&pp=gAQB',
        imageUrl: 'https://example.com/walking.jpg',
        difficulty: 'Beginner',
        duration: 30,
        benefits: [
          'Improves heart health',
          'Increases stamina',
          'Burns calories'
        ],
        instructions: [
          'Start with 10-15 minutes',
          'Gradually increase duration',
          'Maintain good posture'
        ],
      ),
      Exercise(
        id: 'jogging',
        title: 'Jogging',
        description: 'Moderate cardiovascular exercise',
        category: 'cardio',
        videoUrl: 'https://www.youtube.com/watch?v=example2',
        imageUrl: 'https://example.com/jogging.jpg',
        difficulty: 'Intermediate',
        duration: 20,
        benefits: [
          'Improves cardiovascular fitness',
          'Strengthens muscles',
          'Boosts mood'
        ],
        instructions: [
          'Warm up properly',
          'Start slowly',
          'Listen to your body'
        ],
      ),
      Exercise(
        id: 'push_ups',
        title: 'Push-ups',
        description: 'Upper body strength exercise',
        category: 'strength',
        videoUrl: 'https://www.youtube.com/watch?v=example3',
        imageUrl: 'https://example.com/pushups.jpg',
        difficulty: 'Intermediate',
        duration: 10,
        benefits: [
          'Builds chest muscles',
          'Strengthens arms',
          'Improves core stability'
        ],
        instructions: [
          'Keep body straight',
          'Lower chest to ground',
          'Push back up'
        ],
      ),
      Exercise(
        id: 'squats',
        title: 'Squats',
        description: 'Lower body strength exercise',
        category: 'strength',
        videoUrl: 'https://www.youtube.com/watch?v=example4',
        imageUrl: 'https://example.com/squats.jpg',
        difficulty: 'Beginner',
        duration: 15,
        benefits: ['Strengthens legs', 'Improves balance', 'Burns calories'],
        instructions: [
          'Feet shoulder-width apart',
          'Lower hips back',
          'Keep knees behind toes'
        ],
      ),
      Exercise(
        id: 'stretching',
        title: 'Stretching',
        description: 'Flexibility and mobility exercises',
        category: 'flexibility',
        videoUrl:
            'https://www.youtube.com/watch?v=VwSRo8kdjeg&list=PLWplBfOD_MWhtF_9r-z3soDDkylC62K8k&pp=gAQB',
        imageUrl: 'https://example.com/stretching.jpg',
        difficulty: 'Beginner',
        duration: 15,
        benefits: [
          'Improves flexibility',
          'Reduces muscle tension',
          'Prevents injury'
        ],
        instructions: [
          'Hold each stretch 30 seconds',
          'Don\'t bounce',
          'Breathe deeply'
        ],
      ),
      Exercise(
        id: 'yoga',
        title: 'Yoga',
        description: 'Mind-body exercise for flexibility and strength',
        category: 'flexibility',
        videoUrl:
            'https://www.youtube.com/watch?v=VwSRo8kdjeg&list=PLWplBfOD_MWhtF_9r-z3soDDkylC62K8k&pp=gAQB',
        imageUrl: 'https://example.com/yoga.jpg',
        difficulty: 'Beginner',
        duration: 45,
        benefits: [
          'Improves flexibility',
          'Reduces stress',
          'Increases mindfulness'
        ],
        instructions: [
          'Start with basic poses',
          'Focus on breathing',
          'Listen to your body'
        ],
      ),
      Exercise(
        id: 'balance_exercises',
        title: 'Balance Exercises',
        description: 'Improves stability and coordination',
        category: 'balance',
        videoUrl:
            'https://www.youtube.com/watch?v=gJdl-MNMxlY&list=PLWplBfOD_MWgkWFkDuyIg3C1ZQ49auzMO&pp=gAQB',
        imageUrl: 'https://example.com/balance.jpg',
        difficulty: 'Beginner',
        duration: 20,
        benefits: [
          'Improves balance',
          'Prevents falls',
          'Enhances coordination'
        ],
        instructions: [
          'Start near a wall',
          'Focus on posture',
          'Gradually increase difficulty'
        ],
      ),
      Exercise(
        id: 'physical_therapy',
        title: 'Physical Therapy Exercises',
        description: 'Rehabilitation and recovery exercises',
        category: 'rehabilitation',
        videoUrl: 'https://www.youtube.com/watch?v=example8',
        imageUrl: 'https://example.com/pt.jpg',
        difficulty: 'Beginner',
        duration: 30,
        benefits: ['Aids recovery', 'Reduces pain', 'Improves mobility'],
        instructions: [
          'Follow therapist guidance',
          'Start slowly',
          'Monitor progress'
        ],
      ),
    ];
  }

  // Get recommended exercises based on patient data
  List<Exercise> getRecommendedExercises(Map<String, dynamic> patientData) {
    final allExercises = getAllExercises();
    final recommendations = <Exercise>[];

    // Basic recommendations based on common health conditions
    final age = patientData['age'] ?? 30;
    final healthConditions = patientData['healthConditions'] ?? <String>[];
    final activityLevel = patientData['activityLevel'] ?? 'moderate';

    // Always include walking for cardiovascular health
    recommendations.add(allExercises.firstWhere((e) => e.id == 'walking'));

    // Add stretching for flexibility
    recommendations.add(allExercises.firstWhere((e) => e.id == 'stretching'));

    // Add balance exercises for older adults
    if (age > 50) {
      recommendations
          .add(allExercises.firstWhere((e) => e.id == 'balance_exercises'));
    }

    // Add strength training for active individuals
    if (activityLevel == 'active' || activityLevel == 'very_active') {
      recommendations.add(allExercises.firstWhere((e) => e.id == 'squats'));
    }

    // Add rehabilitation exercises if needed
    if (healthConditions.contains('injury') ||
        healthConditions.contains('surgery')) {
      recommendations
          .add(allExercises.firstWhere((e) => e.id == 'physical_therapy'));
    }

    return recommendations;
  }

  // Get exercise by ID
  Exercise? getExerciseById(String id) {
    final allExercises = getAllExercises();
    try {
      return allExercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create exercise recommendation
  Future<void> createExerciseRecommendation(
      ExerciseRecommendation recommendation) async {
    try {
      await _firestore
          .collection('exercise_recommendations')
          .add(recommendation.toMap());
    } catch (e) {
      throw Exception('Failed to create exercise recommendation: $e');
    }
  }

  // Get patient exercise recommendations
  Future<List<ExerciseRecommendation>> getPatientExerciseRecommendations(
      String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercise_recommendations')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseRecommendation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exercise recommendations: $e');
    }
  }

  // Update exercise recommendation completion status
  Future<void> updateExerciseRecommendationCompletion(
    String recommendationId,
    bool isCompleted,
    DateTime? completedAt,
  ) async {
    try {
      await _firestore
          .collection('exercise_recommendations')
          .doc(recommendationId)
          .update({
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update exercise recommendation: $e');
    }
  }
}
