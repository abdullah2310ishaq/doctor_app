class DietPlan {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String startDate;
  final String? endDate;
  final List<Meal> meals;
  final List<String>? restrictions;
  final String? nutritionGuidelines;
  final String? additionalInstructions;
  final List<MealLog>? logs;

  DietPlan({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.startDate,
    this.endDate,
    required this.meals,
    this.restrictions,
    this.nutritionGuidelines,
    this.additionalInstructions,
    this.logs,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    List<Meal> mealsList = [];
    if (json['meals'] != null) {
      mealsList =
          (json['meals'] as List).map((meal) => Meal.fromJson(meal)).toList();
    }

    List<String>? restrictionsList;
    if (json['restrictions'] != null) {
      restrictionsList = List<String>.from(json['restrictions']);
    }

    List<MealLog>? logsList;
    if (json['logs'] != null) {
      logsList =
          (json['logs'] as List).map((log) => MealLog.fromJson(log)).toList();
    }

    return DietPlan(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? json['doctorId'] ?? '',
      patientId: json['patient_id'] ?? json['patientId'] ?? '',
      patientName:
          json['patientName'] ?? json['patients']?['name'] ?? 'Unknown Patient',
      startDate: json['start_date'] ??
          json['startDate'] ??
          DateTime.now().toIso8601String(),
      endDate: json['end_date'] ?? json['endDate'],
      meals: mealsList,
      restrictions: restrictionsList,
      nutritionGuidelines:
          json['nutrition_guidelines'] ?? json['nutritionGuidelines'],
      additionalInstructions:
          json['additional_instructions'] ?? json['additionalInstructions'],
      logs: logsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'start_date': startDate,
      'end_date': endDate,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'restrictions': restrictions,
      'nutrition_guidelines': nutritionGuidelines,
      'additional_instructions': additionalInstructions,
      'logs': logs?.map((log) => log.toJson()).toList(),
    };
  }
}

class Meal {
  final String type; // breakfast, lunch, dinner, snack
  final String name;
  final String? description;
  final String? portionSize;
  final List<String>? ingredients;
  final String? time;

  Meal({
    required this.type,
    required this.name,
    this.description,
    this.portionSize,
    this.ingredients,
    this.time,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<String>? ingredientsList;
    if (json['ingredients'] != null) {
      ingredientsList = List<String>.from(json['ingredients']);
    }

    return Meal(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      portionSize: json['portion_size'] ?? json['portionSize'],
      ingredients: ingredientsList,
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'description': description,
      'portion_size': portionSize,
      'ingredients': ingredients,
      'time': time,
    };
  }
}

class MealLog {
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime date;
  final bool eatenAsPrescribed;
  final String? alternativeFood;
  final String? notes;

  MealLog({
    required this.mealType,
    required this.date,
    required this.eatenAsPrescribed,
    this.alternativeFood,
    this.notes,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      mealType: json['mealType'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      eatenAsPrescribed: json['eatenAsPrescribed'] ?? false,
      alternativeFood: json['alternativeFood'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'date': date.toIso8601String(),
      'eatenAsPrescribed': eatenAsPrescribed,
      'alternativeFood': alternativeFood,
      'notes': notes,
    };
  }
}
