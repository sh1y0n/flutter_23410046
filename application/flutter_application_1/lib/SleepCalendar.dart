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
  backgroundColor: Colors.grey,
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 40),
      const Text(
        '睡眠カレンダー',
        style: TextStyle(fontSize: 20),
      ),
      const SizedBox(height: 20),
      Image.asset(
        'assets/images/kari.png',
        width: 300,
      )
    ],
  ),  
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        showSelectedLabels: false,    
        showUnselectedLabels: false,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.alarm, color: Colors.black), // アイコンを黒に
              backgroundColor: Colors.grey, // 白に統一
            ),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.timer, color: Colors.black), // アイコンを黒に
              backgroundColor: Colors.grey, // 白に統一
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.home, color: Colors.black), // アイコンを黒に
              backgroundColor: Colors.grey, // 白に統一
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.calendar_today, color: Colors.black), // アイコンを黒に
              backgroundColor: Colors.grey, // 白に統一
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.date_range, color: Colors.black), // アイコンを黒に
              backgroundColor: Colors.grey, // 白に統一
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