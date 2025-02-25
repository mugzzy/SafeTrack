import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AttendanceReportChart extends StatelessWidget {
  final int presentCount;
  final int lateCount;
  final int absentCount;

  const AttendanceReportChart({
    Key? key,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData('Present', presentCount, Colors.green),
      ChartData('Late', lateCount, Colors.orange),
      ChartData('Absent', absentCount, Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report Chart'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SfCircularChart(
                title: ChartTitle(text: 'Attendance Overview'),
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.status,
                    yValueMapper: (ChartData data, _) => data.count,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detailed Report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Present: $presentCount',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Late: $lateCount',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Absent: $absentCount',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Attendance Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have attended ${presentCount + lateCount} out of ${presentCount + lateCount + absentCount} events.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your attendance rate is ${((presentCount + lateCount) / (presentCount + lateCount + absentCount) * 100).toStringAsFixed(2)}%.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.status, this.count, this.color);
  final String status;
  final int count;
  final Color color;
}
