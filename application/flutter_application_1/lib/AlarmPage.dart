import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'SleepTimerPage.dart';  
import 'SleepCalendar.dart';
import 'SleepDate.dart';
import 'main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlarmPage(title: 'アラーム設定'),
    );
  }
}

class AlarmSettings {
  String id;
  String title;          
  TimeOfDay wakeUpTime;  
  TimeOfDay sleepTime;   
  List<bool> selectedDays; 
  bool isActive;         
  bool hasFiredToday = false; 

  AlarmSettings({
    required this.id,
    required this.title,
    required this.wakeUpTime,
    required this.sleepTime,
    required this.selectedDays,
    this.isActive = true,
  });
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key, required this.title});

  final String title;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  int _selectedIndex = 0; 
  Timer? _currentTimeTimer; 
  List<AlarmSettings> _alarmList = []; 
  final List<String> _weekDays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  void initState() {
    super.initState();
    _loadInitialTimes(); 
    _startClockListener(); 
  }

  @override
  void dispose() {
    _currentTimeTimer?.cancel(); 
    super.dispose();
  }

  // 保存されている時間を読み込んで画面にセットする
  Future<void> _loadInitialTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedSleep = prefs.getString('saved_sleepTime') ?? "23:00";
    final String savedWake = prefs.getString('saved_wakeUpTime') ?? "07:00";

    // "23:00" などの文字列を TimeOfDay に分解
    final sleepParts = savedSleep.split(':');
    final wakeParts = savedWake.split(':');

    setState(() {
      _alarmList = [
        AlarmSettings(
          id: '1',
          title: '平日のスケジュール',
          sleepTime: TimeOfDay(hour: int.parse(sleepParts[0]), minute: int.parse(sleepParts[1])),
          wakeUpTime: TimeOfDay(hour: int.parse(wakeParts[0]), minute: int.parse(wakeParts[1])),
          selectedDays: [true, true, true, true, true, false, false],
        ),
      ];
    });
  }

  // 睡眠時間とアラーム時間をシンプルに保存する関数
  Future<void> _saveSimpleTimes(TimeOfDay sleep, TimeOfDay wake) async {
    final prefs = await SharedPreferences.getInstance();
    String sleepStr = "${sleep.hour.toString().padLeft(2, '0')}:${sleep.minute.toString().padLeft(2, '0')}";
    String wakeStr = "${wake.hour.toString().padLeft(2, '0')}:${wake.minute.toString().padLeft(2, '0')}";
    
    await prefs.setString('saved_sleepTime', sleepStr);
    await prefs.setString('saved_wakeUpTime', wakeStr);
  }

  void _startClockListener() {
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_alarmList.isEmpty) return;
      final now = DateTime.now();
      final currentWeekday = now.weekday; 
      final currentHour = now.hour;       
      final currentMinute = now.minute;   

      if (now.second == 0) {
        for (var alarm in _alarmList) {
          alarm.hasFiredToday = false;
        }
      }

      for (var alarm in _alarmList) {
        bool isDayOn = alarm.selectedDays[currentWeekday - 1];

        if (alarm.isActive && isDayOn && !alarm.hasFiredToday) {
          if (alarm.wakeUpTime.hour == currentHour && alarm.wakeUpTime.minute == currentMinute) {
            alarm.hasFiredToday = true;
            _triggerAlarmDialog('☀️ 起床時間です！', '${alarm.title}の起床時刻になりました！', true);
          }
          if (alarm.sleepTime.hour == currentHour && alarm.sleepTime.minute == currentMinute) {
            alarm.hasFiredToday = true;
            _triggerAlarmDialog('🌙 就寝時間です！', '${alarm.title}の就寝時刻になりました！', false);
          }
        }
      }
    });
  }

  void _triggerAlarmDialog(String title, String message, bool isWakeUp) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isWakeUp ? Colors.red[900] : Colors.grey[850],
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(context: context, initialTime: initialTime);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepTimerPage(title: 'Timer Page'), transitionDuration: Duration.zero));
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const MyHomePage(title: 'MainPage'), transitionDuration: Duration.zero));
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepCalendarPage(title: 'Calendar Page'), transitionDuration: Duration.zero));
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => SleepDate(), transitionDuration: Duration.zero));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('アラーム設定'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _alarmList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alarmList.length,
              itemBuilder: (context, index) {
                final alarm = _alarmList[index];
                return Card(
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(alarm.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Switch(
                              activeColor: Colors.black,
                              value: alarm.isActive,
                              onChanged: (value) {
                                setState(() {
                                  alarm.isActive = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final selected = await _selectTime(context, alarm.sleepTime);
                                if (selected != null) {
                                  setState(() {
                                    alarm.sleepTime = selected;
                                  });
                                  await _saveSimpleTimes(selected, alarm.wakeUpTime);
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('🌙 就寝リマインド', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  Text(alarm.sleepTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.black54),
                            GestureDetector(
                              onTap: () async {
                                final selected = await _selectTime(context, alarm.wakeUpTime);
                                if (selected != null) {
                                  setState(() {
                                    alarm.wakeUpTime = selected;
                                  });
                                  await _saveSimpleTimes(alarm.sleepTime, selected);
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('☀️ 起床アラーム', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  Text(alarm.wakeUpTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: ToggleButtons(
                            direction: Axis.horizontal,
                            onPressed: (int dayIndex) {
                              setState(() {
                                alarm.selectedDays[dayIndex] = !alarm.selectedDays[dayIndex];
                              });
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: Colors.black,
                            selectedColor: Colors.white,
                            fillColor: Colors.black,
                            color: Colors.black,
                            constraints: const BoxConstraints(minHeight: 35.0, minWidth: 40.0),
                            isSelected: alarm.selectedDays,
                            children: _weekDays.map((day) => Text(day)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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