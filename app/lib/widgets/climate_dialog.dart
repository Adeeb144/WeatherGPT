import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class ClimateDialog extends StatefulWidget {
  const ClimateDialog({super.key});

  @override
  State<ClimateDialog> createState() => _ClimateDialogState();
}

class _ClimateDialogState extends State<ClimateDialog> {
  final _api = ApiService();
  final _loc = LocationService();
  bool loading = true;
  String? error;
  List<dynamic> monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pos = await _loc.current();
    if (pos == null) {
      setState(() { error = 'Location required for climate trends.'; loading = false; });
      return;
    }
    final res = await _api.getClimate('${pos.latitude},${pos.longitude}');
    setState(() {
      loading = false;
      if (res.containsKey('error')) {
        error = res['error'];
      } else {
        monthlyData = res['monthly'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Climate Trends (Last 12 Mo)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : monthlyData.isEmpty
                    ? const Center(child: Text('No data found'))
                    : LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                    final monthStr = monthlyData[value.toInt()]['month'] as String;
                                    final shortMonth = monthStr.substring(5); // e.g., '08'
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(shortMonth, style: const TextStyle(fontSize: 10)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: monthlyData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), (e.value['avg_temp'] as num).toDouble());
                              }).toList(),
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    );
  }
}
