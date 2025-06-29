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
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    List<Meal> mealsList = [];
    if (json['meals'] != null) {
      mealsList = (json['meals'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList();
    }

    List<String>? restrictionsList;
    if (json['restrictions'] != null) {
      restrictionsList = List<String>.from(json['restrictions']);
    }

    return DietPlan(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      patientName: json['patients']['name'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      meals: mealsList,
      restrictions: restrictionsList,
      nutritionGuidelines: json['nutrition_guidelines'],
      additionalInstructions: json['additional_instructions'],
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
      type: json['type'],
      name: json['name'],
      description: json['description'],
      portionSize: json['portion_size'],
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

