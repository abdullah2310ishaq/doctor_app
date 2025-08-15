import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseRecommendationPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final Map<String, dynamic>? patientData;

  const ExerciseRecommendationPage({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientData,
  });

  @override
  State<ExerciseRecommendationPage> createState() =>
      _ExerciseRecommendationPageState();
}

class _ExerciseRecommendationPageState
    extends State<ExerciseRecommendationPage> {
  final TextEditingController _notesController = TextEditingController();
  final List<String> _selectedExercises = [];
  final Map<String, int> _frequencyPerWeek = {};
  bool _isLoading = false;

  // Predefined exercise options
  final List<Map<String, dynamic>> _exerciseOptions = [
    {
      'id': 'walking',
      'name': 'Walking',
      'description': 'Daily walking for 30 minutes',
      'duration': '30 min',
      'difficulty': 'Easy',
      'icon': Icons.directions_walk,
    },
    {
      'id': 'jogging',
      'name': 'Jogging',
      'description': 'Light jogging for cardiovascular health',
      'duration': '20 min',
      'difficulty': 'Moderate',
      'icon': Icons.directions_run,
    },
    {
      'id': 'cycling',
      'name': 'Cycling',
      'description': 'Stationary or outdoor cycling',
      'duration': '25 min',
      'difficulty': 'Moderate',
      'icon': Icons.directions_bike,
    },
    {
      'id': 'swimming',
      'name': 'Swimming',
      'description': 'Low-impact full body exercise',
      'duration': '30 min',
      'difficulty': 'Moderate',
      'icon': Icons.pool,
    },
    {
      'id': 'yoga',
      'name': 'Yoga',
      'description': 'Gentle stretching and flexibility',
      'duration': '45 min',
      'difficulty': 'Easy',
      'icon': Icons.self_improvement,
    },
    {
      'id': 'strength_training',
      'name': 'Strength Training',
      'description': 'Light weight training for muscle strength',
      'duration': '40 min',
      'difficulty': 'Moderate',
      'icon': Icons.fitness_center,
    },
    {
      'id': 'pilates',
      'name': 'Pilates',
      'description': 'Core strengthening exercises',
      'duration': '35 min',
      'difficulty': 'Moderate',
      'icon': Icons.accessibility_new,
    },
    {
      'id': 'stretching',
      'name': 'Stretching',
      'description': 'Daily stretching routine',
      'duration': '15 min',
      'difficulty': 'Easy',
      'icon': Icons.accessibility,
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleExerciseSelection(String exerciseId) {
    setState(() {
      if (_selectedExercises.contains(exerciseId)) {
        _selectedExercises.remove(exerciseId);
        _frequencyPerWeek.remove(exerciseId);
      } else {
        _selectedExercises.add(exerciseId);
        _frequencyPerWeek[exerciseId] = 3; // default 3 times per week
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _saveRecommendation() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one exercise'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate saving to database
      await Future.delayed(const Duration(seconds: 1));
      // Save frequencyPerWeek as part of the recommendation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Exercise recommendation saved successfully!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recommendation: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
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
        title: Text('Exercise Recommendations'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Select exercises and set frequency per week:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._exerciseOptions.map((exercise) {
                    final id = exercise['id'] as String;
                    final selected = _selectedExercises.contains(id);
                    return Card(
                      elevation: selected ? 4 : 1,
                      color: selected ? Colors.blue[50] : Colors.white,
                      child: ListTile(
                        leading: Icon(exercise['icon'], color: Colors.blue),
                        title: Text(exercise['name']),
                        subtitle: Text(exercise['description']),
                        trailing: selected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('per week:'),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 40,
                                    child: TextFormField(
                                      initialValue:
                                          _frequencyPerWeek[id]?.toString() ??
                                              '3',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 6),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        final freq = int.tryParse(val) ?? 3;
                                        setState(() {
                                          _frequencyPerWeek[id] = freq;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : null,
                        onTap: () => _toggleExerciseSelection(id),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Exercise list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exerciseOptions.length,
                itemBuilder: (context, index) {
                  final exercise = _exerciseOptions[index];
                  final isSelected =
                      _selectedExercises.contains(exercise['id']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _toggleExerciseSelection(exercise['id']),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                exercise['icon'],
                                color: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          exercise['duration'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          exercise['difficulty'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected ? Colors.blue : Colors.grey[300],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Add any specific instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                prefixIcon: Icon(Icons.note, color: Colors.blue[600]),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRecommendation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Recommendation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
