import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/alerts_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(create: (_) => ChatProvider(), child: const WeatherGptApp()),
);

class WeatherGptApp extends StatelessWidget {
  const WeatherGptApp({super.key});
  
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WeatherGPT',
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final screens = const [ChatScreen(), AlertsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
        ],
      ),
    );
  }
}
