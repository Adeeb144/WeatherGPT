import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _api = ApiService();
  final _loc = LocationService();
  bool loading = true;
  String? error;
  List<dynamic> alerts = [];
  String place = "your location";

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() { loading = true; error = null; });
    final pos = await _loc.current();
    if (pos == null) {
      setState(() { error = 'Location permission denied or unavailable. Cannot fetch local alerts.'; loading = false; });
      return;
    }
    
    final res = await _api.getAlerts('${pos.latitude},${pos.longitude}');
    setState(() {
      loading = false;
      if (res.containsKey('error')) {
        error = res['error'];
      } else {
        alerts = res['alerts'] ?? [];
        place = res['place']?['name'] ?? 'your location';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alerts for $place')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ))
              : alerts.isEmpty
                  ? const Center(child: Text('No severe weather alerts for your location.', style: TextStyle(fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _loadAlerts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          final severity = alert['severity'];
                          Color cardColor = Colors.yellow[100]!;
                          Color iconColor = Colors.orange;
                          if (severity == 'red') {
                            cardColor = Colors.red[100]!;
                            iconColor = Colors.red;
                          } else if (severity == 'orange') {
                            cardColor = Colors.orange[100]!;
                            iconColor = Colors.deepOrange;
                          }
                          
                          return Card(
                            color: cardColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.warning, color: iconColor, size: 40),
                              title: Text(alert['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${alert['date']}\n${alert['detail']}'),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
