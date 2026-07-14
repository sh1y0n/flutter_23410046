import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'AlarmPage.dart';
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: MyHomePage(title: 'MainPage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; 

  // --- 状態管理用の変数 ---
  bool _isSleepingNow = false; 
  String _latestAlarmTime = "07:00"; 
  String _latestSleepTime = "23:00"; 
  String _activeDaysStr = "月・火・水・木・金"; 
  bool _isAlarmActive = true;
  bool _hasAlarm = false;

  @override
  void initState() {
    super.initState();
    _loadAlarmAndTimerStatus(); 
  }

  String _formatActiveDays(List<dynamic>? selectedDays) {
    if (selectedDays == null || selectedDays.isEmpty) return '設定なし';
    final names = ['月', '火', '水', '木', '金', '土', '日'];
    final active = <String>[];
    for (var i = 0; i < selectedDays.length && i < names.length; i++) {
      if (selectedDays[i] == true) active.add(names[i]);
    }
    if (active.isEmpty) return '指定なし';
    if (active.length == 7) return '毎日';
    return active.join('・');
  }

  // 起動時にSharedPreferencesのシンプルデータを直接読み込む
  Future<void> _loadAlarmAndTimerStatus() async {
    final prefs = await SharedPreferences.getInstance();

    bool hasAlarm = false;
    bool isActive = true;
    String latestSleep = "23:00";
    String latestAlarm = "07:00";
    String activeDays = "月・火・水・木・金";

    if (prefs.containsKey('alarm_list')) {
      final jsonStr = prefs.getString('alarm_list') ?? '[]';
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      if (decoded.isNotEmpty) {
        final first = decoded.first as Map<String, dynamic>;
        final sleep = first['sleepTime'] as Map<String, dynamic>;
        final wake = first['wakeUpTime'] as Map<String, dynamic>;
        latestSleep = '${(sleep['hour'] as int).toString().padLeft(2, '0')}:${(sleep['minute'] as int).toString().padLeft(2, '0')}';
        latestAlarm = '${(wake['hour'] as int).toString().padLeft(2, '0')}:${(wake['minute'] as int).toString().padLeft(2, '0')}';
        isActive = first['isActive'] as bool? ?? true;
        activeDays = _formatActiveDays(first['selectedDays'] as List<dynamic>?);
        hasAlarm = true;
      }
    }

    if (!hasAlarm && prefs.containsKey('saved_sleepTime') && prefs.containsKey('saved_wakeUpTime')) {
      latestSleep = prefs.getString('saved_sleepTime') ?? latestSleep;
      latestAlarm = prefs.getString('saved_wakeUpTime') ?? latestAlarm;
      hasAlarm = true;
    }

    setState(() {
      _isSleepingNow = prefs.getBool('isCounting') ?? false;
      _latestSleepTime = latestSleep;
      _latestAlarmTime = latestAlarm;
      _isAlarmActive = isActive;
      _hasAlarm = hasAlarm;
      _activeDaysStr = activeDays;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const AlarmPage(title: 'Alarm Page'), transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepTimerPage(title: 'Timer Page'), transitionDuration: Duration.zero));
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepCalendarPage(title: 'Calendar Page'), transitionDuration: Duration.zero));
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepDate(), transitionDuration: Duration.zero));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey, 
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'こんにちは！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),

            const Text(
              '【現在の睡眠ステータス】',
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white24, 
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isSleepingNow ? Icons.bedtime : Icons.wb_sunny_rounded,
                      color: _isSleepingNow ? Colors.indigo : Colors.orange,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSleepingNow ? '現在、睡眠を計測中です' : '現在は起きています',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSleepingNow ? '起きたらタイマー画面で停止してください。' : '寝る前にタイマー画面で開始してください。',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '【最新のアラーム設定】',
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white24, 
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '次の予定スケジュール',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isAlarmActive ? Colors.black : Colors.grey[700], 
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isAlarmActive ? 'ON' : 'OFF',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.black26),
                    if (_hasAlarm) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('🌙 就寝時間', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(_latestSleepTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.black54),
                          Column(
                            children: [
                              const Text('☀️ 起床時間', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(_latestAlarmTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.black26),
                      Row(
                        children: [
                          const Icon(Icons.repeat, color: Colors.black54, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '対象曜日: $_activeDaysStr',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        '現在、設定されたアラームはありません。\nアラーム画面の右上「＋」から追加できます。',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, 
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Text(
                  'アラームの設定・変更はこちら',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline), 
                ),
                label: const Icon(Icons.arrow_forward_ios, size: 12), 
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    PageRouteBuilder(
                      pageBuilder: (context, a, b) => const AlarmPage(title: 'Alarm Page'), 
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        showSelectedLabels: false,    
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: CircleAvatar(child: Icon(Icons.alarm, color: Colors.black), backgroundColor: Colors.grey), label: 'Alarm'),
          BottomNavigationBarItem(icon: CircleAvatar(child: Icon(Icons.timer, color: Colors.black), backgroundColor: Colors.grey), label: 'Timer'),
          BottomNavigationBarItem(icon: CircleAvatar(child: Icon(Icons.home, color: Colors.black), backgroundColor: Colors.grey), label: 'Home'),
          BottomNavigationBarItem(icon: CircleAvatar(child: Icon(Icons.calendar_today, color: Colors.black), backgroundColor: Colors.grey), label: 'Calendar'),
          BottomNavigationBarItem(icon: CircleAvatar(child: Icon(Icons.date_range, color: Colors.black), backgroundColor: Colors.grey), label: 'Date'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}