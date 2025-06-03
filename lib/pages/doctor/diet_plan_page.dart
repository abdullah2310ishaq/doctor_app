import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/services/notification_service.dart';

class CreateeDietPlanPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onDietPlanCreated;

  const CreateeDietPlanPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onDietPlanCreated,
  });

  @override
  State<CreateeDietPlanPage> createState() => _CreateeDietPlanPageState();
}

class _CreateeDietPlanPageState extends State<CreateeDietPlanPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _nutritionGuidelinesController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  List<MealInput> _meals = [];
  List<String> _restrictions = [];

  final List<String> _availableRestrictions = [
    'Low Sugar', 'Low Salt', 'Gluten Free', 'Dairy Free', 
    'Vegetarian', 'Vegan', 'Low Fat', 'Low Carb', 'Nut Free'
  ];

  final List<String> _mealTypes = [
    'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize default meals
    _meals.add(MealInput(type: 'Breakfast'));
    _meals.add(MealInput(type: 'Lunch'));
    _meals.add(MealInput(type: 'Dinner'));
  }

  @override
  void dispose() {
    _nutritionGuidelinesController.dispose();
    _additionalInstructionsController.dispose();
    for (var meal in _meals) {
      meal.dispose();
    }
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _addMeal() {
    String? availableType;
    for (var type in _mealTypes) {
      if (!_meals.any((meal) => meal.type == type)) {
        availableType = type;
        break;
      }
    }

    if (availableType != null) {
      setState(() {
        _meals.add(MealInput(type: availableType!));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All meal types have been added')),
      );
    }
  }

  void _removeMeal(int index) {
    setState(() {
      _meals[index].dispose();
      _meals.removeAt(index);
    });
  }

  void _toggleRestriction(String restriction) {
    setState(() {
      if (_restrictions.contains(restriction)) {
        _restrictions.remove(restriction);
      } else {
        _restrictions.add(restriction);
      }
    });
  }

  void _saveDietPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_meals.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one meal';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
      final doctorName = doctorDoc.exists
          ? (doctorDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Doctor'
          : 'Doctor';

      final meals = _meals.map((meal) {
        final ingredients = meal.ingredientsController.text
            .trim()
            .split('\n')
            .where((i) => i.isNotEmpty)
            .toList();
        return {
          'type': meal.type,
          'name': meal.nameController.text.trim(),
          'description': meal.descriptionController.text.trim(),
          'portionSize': meal.portionSizeController.text.trim().isEmpty
              ? '1 serving'
              : meal.portionSizeController.text.trim(),
          'ingredients': ingredients,
          'time': meal.timeController.text.trim().isEmpty
              ? _getDefaultTime(meal.type)
              : meal.timeController.text.trim(),
        };
      }).toList();

      final dietPlanRef = await _firestore.collection('diet_plans').add({
        'doctorId': user.uid,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate?.toIso8601String() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'meals': meals,
        'restrictions': _restrictions,
        'nutritionGuidelines': _nutritionGuidelinesController.text.trim(),
        'additionalInstructions': _additionalInstructionsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createDietPlanNotification(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        dietPlanId: dietPlanRef.id,
      );

      if (!mounted) return;
      widget.onDietPlanCreated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error creating diet plan: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating diet plan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDefaultTime(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return '8:00 AM';
      case 'Morning Snack':
        return '10:30 AM';
      case 'Lunch':
        return '1:00 PM';
      case 'Afternoon Snack':
        return '3:30 PM';
      case 'Dinner':
        return '7:00 PM';
      case 'Evening Snack':
        return '9:00 PM';
      default:
        return '12:00 PM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diet Plan for ${widget.patientName}'),
        backgroundColor: Colors.teal[50],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[100]!, Colors.teal[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a Personalized Diet Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: widget.patientName,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Patient',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectStartDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_startDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEndDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : 'Not specified',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dietary Restrictions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableRestrictions.map((restriction) {
                      final isSelected = _restrictions.contains(restriction);
                      return FilterChip(
                        label: Text(restriction),
                        selected: isSelected,
                        onSelected: (_) => _toggleRestriction(restriction),
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.teal[100],
                        checkmarkColor: Colors.teal,
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected ? Colors.teal[900] : Colors.grey[800],
                            ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Meals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._meals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meal.type,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeMeal(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: meal.nameController,
                              decoration: InputDecoration(
                                labelText: 'Meal Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.restaurant, color: Colors.teal),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter meal name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: meal.descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.description, color: Colors.teal),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: meal.portionSizeController,
                                    decoration: InputDecoration(
                                      labelText: 'Portion Size',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.kitchen, color: Colors.teal),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: meal.timeController,
                                    decoration: InputDecoration(
                                      labelText: 'Time (e.g., 8:00 AM)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.schedule, color: Colors.teal),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: meal.ingredientsController,
                              decoration: InputDecoration(
                                labelText: 'Ingredients (one per line)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.list, color: Colors.teal),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _addMeal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Meal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nutritionGuidelinesController,
                    decoration: InputDecoration(
                      labelText: 'Nutrition Guidelines',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note, color: Colors.teal),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _additionalInstructionsController,
                    decoration: InputDecoration(
                      labelText: 'Additional Instructions',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.info, color: Colors.teal),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red[600],
                            ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDietPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Diet Plan',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MealInput {
  final String type;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final portionSizeController = TextEditingController();
  final ingredientsController = TextEditingController();
  final timeController = TextEditingController();

  MealInput({required this.type});

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    portionSizeController.dispose();
    ingredientsController.dispose();
    timeController.dispose();
  }
}