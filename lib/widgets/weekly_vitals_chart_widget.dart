import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:doctor_app/models/vital_reading.dart';
import 'package:intl/intl.dart';

class WeeklyVitalsChartWidget extends StatefulWidget {
  final String? patientId; // For doctor view

  const WeeklyVitalsChartWidget({Key? key, this.patientId}) : super(key: key);

  @override
  State<WeeklyVitalsChartWidget> createState() =>
      _WeeklyVitalsChartWidgetState();
}

class _WeeklyVitalsChartWidgetState extends State<WeeklyVitalsChartWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<VitalReading> _readings = [];
  bool _isLoading = true;
  String _selectedChart = 'BP'; // 'BP' or 'Sugar'

  @override
  void initState() {
    super.initState();
    _loadWeeklyReadings();
  }

  String get _currentPatientId {
    return widget.patientId ?? _auth.currentUser?.uid ?? '';
  }

  Future<void> _loadWeeklyReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final query = await _firestore
          .collection('vital_readings')
          .where('patientId', isEqualTo: _currentPatientId)
          .where('recordedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('recordedAt', isLessThan: Timestamp.fromDate(weekEnd))
          .orderBy('recordedAt')
          .get();

      _readings = query.docs
          .map((doc) => VitalReading.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading readings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<FlSpot> _getBPSystolicSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _readings.length; i++) {
      if (_readings[i].systolicBP != null) {
        spots.add(FlSpot(i.toDouble(), _readings[i].systolicBP!));
      }
    }
    return spots;
  }

  List<FlSpot> _getBPDiastolicSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _readings.length; i++) {
      if (_readings[i].diastolicBP != null) {
        spots.add(FlSpot(i.toDouble(), _readings[i].diastolicBP!));
      }
    }
    return spots;
  }

  List<FlSpot> _getSugarSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _readings.length; i++) {
      if (_readings[i].sugarLevel != null) {
        spots.add(FlSpot(i.toDouble(), _readings[i].sugarLevel!));
      }
    }
    return spots;
  }

  Widget _buildBPChart() {
    final systolicSpots = _getBPSystolicSpots();
    final diastolicSpots = _getBPDiastolicSpots();

    if (systolicSpots.isEmpty && diastolicSpots.isEmpty) {
      return const Center(
        child: Text(
          'No blood pressure data available for this week',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < _readings.length) {
                    final reading = _readings[value.toInt()];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(reading.recordedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
          minX: 0,
          maxX: _readings.isNotEmpty ? (_readings.length - 1).toDouble() : 6,
          minY: 60,
          maxY: 180,
          lineBarsData: [
            if (systolicSpots.isNotEmpty)
              LineChartBarData(
                spots: systolicSpots,
                isCurved: true,
                color: Colors.red[600],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red[600]!,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            if (diastolicSpots.isNotEmpty)
              LineChartBarData(
                spots: diastolicSpots,
                isCurved: true,
                color: Colors.blue[600],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue[600]!,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSugarChart() {
    final sugarSpots = _getSugarSpots();

    if (sugarSpots.isEmpty) {
      return const Center(
        child: Text(
          'No blood sugar data available for this week',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 25,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < _readings.length) {
                    final reading = _readings[value.toInt()];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(reading.recordedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
          minX: 0,
          maxX: _readings.isNotEmpty ? (_readings.length - 1).toDouble() : 6,
          minY: 70,
          maxY: 200,
          lineBarsData: [
            LineChartBarData(
              spots: sugarSpots,
              isCurved: true,
              color: Colors.purple[600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.purple[600]!,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.purple[100]!.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                  'Weekly Vitals Chart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                ),
                IconButton(
                  onPressed: _loadWeeklyReadings,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chart type selector
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedChart = 'BP';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedChart == 'BP'
                          ? Colors.red[600]
                          : Colors.grey[300],
                      foregroundColor:
                          _selectedChart == 'BP' ? Colors.white : Colors.black,
                    ),
                    child: const Text('Blood Pressure'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedChart = 'Sugar';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedChart == 'Sugar'
                          ? Colors.purple[600]
                          : Colors.grey[300],
                      foregroundColor: _selectedChart == 'Sugar'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Blood Sugar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (_selectedChart == 'BP') ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 8),
                    const Text('Systolic'),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    const Text('Diastolic'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBPChart(),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.purple[600],
                    ),
                    const SizedBox(width: 8),
                    const Text('Blood Sugar (mg/dL)'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSugarChart(),
              ],
            ],
            if (!_isLoading && _readings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No data available for this week.\nStart recording your vitals!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
