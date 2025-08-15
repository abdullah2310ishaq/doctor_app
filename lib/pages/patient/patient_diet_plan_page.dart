import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/models/diet_plan.dart';

class PatientDietPlanPage extends StatefulWidget {
  const PatientDietPlanPage({super.key});

  @override
  State<PatientDietPlanPage> createState() => _PatientDietPlanPageState();
}

class _PatientDietPlanPageState extends State<PatientDietPlanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DietPlan> _dietPlans = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDietPlans();
  }

  Future<void> _loadDietPlans() async {
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
      final snapshot = await _firestore
          .collection('diet_plans')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('startDate', descending: true)
          .get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        try {
          return DietPlan.fromJson(data);
        } catch (e) {
          print('Error parsing diet plan ${doc.id}: $e');
          // Return a default diet plan if parsing fails
          return DietPlan(
            id: doc.id,
            doctorId: data['doctorId'] ?? data['doctor_id'] ?? '',
            patientId: data['patientId'] ?? data['patient_id'] ?? '',
            patientName: data['patientName'] ?? 'Unknown Patient',
            startDate: data['startDate'] ??
                data['start_date'] ??
                DateTime.now().toIso8601String(),
            endDate: data['endDate'] ?? data['end_date'],
            meals: [],
            restrictions: data['restrictions'] != null
                ? List<String>.from(data['restrictions'])
                : null,
            nutritionGuidelines:
                data['nutritionGuidelines'] ?? data['nutrition_guidelines'],
            additionalInstructions: data['additionalInstructions'] ??
                data['additional_instructions'],
            logs: null,
          );
        }
      }).toList();

      setState(() {
        _dietPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading diet plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logMeal(String mealType, bool eatenAsPrescribed,
      [String? altFood]) async {
    final user = _auth.currentUser;
    if (user == null || _dietPlans.isEmpty) return;

    if (_selectedPlanIndex >= _dietPlans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No diet plan selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPlan = _dietPlans[_selectedPlanIndex];

    final log = {
      'mealType': mealType,
      'date': DateTime.now().toIso8601String(),
      'eatenAsPrescribed': eatenAsPrescribed,
      'alternativeFood': altFood ?? '', // Ensure altFood is never null
    };

    try {
      if (currentPlan.id.isNotEmpty) {
        // First check if the document exists and has logs array
        final docRef = _firestore.collection('diet_plans').doc(currentPlan.id);
        final doc = await docRef.get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          List<dynamic> logs = data['logs'] ?? [];
          logs.add(log);

          await docRef.update({'logs': logs});
        } else {
          // If document doesn't exist, create it with the log
          await docRef.set({
            'logs': [log]
          }, SetOptions(merge: true));
        }
      }

      // Send feedback to doctor
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          doctorId = userDoc.data()?['assignedDoctorId'];
        }
        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          if (patientDoc.exists) {
            doctorId = patientDoc.data()?['assignedDoctorId'];
          }
        }
      } catch (e) {
        print('Error getting assigned doctor: $e');
      }

      final targetDoctorId = doctorId ?? currentPlan.doctorId;

      if (targetDoctorId != null && targetDoctorId.isNotEmpty) {
        await _firestore.collection('diet_plan_feedback').add({
          'dietPlanId': currentPlan.id,
          'patientId': user.uid,
          'doctorId': targetDoctorId,
          'feedback': eatenAsPrescribed
              ? 'Ate as prescribed'
              : 'Ate different food: ${altFood ?? "Not specified"}',
          'mealType': mealType,
          'eatenAsPrescribed': eatenAsPrescribed,
          'alternativeFood': altFood,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal log saved and feedback sent to doctor!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the data
      _loadDietPlans();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving meal log: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Enhanced meal logging dialog with comprehensive options
  void _showEnhancedMealLogDialog(Meal meal) {
    bool eatenAsPrescribed = true;
    String actualFood = '';
    String portions = 'Full portion';
    String satisfaction = 'Satisfied';
    String notes = '';

    final List<String> portionOptions = [
      'Full portion',
      '3/4 portion',
      'Half portion',
      '1/4 portion',
      'Didn\'t eat'
    ];
    final List<String> satisfactionOptions = [
      'Very satisfied',
      'Satisfied',
      'Somewhat satisfied',
      'Still hungry',
      'Too full'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(_getMealIcon(meal.type), color: _getMealColor(meal.type)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log ${meal.type.toUpperCase()}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prescribed meal info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescribed: ${meal.name}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (meal.description != null) ...[
                          SizedBox(height: 4),
                          Text(meal.description!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                        if (meal.time != null) ...[
                          SizedBox(height: 4),
                          Text('Scheduled time: ${meal.time}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Did you eat as prescribed?
                  Text('Did you eat the prescribed meal?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile<bool>(
                        title: Text('✅ Yes, I ate the prescribed meal'),
                        value: true,
                        groupValue: eatenAsPrescribed,
                        onChanged: (value) {
                          setDialogState(() {
                            eatenAsPrescribed = value!;
                            if (eatenAsPrescribed) actualFood = '';
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: Text('❌ No, I ate something different'),
                        value: false,
                        groupValue: eatenAsPrescribed,
                        onChanged: (value) {
                          setDialogState(() {
                            eatenAsPrescribed = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  // If ate something different, what was it?
                  if (!eatenAsPrescribed) ...[
                    SizedBox(height: 12),
                    Text('What did you actually eat?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => actualFood = value,
                      decoration: InputDecoration(
                        hintText: 'Describe what you ate instead...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],

                  SizedBox(height: 16),

                  // Portion size
                  Text('How much did you eat?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: portions,
                        isExpanded: true,
                        items: portionOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            portions = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Satisfaction level
                  Text('How do you feel after eating?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: satisfaction,
                        isExpanded: true,
                        items: satisfactionOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            satisfaction = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Additional notes
                  Text('Additional notes (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => notes = value,
                    decoration: InputDecoration(
                      hintText: 'Any additional comments...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
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
                _logEnhancedMeal(
                  meal.type,
                  meal.name,
                  eatenAsPrescribed,
                  actualFood.isEmpty ? null : actualFood,
                  portions,
                  satisfaction,
                  notes.isEmpty ? null : notes,
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Save Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced meal logging with comprehensive data
  Future<void> _logEnhancedMeal(
    String mealType,
    String prescribedMeal,
    bool eatenAsPrescribed,
    String? actualFood,
    String portions,
    String satisfaction,
    String? notes,
  ) async {
    final user = _auth.currentUser;
    if (user == null || _dietPlans.isEmpty) return;

    if (_selectedPlanIndex >= _dietPlans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No diet plan selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPlan = _dietPlans[_selectedPlanIndex];

    final log = {
      'mealType': mealType,
      'prescribedMeal': prescribedMeal,
      'date': DateTime.now().toIso8601String(),
      'eatenAsPrescribed': eatenAsPrescribed,
      'actualFood': actualFood,
      'portions': portions,
      'satisfaction': satisfaction,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      if (currentPlan.id.isNotEmpty) {
        await _firestore.collection('diet_plans').doc(currentPlan.id).update({
          'logs': FieldValue.arrayUnion([log])
        });
      }

      // Create notification to doctor about patient's meal log
      if (currentPlan.doctorId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': currentPlan.doctorId,
          'title': '🍽️ Patient Meal Log Update',
          'message':
              'Patient logged their ${mealType}. ${eatenAsPrescribed ? 'Followed prescribed meal' : 'Ate something different'}.',
          'type': 'meal_log_update',
          'relatedId': currentPlan.id,
          'patientId': user.uid,
          'mealType': mealType,
          'eatenAsPrescribed': eatenAsPrescribed,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal log saved and sent to doctor!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the data
      _loadDietPlans();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving meal log: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper methods for meal icons and colors
  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange[600]!;
      case 'lunch':
        return Colors.green[600]!;
      case 'dinner':
        return Colors.purple[600]!;
      case 'snack':
        return Colors.amber[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  void _showMealLogDialog(String mealType) {
    final TextEditingController altFoodController = TextEditingController();
    bool eatenAsPrescribed = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Log $mealType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: Text('Ate as prescribed'),
                value: true,
                groupValue: eatenAsPrescribed,
                onChanged: (value) {
                  setDialogState(() {
                    eatenAsPrescribed = value!;
                  });
                },
              ),
              RadioListTile<bool>(
                title: Text('Ate something else'),
                value: false,
                groupValue: eatenAsPrescribed,
                onChanged: (value) {
                  setDialogState(() {
                    eatenAsPrescribed = value!;
                  });
                },
              ),
              if (!eatenAsPrescribed) ...[
                SizedBox(height: 16),
                TextField(
                  controller: altFoodController,
                  decoration: InputDecoration(
                    labelText: 'What did you eat instead?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logMeal(
                  mealType,
                  eatenAsPrescribed,
                  eatenAsPrescribed ? null : altFoodController.text,
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Save Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFeedbackToDoctor(
      String feedback, List<String> issues) async {
    final user = _auth.currentUser;
    if (user == null || _dietPlans.isEmpty) return;

    if (_selectedPlanIndex >= _dietPlans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No diet plan selected'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentPlan = _dietPlans[_selectedPlanIndex];

    try {
      // Get assigned doctor ID from patient profile
      String? doctorId;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          doctorId = userDoc.data()?['assignedDoctorId'];
        }
        if (doctorId == null) {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          if (patientDoc.exists) {
            doctorId = patientDoc.data()?['assignedDoctorId'];
          }
        }
      } catch (e) {
        print('Error getting assigned doctor: $e');
      }

      // Use assigned doctor ID if available, otherwise use plan doctor ID
      final targetDoctorId = doctorId ?? currentPlan.doctorId;

      if (targetDoctorId != null && targetDoctorId.isNotEmpty) {
        await _firestore.collection('diet_plan_feedback').add({
          'dietPlanId': currentPlan.id,
          'patientId': user.uid,
          'doctorId': targetDoctorId,
          'feedback': feedback,
          'issues': issues,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback sent to doctor successfully!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    final List<String> availableIssues = [
      'Food allergies/reactions',
      'Don\'t like the taste',
      'Too expensive ingredients',
      'Hard to prepare',
      'Ingredients not available',
      'Still feeling hungry',
      'Not feeling satisfied',
      'Portion sizes too big/small',
      'Time conflicts with schedule',
      'Need more variety',
    ];
    final Set<String> selectedIssues = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Diet Plan Feedback'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select any issues you\'re experiencing:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: availableIssues
                        .map((issue) => CheckboxListTile(
                              title:
                                  Text(issue, style: TextStyle(fontSize: 14)),
                              value: selectedIssues.contains(issue),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value!) {
                                    selectedIssues.add(issue);
                                  } else {
                                    selectedIssues.remove(issue);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    labelText: 'Additional feedback',
                    border: OutlineInputBorder(),
                    hintText: 'Describe any other concerns or suggestions...',
                  ),
                  maxLines: 3,
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
                _sendFeedbackToDoctor(
                    feedbackController.text, selectedIssues.toList());
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child:
                  Text('Send Feedback', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('My Diet Plans',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.feedback),
            onPressed: _dietPlans.isNotEmpty ? _showFeedbackDialog : null,
            tooltip: 'Send Feedback',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDietPlans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
          : _errorMessage != null
              ? _buildErrorWidget()
              : _dietPlans.isEmpty
                  ? _buildEmptyWidget()
                  : _buildDietPlanContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDietPlans,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.blue[300]),
            SizedBox(height: 16),
            Text(
              'No Diet Plans Yet',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Your doctor will create personalized diet plans for you.',
              style: TextStyle(fontSize: 16, color: Colors.blue[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPlanContent() {
    return Column(
      children: [
        // Diet Plan Selection
        if (_dietPlans.length > 1) ...[
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Diet Plan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700]),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dietPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _dietPlans[index];
                          final isSelected = index == _selectedPlanIndex;
                          final startDate = DateTime.parse(plan.startDate);

                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                DateFormat('MMM dd, yyyy').format(startDate),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPlanIndex = index;
                                  });
                                }
                              },
                              selectedColor: Colors.blue[700],
                              backgroundColor: Colors.blue[100],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Diet Plan Details
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _buildDietPlanDetails(_dietPlans[_selectedPlanIndex]),
          ),
        ),
      ],
    );
  }

  Widget _buildDietPlanDetails(DietPlan plan) {
    final startDate = DateTime.parse(plan.startDate);
    final endDate = plan.endDate != null ? DateTime.parse(plan.endDate!) : null;
    final today = DateTime.now();
    final isActive = endDate == null ||
        today.isBefore(endDate) ||
        today.isAtSameMomentAs(endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan Overview Card
        Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Diet Plan Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Start Date',
                      DateFormat('MMM dd, yyyy').format(startDate)),
                  if (endDate != null)
                    _buildInfoRow(
                        'End Date', DateFormat('MMM dd, yyyy').format(endDate)),
                  _buildInfoRow('Status', isActive ? 'Active' : 'Completed'),
                  _buildInfoRow('Total Meals', '${plan.meals.length}'),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Nutrition Guidelines
        if (plan.nutritionGuidelines != null &&
            plan.nutritionGuidelines!.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Guidelines',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700]),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      plan.nutritionGuidelines!,
                      style: TextStyle(fontSize: 14, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Dietary Restrictions
        if (plan.restrictions != null && plan.restrictions!.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dietary Restrictions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700]),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plan.restrictions!
                        .map((restriction) => Chip(
                              label: Text(restriction,
                                  style: TextStyle(color: Colors.red[700])),
                              backgroundColor: Colors.red[50],
                              side: BorderSide(color: Colors.red[200]!),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Meals Section
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Meal Plan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700]),
                ),
                SizedBox(height: 16),
                ...plan.meals.map((meal) => _buildMealCard(meal, isActive)),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Additional Instructions
        if (plan.additionalInstructions != null &&
            plan.additionalInstructions!.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Instructions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700]),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      plan.additionalInstructions!,
                      style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Meal Logs Section
        if (plan.logs != null && plan.logs!.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Meal Logs',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700]),
                  ),
                  SizedBox(height: 12),
                  ...plan.logs!.take(10).map((log) => _buildLogItem(log)),
                  if (plan.logs!.length > 10)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${plan.logs!.length - 10} more logs',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal, bool isActive) {
    final mealIcons = {
      'Breakfast': Icons.wb_sunny,
      'Morning Snack': Icons.coffee,
      'Lunch': Icons.lunch_dining,
      'Afternoon Snack': Icons.cookie,
      'Dinner': Icons.dinner_dining,
      'Evening Snack': Icons.nightlight_round,
    };

    final mealColors = {
      'Breakfast': Colors.orange,
      'Morning Snack': Colors.brown,
      'Lunch': Colors.green,
      'Afternoon Snack': Colors.purple,
      'Dinner': Colors.indigo,
      'Evening Snack': Colors.deepPurple,
    };

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (mealColors[meal.type] ?? Colors.blue)[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    mealIcons[meal.type] ?? Icons.restaurant,
                    color: mealColors[meal.type] ?? Colors.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: mealColors[meal.type] ?? Colors.blue,
                        ),
                      ),
                      if (meal.time != null)
                        Text(
                          'Time: ${meal.time}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (isActive)
                  ElevatedButton(
                    onPressed: () => _showEnhancedMealLogDialog(meal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text('Log',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              meal.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (meal.description != null && meal.description!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                meal.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            if (meal.portionSize != null && meal.portionSize!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Portion: ${meal.portionSize}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Ingredients:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: meal.ingredients!
                    .map((ingredient) => Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            ingredient,
                            style: TextStyle(
                                fontSize: 12, color: Colors.green[700]),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(MealLog log) {
    final logDate = DateFormat('MMM dd, yyyy - HH:mm').format(log.date);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: log.eatenAsPrescribed ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              log.eatenAsPrescribed ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.eatenAsPrescribed ? Icons.check_circle : Icons.warning,
                color: log.eatenAsPrescribed
                    ? Colors.green[600]
                    : Colors.orange[600],
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '${log.mealType} - $logDate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: log.eatenAsPrescribed
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ],
          ),
          if (!log.eatenAsPrescribed && log.alternativeFood != null) ...[
            SizedBox(height: 4),
            Text(
              'Ate instead: ${log.alternativeFood}',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Notes: ${log.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
