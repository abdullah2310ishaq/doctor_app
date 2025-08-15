import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';

class PatientExercisePage extends StatefulWidget {
  const PatientExercisePage({super.key});

  @override
  State<PatientExercisePage> createState() => _PatientExercisePageState();
}

class _PatientExercisePageState extends State<PatientExercisePage> {
  final ExerciseService _exerciseService = ExerciseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ExerciseRecommendation> _recommendations = [];
  Map<String, int> _weeklyProgress = {};
  Map<String, Exercise> _exercises = {};
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _loadExerciseData();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadExerciseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      final recSnapshot = await _firestore
          .collection('exercise_recommendations')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      List<ExerciseRecommendation> recommendations = [];
      Set<String> allExerciseIds = {};

      for (var doc in recSnapshot.docs) {
        final rec = ExerciseRecommendation.fromMap(doc.data());
        recommendations.add(rec);
        allExerciseIds.addAll(rec.exerciseIds);
      }

      Map<String, Exercise> exercises = {};
      for (String exerciseId in allExerciseIds) {
        final exercise = await _exerciseService.getExerciseById(exerciseId);
        if (exercise != null) {
          exercises[exerciseId] = exercise;
        }
      }

      await _loadWeeklyProgress(user.uid, allExerciseIds.toList());

      setState(() {
        _recommendations = recommendations;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading exercise data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyProgress(
      String patientId, List<String> exerciseIds) async {
    final weekEnd = _currentWeekStart.add(Duration(days: 7));

    try {
      final logsSnapshot = await _firestore
          .collection('exercise_logs')
          .where('patientId', isEqualTo: patientId)
          .where('date',
              isGreaterThanOrEqualTo: _currentWeekStart.toIso8601String())
          .where('date', isLessThan: weekEnd.toIso8601String())
          .get();

      Map<String, int> progress = {};
      for (String exerciseId in exerciseIds) {
        progress[exerciseId] = 0;
      }

      for (var doc in logsSnapshot.docs) {
        final log = ExerciseLog.fromMap(doc.data());
        if (log.completed && progress.containsKey(log.exerciseId)) {
          progress[log.exerciseId] = progress[log.exerciseId]! + 1;
        }
      }

      setState(() {
        _weeklyProgress = progress;
      });
    } catch (e) {
      print('Error loading weekly progress: $e');
    }
  }

  Future<void> _logExerciseCompletion(
      String exerciseId, Exercise exercise) async {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => _buildExerciseLogDialog(exerciseId, exercise),
    );
  }

  Widget _buildExerciseLogDialog(String exerciseId, Exercise exercise) {
    String difficulty = 'Normal';
    String notes = '';
    bool completed = true;

    final difficultyOptions = [
      'Very Easy',
      'Easy',
      'Normal',
      'Hard',
      'Very Hard'
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title:
          Text('Log Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${exercise.duration} min • ${exercise.difficulty}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 16),
            Text('Did you complete this exercise?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<bool>(
              title: Text('Yes, I completed it'),
              value: true,
              groupValue: completed,
              onChanged: (value) => setState(() => completed = value!),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              title: Text('No, I couldn\'t complete it'),
              value: false,
              groupValue: completed,
              onChanged: (value) => setState(() => completed = value!),
              contentPadding: EdgeInsets.zero,
            ),
            if (completed) ...[
              SizedBox(height: 16),
              Text('How difficult was it?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: difficulty,
                isExpanded: true,
                items: difficultyOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => difficulty = value!),
              ),
            ],
            SizedBox(height: 16),
            Text('Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              onChanged: (value) => notes = value,
              decoration: InputDecoration(
                hintText: completed
                    ? 'How did you feel?'
                    : 'What prevented you from completing?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _saveExerciseLog(
                exerciseId, exercise, completed, difficulty, notes);
          },
          child: Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveExerciseLog(
    String exerciseId,
    Exercise exercise,
    bool completed,
    String difficulty,
    String notes,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final log = {
      'patientId': user.uid,
      'exerciseId': exerciseId,
      'exerciseTitle': exercise.title,
      'date': DateTime.now().toIso8601String(),
      'completed': completed,
      'difficulty': completed ? difficulty : null,
      'notes': notes.isEmpty ? null : notes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _firestore.collection('exercise_logs').add(log);
      // Get doctor ID for notification
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        doctorId = userDoc.data()?['assignedDoctorId'];

        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          doctorId = patientDoc.data()?['assignedDoctorId'];
        }
      } catch (e) {
        print('Could not get doctor ID for notification: $e');
      }

      if (doctorId != null) {
        await _firestore.collection('notifications').add({
          'userId': doctorId,
          'title': completed ? 'Exercise Completed' : 'Exercise Not Completed',
          'message':
              'Patient ${completed ? 'completed' : 'did not complete'} ${exercise.title}.',
          'type': 'exercise_log_update',
          'relatedId': exerciseId,
          'patientId': user.uid,
          'exerciseTitle': exercise.title,
          'completed': completed,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise log saved!')),
      );

      await _loadWeeklyProgress(user.uid, _exercises.keys.toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving log: $e')),
      );
    }
  }

  Future<void> _launchVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Plan'),
        backgroundColor: Colors.blue,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final padding = isWideScreen ? 24.0 : 16.0;

          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExerciseData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExerciseVideoCategories(
                    isWideScreen, constraints.maxWidth),
                SizedBox(height: padding),
                if (_recommendations.isNotEmpty) ...[
                  _buildWeeklyProgressSection(isWideScreen),
                  SizedBox(height: padding),
                  _buildExerciseRecommendationsSection(isWideScreen),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isWideScreen ? 16 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Exercise Plan',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Text(
                            'No exercise plan assigned yet. Your doctor will assign one soon.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Meanwhile, you can use the exercise videos above to stay active!',
                            style: TextStyle(
                                color: Colors.blue[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyProgressSection(bool isWideScreen) {
    final weekStart = DateFormat('MMM dd').format(_currentWeekStart);
    final weekEnd =
        DateFormat('MMM dd').format(_currentWeekStart.add(Duration(days: 6)));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Progress ($weekStart - $weekEnd)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ..._weeklyProgress.entries.map((entry) {
              final exercise = _exercises[entry.key];
              if (exercise == null) return SizedBox.shrink();

              final recommendation = _recommendations.firstWhere(
                (rec) => rec.exerciseIds.contains(entry.key),
              );
              final targetFreq =
                  recommendation.frequencyPerWeek?[entry.key] ?? 3;
              final completed = entry.value;

              return ListTile(
                title: Text(exercise.title),
                subtitle: Text('$completed/$targetFreq completed'),
                trailing: Icon(
                  completed >= targetFreq ? Icons.check_circle : Icons.schedule,
                  color: completed >= targetFreq ? Colors.green : Colors.grey,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseVideoCategories(bool isWideScreen, double maxWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled,
                    color: Colors.blue[600], size: 24),
                SizedBox(width: 8),
                Text('Exercise Videos',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Access these exercise videos anytime to stay active and healthy!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildExerciseCategoryCard(
                  'Basic Exercises',
                  'Strength and conditioning for beginners',
                  Icons.fitness_center,
                  Colors.blue,
                  'https://www.youtube.com/watch?v=GIz1C3yfE1s&list=PLWplBfOD_MWjL9TUfMzprF159PpoUwzc4&pp=gAQB',
                  maxWidth,
                ),
                _buildExerciseCategoryCard(
                  'Flexibility & Mobility',
                  'Stretching and flexibility exercises',
                  Icons.accessibility_new,
                  Colors.orange,
                  'https://www.youtube.com/watch?v=VwSRo8kdjeg&list=PLWplBfOD_MWhtF_9r-z3soDDkylC62K8k&pp=gAQB',
                  maxWidth,
                ),
                _buildExerciseCategoryCard(
                  'Balance Training',
                  'Stability and balance exercises',
                  Icons.balance,
                  Colors.purple,
                  'https://www.youtube.com/watch?v=gJdl-MNMxlY&list=PLWplBfOD_MWgkWFkDuyIg3C1ZQ49auzMO&pp=gAQB',
                  maxWidth,
                ),
                _buildExerciseCategoryCard(
                  'Cardio Training',
                  'Aerobic and cardiovascular exercises',
                  Icons.favorite,
                  Colors.red,
                  'https://www.youtube.com/watch?v=nmvVfgrExAg&list=PLWplBfOD_MWiT6pqMpzm9WsJZt0ydxXds&pp=gAQB0gcJCV8EOCosWNin',
                  maxWidth,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCategoryCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String youtubeUrl,
    double maxWidth,
  ) {
    final cardWidth = maxWidth > 600 ? (maxWidth - 48) / 2 : maxWidth - 32;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _launchYouTubePlaylist(youtubeUrl),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Spacer(),
                    Icon(Icons.play_circle_filled, color: color, size: 24),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to watch',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRecommendationsSection(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Exercise Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _sendExerciseFeedbackToDoctor,
              child: Text('Send Feedback'),
            ),
          ],
        ),
        ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildRecommendationCard(ExerciseRecommendation recommendation) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Created: ${DateFormat('MMM dd, yyyy').format(recommendation.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (recommendation.notes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Notes: ${recommendation.notes}',
                    style: TextStyle(fontSize: 14)),
              ),
            ...recommendation.exerciseIds.map((exerciseId) {
              final exercise = _exercises[exerciseId];
              if (exercise == null) return SizedBox.shrink();

              final targetFreq =
                  recommendation.frequencyPerWeek?[exerciseId] ?? 3;
              final completed = _weeklyProgress[exerciseId] ?? 0;

              return _buildExerciseCard(
                  exercise, exerciseId, targetFreq, completed);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      Exercise exercise, String exerciseId, int targetFreq, int completed) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.title,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${exercise.duration} min • ${exercise.difficulty}',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('$completed/$targetFreq',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(exercise.description, style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _launchVideo(exercise.videoUrl),
                    child: Text('Watch Video'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _logExerciseCompletion(exerciseId, exercise),
                    child: Text('Log Exercise'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendExerciseFeedbackToDoctor() async {
    final user = _auth.currentUser;
    if (user == null || _recommendations.isEmpty) return;

    try {
      // Get doctor ID
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        doctorId = userDoc.data()?['assignedDoctorId'];

        // If no assigned doctor, try to get from patients collection
        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          doctorId = patientDoc.data()?['assignedDoctorId'];
        }
      } catch (e) {
        print('Could not get doctor ID: $e');
      }

      final latestRecommendation = _recommendations.first;
      int totalCompleted = 0;
      int totalTarget = 0;

      for (String exerciseId in latestRecommendation.exerciseIds) {
        totalCompleted += _weeklyProgress[exerciseId] ?? 0;
        totalTarget += latestRecommendation.frequencyPerWeek?[exerciseId] ?? 3;
      }

      await _firestore.collection('exercise_feedback').add({
        'patientId': user.uid,
        'doctorId': doctorId,
        'patientName': latestRecommendation.patientName,
        'weekStart': _currentWeekStart.toIso8601String(),
        'totalCompleted': totalCompleted,
        'totalTarget': totalTarget,
        'completionRate':
            totalTarget > 0 ? (totalCompleted / totalTarget * 100).round() : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback sent to doctor!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending feedback: $e')),
      );
    }
  }

  Future<void> _launchYouTubePlaylist(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open YouTube playlist')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening YouTube: $e')),
      );
    }
  }
}
