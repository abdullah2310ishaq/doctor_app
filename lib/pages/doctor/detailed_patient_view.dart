import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DetailedPatientView extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> healthData;

  const DetailedPatientView({
    super.key,
    required this.patient,
    required this.healthData,
  });

  @override
  State<DetailedPatientView> createState() => _DetailedPatientViewState();
}

class _DetailedPatientViewState extends State<DetailedPatientView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _weeklyFeedbacks = [];
  List<Map<String, dynamic>> _recentLogs = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDetailedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetailedData() async {
    setState(() {
    });

    final patientId = widget.patient['id'];

    try {
      // Load weekly feedback history
      final feedbackSnapshot = await _firestore
          .collection('weekly_feedback')
          .where('patientId', isEqualTo: patientId)
          .orderBy('submittedAt', descending: true)
          .limit(8) // Last 8 weeks
          .get();

      _weeklyFeedbacks = feedbackSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Load recent activity logs
      _recentLogs = await _loadRecentLogs(patientId);

      // Load alerts and concerns
      _alerts = await _loadPatientAlerts(patientId);

      setState(() {
      });
    } catch (e) {
      // Error loading detailed data
      setState(() {
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentLogs(String patientId) async {
    List<Map<String, dynamic>> logs = [];

    try {
      // Get recent prescription logs
      final prescriptionSnapshot = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (prescriptionSnapshot.docs.isNotEmpty) {
        final prescription = prescriptionSnapshot.docs.first.data();
        final prescriptionLogs = prescription['logs'] as List? ?? [];

        for (var log in prescriptionLogs.take(10)) {
          logs.add({...log, 'type': 'medicine', 'source': 'prescription'});
        }
      }

      // Get recent diet logs
      final dietSnapshot = await _firestore
          .collection('diet_plans')
          .where('patientId', isEqualTo: patientId)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (dietSnapshot.docs.isNotEmpty) {
        final dietPlan = dietSnapshot.docs.first.data();
        final dietLogs = dietPlan['logs'] as List? ?? [];

        for (var log in dietLogs.take(10)) {
          logs.add({...log, 'type': 'meal', 'source': 'diet_plan'});
        }
      }

      // Get recent exercise logs
      final exerciseSnapshot = await _firestore
          .collection('exercise_logs')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      for (var doc in exerciseSnapshot.docs) {
        logs.add({...doc.data(), 'type': 'exercise', 'source': 'exercise_log'});
      }

      // Sort logs by date
      logs.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      return logs.take(20).toList();
    } catch (e) {
      // Error loading recent logs
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadPatientAlerts(
      String patientId) async {
    try {
      final alertSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return alertSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((alert) => _isImportantAlert(alert))
          .toList();
    } catch (e) {
      return [];
    }
  }

  bool _isImportantAlert(Map<String, dynamic> alert) {
    final message = alert['message']?.toLowerCase() ?? '';
    return message.contains('missed') ||
        message.contains('side effect') ||
        message.contains('stop') ||
        message.contains('severe') ||
        alert['hasSideEffects'] == true ||
        alert['wantsToContinue'] == false;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final healthData = widget.healthData;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(patient['name'] ?? 'Patient Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () => _showMessageDialog(),
            tooltip: 'Send Message',
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showEditPrescriptionDialog(),
            tooltip: 'Update Treatment',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Compliance'),
            Tab(text: 'Alerts'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(patient, healthData),
          _buildTrendsTab(),
          _buildComplianceTab(healthData),
          _buildAlertsTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      Map<String, dynamic> patient, Map<String, dynamic> healthData) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Summary Card
          _buildPatientSummaryCard(patient, healthData),
          SizedBox(height: 16),

          // Clinical Scores Card
          _buildClinicalScoresCard(healthData),
          SizedBox(height: 16),

          // Current Health Status
          _buildCurrentHealthCard(healthData),
          SizedBox(height: 16),

          // Recent Activity Summary
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildPatientSummaryCard(
      Map<String, dynamic> patient, Map<String, dynamic> healthData) {
    final overallCompliance = healthData['overallCompliance'] ?? 0;
    final overallHealth = healthData['overallHealthRating'] ?? 5;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      (patient['name'] ?? 'P')[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'] ?? 'Unknown Patient',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          patient['email'] ?? '',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Age: ${patient['age'] ?? 'N/A'} • Gender: ${patient['gender'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewMetric('Overall Health',
                        '$overallHealth/10', _getHealthColor(overallHealth)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewMetric(
                        'Compliance',
                        '${overallCompliance.toStringAsFixed(0)}%',
                        _getComplianceColor(overallCompliance)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalScoresCard(Map<String, dynamic> healthData) {
    final godinScore = healthData['godinScore'] ?? 0;
    final sarcfScore = healthData['sarcfScore'] ?? 0;
    final susScore = healthData['susScore'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Assessment Scores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard(
                    'Godin Exercise',
                    godinScore.toString(),
                    'Physical Activity Level',
                    _getGodinColor(godinScore),
                    Icons.fitness_center,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildScoreCard(
                    'SARC-F',
                    sarcfScore.toString(),
                    'Muscle Strength',
                    _getSarcfColor(sarcfScore),
                    Icons.accessibility,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildScoreCard(
                    'SUS Score',
                    susScore.toStringAsFixed(0),
                    'System Usability',
                    _getSusColor(susScore),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
      String title, String score, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHealthCard(Map<String, dynamic> healthData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Health Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 16),
            _buildHealthMetricRow(
                'Medicine Compliance',
                '${healthData['medicineCompliance']?.toStringAsFixed(0) ?? 0}%',
                _getComplianceColor(healthData['medicineCompliance'] ?? 0),
                Icons.medication),
            _buildHealthMetricRow(
                'Diet Compliance',
                '${healthData['dietCompliance']?.toStringAsFixed(0) ?? 0}%',
                _getComplianceColor(healthData['dietCompliance'] ?? 0),
                Icons.restaurant),
            _buildHealthMetricRow(
                'Exercise Compliance',
                '${healthData['exerciseCompliance']?.toStringAsFixed(0) ?? 0}%',
                _getComplianceColor(healthData['exerciseCompliance'] ?? 0),
                Icons.fitness_center),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricRow(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 16),
            if (_recentLogs.isEmpty)
              Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ..._recentLogs.take(3).map((log) => _buildActivityItem(log)),
            SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(4), // Go to Logs tab
                child: Text('View All Logs →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final type = log['type'];
    final date = DateTime.parse(log['date']);

    IconData icon;
    Color color;
    String description;

    switch (type) {
      case 'medicine':
        icon = Icons.medication;
        color = log['taken'] == true ? Colors.green[600]! : Colors.red[600]!;
        description =
            '${log['taken'] ? 'Took' : 'Missed'} ${log['medicationName']}';
        break;
      case 'meal':
        icon = Icons.restaurant;
        color = log['eatenAsPrescribed'] == true
            ? Colors.green[600]!
            : Colors.orange[600]!;
        description =
            '${log['eatenAsPrescribed'] ? 'Followed' : 'Modified'} ${log['mealType']}';
        break;
      case 'exercise':
        icon = Icons.fitness_center;
        color =
            log['completed'] == true ? Colors.green[600]! : Colors.red[600]!;
        description =
            '${log['completed'] ? 'Completed' : 'Missed'} ${log['exerciseTitle']}';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey[600]!;
        description = 'Activity logged';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Text(
            DateFormat('MMM dd, HH:mm').format(date),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Trends (Last 8 Weeks)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          if (_weeklyFeedbacks.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No trend data available',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          else
            ..._buildTrendCharts(),
        ],
      ),
    );
  }

  List<Widget> _buildTrendCharts() {
    return [
      _buildTrendCard(
        'Overall Health Rating',
        _weeklyFeedbacks
            .map((f) => (f['overallHealthRating'] ?? 5).toDouble())
            .toList()
            .cast<double>(),
        Colors.blue[600]!,
        0,
        10,
      ),
      const SizedBox(height: 16),
      _buildTrendCard(
        'Godin Exercise Score',
        _weeklyFeedbacks
            .map((f) => (f['godinScore'] ?? 0).toDouble())
            .toList()
            .cast<double>(),
        Colors.green[600]!,
        0,
        100,
      ),
      const SizedBox(height: 16),
      _buildTrendCard(
        'SARC-F Score',
        _weeklyFeedbacks
            .map((f) => (f['sarcfScore'] ?? 0).toDouble())
            .toList()
            .cast<double>(),
        Colors.purple[600]!,
        0,
        10,
      ),
    ];
  }

  Widget _buildTrendCard(String title, List<double> values, Color color,
      double minY, double maxY) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 16),

            // Simple trend visualization
            Container(
              height: 100,
              child: _buildSimpleTrendChart(values, color, minY, maxY),
            ),

            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${values.length} weeks ago',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(
                    'Latest: ${values.isNotEmpty ? values.first.toStringAsFixed(1) : 'N/A'}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTrendChart(
      List<double> values, Color color, double minY, double maxY) {
    if (values.isEmpty) {
      return Center(
          child: Text('No data', style: TextStyle(color: Colors.grey[600])));
    }

    return CustomPaint(
      size: Size.infinite,
      painter: SimpleTrendPainter(values, color, minY, maxY),
    );
  }

  Widget _buildComplianceTab(Map<String, dynamic> healthData) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          _buildComplianceOverview(healthData),
          SizedBox(height: 16),
          _buildComplianceDetails(healthData),
        ],
      ),
    );
  }

  Widget _buildComplianceOverview(Map<String, dynamic> healthData) {
    final medicineCompliance = healthData['medicineCompliance'] ?? 0;
    final dietCompliance = healthData['dietCompliance'] ?? 0;
    final exerciseCompliance = healthData['exerciseCompliance'] ?? 0;
    final overallCompliance =
        (medicineCompliance + dietCompliance + exerciseCompliance) / 3;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Overall Compliance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: overallCompliance / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getComplianceColor(overallCompliance)),
                  ),
                ),
                Text(
                  '${overallCompliance.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getComplianceColor(overallCompliance),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildComplianceItem(
                    'Medicine', medicineCompliance, Icons.medication),
                _buildComplianceItem('Diet', dietCompliance, Icons.restaurant),
                _buildComplianceItem(
                    'Exercise', exerciseCompliance, Icons.fitness_center),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceItem(String label, double compliance, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _getComplianceColor(compliance), size: 24),
        SizedBox(height: 4),
        Text(
          '${compliance.toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getComplianceColor(compliance),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildComplianceDetails(Map<String, dynamic> healthData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildInsightItem(
              'Medicine Adherence',
              _getMedicineInsight(healthData['medicineCompliance'] ?? 0),
              _getComplianceColor(healthData['medicineCompliance'] ?? 0),
            ),
            _buildInsightItem(
              'Diet Following',
              _getDietInsight(healthData['dietCompliance'] ?? 0),
              _getComplianceColor(healthData['dietCompliance'] ?? 0),
            ),
            _buildInsightItem(
              'Exercise Participation',
              _getExerciseInsight(healthData['exerciseCompliance'] ?? 0),
              _getComplianceColor(healthData['exerciseCompliance'] ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String insight, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4),
          Text(
            insight,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _getMedicineInsight(double compliance) {
    if (compliance >= 90) {
      return 'Excellent adherence. Patient consistently takes medications as prescribed.';
    }
    if (compliance >= 80) {
      return 'Good adherence with occasional missed doses. Monitor for patterns.';
    }
    if (compliance >= 70) {
      return 'Moderate adherence. Consider reminder strategies or simplified regimen.';
    }
    return 'Poor adherence. Immediate intervention needed. Review barriers with patient.';
  }

  String _getDietInsight(double compliance) {
    if (compliance >= 90) {
      return 'Excellent diet compliance. Patient consistently follows meal plan.';
    }
    if (compliance >= 80) {
      return 'Good compliance with occasional modifications. Review preferences.';
    }
    if (compliance >= 70) {
      return 'Moderate compliance. Consider adjusting meal plan for better adherence.';
    }
    return 'Poor diet compliance. Review meal plan feasibility and patient preferences.';
  }

  String _getExerciseInsight(double compliance) {
    if (compliance >= 90) {
      return 'Excellent exercise participation. Patient meets all targets consistently.';
    }
    if (compliance >= 80) {
      return 'Good participation with occasional missed sessions. Encourage consistency.';
    }
    if (compliance >= 70) {
      return 'Moderate participation. Consider adjusting frequency or exercise types.';
    }
    return 'Poor exercise compliance. Review barriers and modify exercise plan if needed.';
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Alerts & Concerns',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          if (_alerts.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                  SizedBox(height: 16),
                  Text('No current alerts',
                      style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold)),
                  Text('Patient is doing well!',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          else
            ..._alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isHighPriority = _isHighPriorityAlert(alert);
    final color = isHighPriority ? Colors.red[600]! : Colors.orange[600]!;
    final icon = isHighPriority ? Icons.warning : Icons.info;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['title'] ?? 'Alert',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(
                    DateTime.parse(alert['createdAt']),
                  ),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              alert['message'] ?? '',
              style: TextStyle(fontSize: 13),
            ),
            if (isHighPriority) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red[600], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Requires immediate attention',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isHighPriorityAlert(Map<String, dynamic> alert) {
    final message = alert['message']?.toLowerCase() ?? '';
    return message.contains('stop') ||
        message.contains('severe') ||
        message.contains('allergic') ||
        alert['wantsToContinue'] == false;
  }

  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Logs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          if (_recentLogs.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.list, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No activity logs',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          else
            ..._recentLogs.map((log) => _buildDetailedLogCard(log)),
        ],
      ),
    );
  }

  Widget _buildDetailedLogCard(Map<String, dynamic> log) {
    final date = DateTime.parse(log['date']);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getLogIcon(log),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getLogTitle(log),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(date),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            if (_getLogDescription(log).isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                _getLogDescription(log),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getLogIcon(Map<String, dynamic> log) {
    final type = log['type'];
    Color color;
    IconData icon;

    switch (type) {
      case 'medicine':
        icon = Icons.medication;
        color = log['taken'] == true ? Colors.green[600]! : Colors.red[600]!;
        break;
      case 'meal':
        icon = Icons.restaurant;
        color = log['eatenAsPrescribed'] == true
            ? Colors.green[600]!
            : Colors.orange[600]!;
        break;
      case 'exercise':
        icon = Icons.fitness_center;
        color =
            log['completed'] == true ? Colors.green[600]! : Colors.red[600]!;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey[600]!;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _getLogTitle(Map<String, dynamic> log) {
    final type = log['type'];

    switch (type) {
      case 'medicine':
        return '${log['taken'] ? 'Took' : 'Missed'} ${log['medicationName']}';
      case 'meal':
        return '${log['eatenAsPrescribed'] ? 'Followed' : 'Modified'} ${log['mealType']}';
      case 'exercise':
        return '${log['completed'] ? 'Completed' : 'Missed'} ${log['exerciseTitle']}';
      default:
        return 'Activity';
    }
  }

  String _getLogDescription(Map<String, dynamic> log) {
    final type = log['type'];
    List<String> details = [];

    switch (type) {
      case 'medicine':
        if (log['effectiveness'] != null) {
          details.add('Effectiveness: ${log['effectiveness']}');
        }
        if (log['sideEffects'] != null && log['sideEffects'] != 'None') {
          details.add('Side effects: ${log['sideEffects']}');
        }
        if (log['missedReason'] != null) {
          details.add('Reason: ${log['missedReason']}');
        }
        break;
      case 'meal':
        if (log['actualFood'] != null) {
          details.add('Ate: ${log['actualFood']}');
        }
        if (log['portions'] != null) {
          details.add('Portion: ${log['portions']}');
        }
        if (log['satisfaction'] != null) {
          details.add('Satisfaction: ${log['satisfaction']}');
        }
        break;
      case 'exercise':
        if (log['difficulty'] != null) {
          details.add('Difficulty: ${log['difficulty']}');
        }
        break;
    }

    if (log['notes'] != null && log['notes'].toString().isNotEmpty) {
      details.add('Notes: ${log['notes']}');
    }

    return details.join(' • ');
  }

  void _showMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Message to Patient'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Message sent to patient!')),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEditPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Treatment Plan'),
        content: Text('Treatment modification features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods for color coding
  Color _getHealthColor(int health) {
    if (health <= 3) return Colors.red[600]!;
    if (health <= 6) return Colors.orange[600]!;
    if (health <= 8) return Colors.yellow[700]!;
    return Colors.green[600]!;
  }

  Color _getComplianceColor(double compliance) {
    if (compliance < 50) return Colors.red[600]!;
    if (compliance < 80) return Colors.orange[600]!;
    return Colors.green[600]!;
  }

  Color _getGodinColor(int godin) {
    if (godin < 20) return Colors.red[600]!;
    if (godin < 40) return Colors.orange[600]!;
    return Colors.green[600]!;
  }

  Color _getSarcfColor(int sarcf) {
    if (sarcf >= 4) return Colors.red[600]!;
    if (sarcf >= 2) return Colors.orange[600]!;
    return Colors.green[600]!;
  }

  Color _getSusColor(double sus) {
    if (sus < 50) return Colors.red[600]!;
    if (sus < 80) return Colors.orange[600]!;
    return Colors.green[600]!;
  }
}

// Simple trend chart painter
class SimpleTrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double minY;
  final double maxY;

  SimpleTrendPainter(this.values, this.color, this.minY, this.maxY);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedY =
          (values[values.length - 1 - i] - minY) / (maxY - minY);
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedY =
          (values[values.length - 1 - i] - minY) / (maxY - minY);
      final y = size.height - (normalizedY * size.height);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
