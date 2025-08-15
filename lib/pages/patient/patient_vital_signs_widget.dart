import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientVitalSignsWidget extends StatefulWidget {
  const PatientVitalSignsWidget({super.key});

  @override
  State<PatientVitalSignsWidget> createState() => _PatientVitalSignsWidgetState();
}

class _PatientVitalSignsWidgetState extends State<PatientVitalSignsWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Vital Signs Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.add, color: Colors.red[600]),
                  onSelected: (value) => _showAddVitalDialog(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'blood_pressure',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Add Blood Pressure'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'blood_sugar',
                      child: Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Add Blood Sugar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Blood Pressure Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Blood Pressure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
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
                        'Blood Sugar Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
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
                  child: _buildVitalSummaryCard('BP', '120/80', 'Normal', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalSummaryCard('Sugar', '95 mg/dL', 'Normal', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalSummaryCard('Readings', '14', 'This Week', Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBPChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: _auth.currentUser!.uid)
          .where('type', isEqualTo: 'blood_pressure')
          .orderBy('timestamp', descending: false)
          .limit(7)
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
              border: Border.all(color: Colors.red[300]!),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Recent Readings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final data = readings[index].data() as Map<String, dynamic>;
                    final systolic = data['systolic'] ?? '';
                    final diastolic = data['diastolic'] ?? '';
                    final timestamp = data['timestamp'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getBPColor(int.tryParse(systolic) ?? 0, int.tryParse(diastolic) ?? 0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$systolic/$diastolic',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp).split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSugarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: _auth.currentUser!.uid)
          .where('type', isEqualTo: 'blood_sugar')
          .orderBy('timestamp', descending: false)
          .limit(7)
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Recent Readings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final data = readings[index].data() as Map<String, dynamic>;
                    final value = data['value'] ?? '';
                    final mealType = data['mealType'] ?? '';
                    final timestamp = data['timestamp'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSugarColor(int.tryParse(value) ?? 0, mealType),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$value mg/dL',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            mealType,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp).split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalSummaryCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBPColor(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return Colors.red[600]!;
    if (systolic >= 130 || diastolic >= 80) return Colors.orange[600]!;
    if (systolic >= 120) return Colors.amber[600]!;
    return Colors.green[600]!;
  }

  Color _getSugarColor(int value, String mealType) {
    if (mealType.toLowerCase().contains('fasting')) {
      if (value >= 126) return Colors.red[600]!;
      if (value >= 100) return Colors.orange[600]!;
      return Colors.green[600]!;
    } else {
      if (value >= 200) return Colors.red[600]!;
      if (value >= 140) return Colors.orange[600]!;
      return Colors.green[600]!;
    }
  }

  void _showAddVitalDialog(String type) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController value2Controller = TextEditingController();
    String selectedMealType = 'Fasting';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${type == 'blood_pressure' ? 'Blood Pressure' : 'Blood Sugar'} Reading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'blood_pressure') ...[
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Systolic (mmHg)',
                      hintText: 'e.g., 120',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: value2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic (mmHg)',
                      hintText: 'e.g., 80',
                    ),
                    keyboardType: TextInputType.number,
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
                    items: ['Fasting', 'Post-meal', 'Random', 'Bedtime'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedMealType = value!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveVitalReading(type, valueController.text, value2Controller.text, selectedMealType),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVitalReading(String type, String value1, String value2, String mealType) async {
    if (value1.isEmpty || (type == 'blood_pressure' && value2.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final data = {
        'patientId': _auth.currentUser!.uid,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (type == 'blood_pressure') {
        data['systolic'] = value1;
        data['diastolic'] = value2;
      } else {
        data['value'] = value1;
        data['unit'] = 'mg/dL';
        data['mealType'] = mealType;
      }

      await _firestore.collection('vital_signs').add(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type == 'blood_pressure' ? 'Blood pressure' : 'Blood sugar'} reading saved!'),
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

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM dd, HH:mm').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
} 