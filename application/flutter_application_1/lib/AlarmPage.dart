import 'package:flutter/material.dart';
import 'SleepTimerPage.dart';  
import 'SleepCalendar.dart';
import 'SleepDate.dart';

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
      home: const AlarmPage(title: 'Alarm Page'),
    );
  }
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key, required this.title});

  final String title;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  int _selectedIndex = 0; // 初期選択を変更

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
        // ホームなので何もしない
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SleepCalendarPage(title: 'Calendar Page'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
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
      body: Container(), // 空の body でフッターのみのページに
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.alarm, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.timer, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.home, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.calendar_today, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.date_range, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            label: 'Date',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
