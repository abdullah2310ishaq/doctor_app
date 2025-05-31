import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DietPlanPage extends StatefulWidget {
  const DietPlanPage({super.key});

  @override
  State<DietPlanPage> createState() => _DietPlanPageState();
}

class _DietPlanPageState extends State<DietPlanPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _nutritionGuidelinesController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();
  
  bool _isLoading = false;
  bool _patientsLoading = false;
  String? _errorMessage;
  
  List<Map<String, dynamic>> _patients = [];
  List<MealInput> _meals = [];
  List<String> _restrictions = [];

  final List<String> _availableRestrictions = [
    'Low Sugar', 'Low Salt', 'Gluten Free', 'Dairy Free', 
    'Vegetarian', 'Vegan', 'Low Fat', 'Low Carb', 'Nut Free'
  ];

  final List<String> _mealTypes = [
    'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack'
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    // Add initial meal inputs
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

  void _loadPatients() {
    setState(() {
      _patientsLoading = true;
    });

    // Mock patient data
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _patients = [
          {'id': 'pat1', 'name': 'John Doe'},
          {'id': 'pat2', 'name': 'Jane Smith'},
          {'id': 'pat3', 'name': 'Robert Johnson'},
          {'id': 'pat4', 'name': 'Emily Davis'},
          {'id': 'pat5', 'name': 'Michael Brown'},
        ];
        _patientsLoading = false;
      });
    });
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
        // If end date is before start date, reset it
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
    // Find a meal type that hasn't been used yet
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
        const SnackBar(
          content: Text('All meal types have been added'),
        ),
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

  void _saveDietPlan() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      setState(() {
        _errorMessage = 'Please select a patient';
      });
      return;
    }
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

    // Simulate diet plan saving
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diet plan saved successfully'),
        ),
      );
      
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Diet Plan'),
      ),
      body: _patientsLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a personalized diet plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                    : 'Not specified',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Dietary Restrictions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._meals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final meal = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                                decoration: const InputDecoration(
                                  labelText: 'Meal Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter meal name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: meal.descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
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
                                      decoration: const InputDecoration(
                                        labelText: 'Portion Size',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: meal.timeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Time (e.g., 8:00 AM)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: meal.ingredientsController,
                                decoration: const InputDecoration(
                                  labelText: 'Ingredients (one per line)',
                                  border: OutlineInputBorder(),
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
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nutritionGuidelinesController,
                      decoration: const InputDecoration(
                        labelText: 'Nutrition Guidelines',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _additionalInstructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Instructions',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDietPlan,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Diet Plan'),
                        ),
                      ),
                    ),
                  ],
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

