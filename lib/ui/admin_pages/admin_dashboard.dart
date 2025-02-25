import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Import Syncfusion Charts

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _studentCount = 0;
  int _parentCount = 0;
  int _schoolPersonnelCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCounts();
  }

  Future<void> _fetchUserCounts() async {
    final firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot studentSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .get();
      QuerySnapshot parentSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .get();
      QuerySnapshot teacherSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Teacher')
          .get();

      setState(() {
        _studentCount = studentSnapshot.size;
        _parentCount = parentSnapshot.size;
        _schoolPersonnelCount = teacherSnapshot.size;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user counts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildLineChart()),
                    const SizedBox(width: 16), // Space between charts
                    Expanded(child: _buildPieChart()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Students Users', '$_studentCount',
                        Colors.lightBlueAccent, Icons.school, 50, 50),
                    _buildStatCard('Parents Users', '$_parentCount',
                        Colors.brown, Icons.person, 50, 50),
                    _buildStatCard('Teachers', '$_schoolPersonnelCount',
                        Colors.orangeAccent, Icons.person_add, 50, 50),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildLineChart() {
    // Sample data for the line chart
    final List<_ChartData> lineChartData = [
      _ChartData('Students', _studentCount),
      _ChartData('Parents', _parentCount),
      _ChartData('Teachers', _schoolPersonnelCount),
    ];

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        title: const ChartTitle(text: 'User Registrations'),
        series: <CartesianSeries<_ChartData, String>>[
          LineSeries<_ChartData, String>(
            name: 'Users',
            dataSource: lineChartData,
            xValueMapper: (_ChartData data, _) => data.role,
            yValueMapper: (_ChartData data, _) => data.count,
            color: Colors.blue,
          ),
        ],
        tooltipBehavior: TooltipBehavior(enable: true),
      ),
    );
  }

  Widget _buildPieChart() {
    final List<_ChartData> pieChartData = [
      _ChartData('Students', _studentCount),
      _ChartData('Parents', _parentCount),
      _ChartData('Teachers', _schoolPersonnelCount),
    ];

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        title: const ChartTitle(text: 'User Distribution'),
        legend: const Legend(isVisible: true),
        series: <CircularSeries<_ChartData, String>>[
          PieSeries<_ChartData, String>(
            dataSource: pieChartData,
            xValueMapper: (_ChartData data, _) => data.role,
            yValueMapper: (_ChartData data, _) => data.count,
            dataLabelMapper: (_ChartData data, _) =>
                '${data.role}: ${data.count}',
            enableTooltip: true,
            pointColorMapper: (_ChartData data, _) {
              switch (data.role) {
                case 'Students':
                  return Colors.lightBlueAccent;
                case 'Parents':
                  return Colors.brown;
                case 'Teachers':
                  return Colors.orangeAccent;
                default:
                  return Colors.grey; // Fallback color
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon,
      double iconSize, double iconHeight) {
    return Expanded(
      child: Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.role, this.count);
  final String role;
  final int count;
}
