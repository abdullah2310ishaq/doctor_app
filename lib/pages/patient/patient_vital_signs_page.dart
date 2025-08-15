import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientVitalSignsPage extends StatefulWidget {
  const PatientVitalSignsPage({super.key});

  @override
  State<PatientVitalSignsPage> createState() => _PatientVitalSignsPageState();
}

class _PatientVitalSignsPageState extends State<PatientVitalSignsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _patientId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vital Signs Tracking'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: _patientId == null
          ? const Center(child: Text('User not authenticated'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildVitalSignsCharts(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: Colors.teal[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Your Vital Signs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your blood pressure and blood sugar levels',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Regular monitoring helps you and your doctor track your health progress. Add readings weekly for best results.',
                      style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blood Pressure Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Blood Pressure Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVitalDialog('blood_pressure'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Reading',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBPChart(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Blood Sugar Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Blood Sugar Level Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVitalDialog('blood_sugar'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Reading',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSugarChart(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Summary Stats
        Row(
          children: [
            Expanded(
                child: _buildVitalSummaryCard(
                    'BP', '120/80', 'Normal', Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildVitalSummaryCard(
                    'Sugar', '95 mg/dL', 'Normal', Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildVitalSummaryCard(
                    'Readings', '14', 'This Week', Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildBPChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: _patientId)
          .where('type', isEqualTo: 'blood_pressure')
          .orderBy('timestamp', descending: false)
          .limit(7) // Last 7 readings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data?.docs ?? [];

        if (readings.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No BP readings yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add readings to see trends',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index].data() as Map<String, dynamic>;
              final systolic = reading['systolic']?.toString() ?? '0';
              final diastolic = reading['diastolic']?.toString() ?? '0';
              final timestamp = reading['timestamp']?.toString() ?? '';

              // Determine color based on BP values
              Color cardColor = Colors.green;
              final systolicInt = int.tryParse(systolic) ?? 0;
              final diastolicInt = int.tryParse(diastolic) ?? 0;

              if (systolicInt >= 140 || diastolicInt >= 90) {
                cardColor = Colors.red;
              } else if (systolicInt >= 120 || diastolicInt >= 80) {
                cardColor = Colors.orange;
              }

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$systolic/$diastolic',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'mmHg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (timestamp.isNotEmpty) ...[
                        Text(
                          DateFormat('MMM dd')
                              .format(DateTime.parse(timestamp)),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSugarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: _patientId)
          .where('type', isEqualTo: 'blood_sugar')
          .orderBy('timestamp', descending: false)
          .limit(7) // Last 7 readings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data?.docs ?? [];

        if (readings.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No sugar readings yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add readings to see trends',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index].data() as Map<String, dynamic>;
              final value = reading['value']?.toString() ?? '0';
              final mealType = reading['mealType']?.toString() ?? '';
              final timestamp = reading['timestamp']?.toString() ?? '';

              // Determine color based on sugar value
              Color cardColor = Colors.green;
              final sugarInt = int.tryParse(value) ?? 0;

              if (sugarInt >= 200) {
                cardColor = Colors.red;
              } else if (sugarInt >= 140) {
                cardColor = Colors.orange;
              }

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (mealType.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          mealType,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (timestamp.isNotEmpty) ...[
                        Text(
                          DateFormat('MMM dd')
                              .format(DateTime.parse(timestamp)),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVitalSummaryCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.teal[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVitalDialog('blood_pressure'),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Add BP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVitalDialog('blood_sugar'),
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Add Sugar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVitalDialog(String type) {
    final valueController = TextEditingController();
    final value2Controller = TextEditingController();
    String? selectedMealType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              'Add ${type == 'blood_pressure' ? 'Blood Pressure' : 'Blood Sugar'} Reading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'blood_pressure') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueController,
                        decoration: const InputDecoration(
                          labelText: 'Systolic (mmHg)',
                          hintText: 'e.g., 120',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: value2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic (mmHg)',
                          hintText: 'e.g., 80',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Sugar (mg/dL)',
                    hintText: 'e.g., 95',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  items:
                      ['Fasting', 'Post-meal', 'Random', 'Bedtime'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedMealType = value!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveVitalReading(type, valueController.text,
                  value2Controller.text, selectedMealType),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVitalReading(
      String type, String value1, String value2, String? mealType) async {
    if (value1.isEmpty || (type == 'blood_pressure' && value2.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final data = {
        'patientId': _patientId,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (type == 'blood_pressure') {
        data['systolic'] = value1;
        data['diastolic'] = value2;
      } else {
        data['value'] = value1;
        data['unit'] = 'mg/dL';
        data['mealType'] = mealType ?? 'Random';
      }

      await _firestore.collection('vital_signs').add(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${type == 'blood_pressure' ? 'Blood pressure' : 'Blood sugar'} reading saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reading: $e')),
        );
      }
    }
  }
}
