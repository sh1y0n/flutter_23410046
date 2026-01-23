import 'package:flutter/material.dart';
import 'AlarmPage.dart';
import 'SleepTimerPage.dart';  
import 'SleepDate.dart';
import 'main.dart'; // MyHomePage をインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SleepCalendarPage(title: 'カレンダー'),
    );
  }
}

class SleepCalendarPage extends StatefulWidget {
  const SleepCalendarPage({super.key, required this.title});

  final String title;

  @override
  State<SleepCalendarPage> createState() => _SleepCalendarPageState();
}

class _SleepCalendarPageState extends State<SleepCalendarPage> {
  int _selectedIndex = 3; // Calendar を初期選択

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AlarmPage(title: 'Alarm Page'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SleepTimerPage(title: 'Timer Page'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(title: 'MainPage'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        // Calendarなので何もしない
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SleepDate(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.alarm, color: Colors.white),
              backgroundColor: Colors.black,
            ),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.timer, color: Colors.white),
              backgroundColor: Colors.black,
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.home, color: Colors.white),
              backgroundColor: Colors.black,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.calendar_today, color: Colors.white),
              backgroundColor: Colors.black,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.date_range, color: Colors.white),
              backgroundColor: Colors.black,
            ),
            label: 'Date',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
