import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ★追加
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

  List<AlarmSettings> _alarmList = [
    AlarmSettings(
      id: '1',
      title: '平日のスケジュール',
      wakeUpTime: const TimeOfDay(hour: 7, minute: 0), 
      sleepTime: const TimeOfDay(hour: 23, minute: 0),  
      selectedDays: [true, true, true, true, true, false, false], 
    ),
  ];

  final List<String> _weekDays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  void initState() {
    super.initState();
    _loadAlarmSettings(); // ★起動時に前回の時間を読み込む
    _startClockListener(); 
  }

  @override
  void dispose() {
    _currentTimeTimer?.cancel(); 
    super.dispose();
  }

  // ★スマホから保存されたアラーム時刻を復元する関数
  Future<void> _loadAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWakeUp = prefs.getString('saved_wakeUpTime');
    final savedSleep = prefs.getString('saved_sleepTime');
    final savedIsActive = prefs.getBool('saved_isAlarmActive');

    setState(() {
      if (savedWakeUp != null) {
        final parts = savedWakeUp.split(':');
        _alarmList[0].wakeUpTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (savedSleep != null) {
        final parts = savedSleep.split(':');
        _alarmList[0].sleepTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (savedIsActive != null) {
        _alarmList[0].isActive = savedIsActive;
      }
      
      // 曜日データの復元（文字列からList<bool>へ戻す）
      final savedDaysStr = prefs.getString('saved_activeDays');
      if (savedDaysStr != null) {
        for (int i = 0; i < _weekDays.length; i++) {
          _alarmList[0].selectedDays[i] = savedDaysStr.contains(_weekDays[i]);
        }
      }
    });
  }

  // ★ホーム画面と同期するために、現在のデータをスマホに送り込む関数
  Future<void> _syncToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final alarm = _alarmList[0];

    // 「07:05」のような文字列に整形
    final wakeUpStr = '${alarm.wakeUpTime.hour.toString().padLeft(2, '0')}:${alarm.wakeUpTime.minute.toString().padLeft(2, '0')}';
    final sleepStr = '${alarm.sleepTime.hour.toString().padLeft(2, '0')}:${alarm.sleepTime.minute.toString().padLeft(2, '0')}';

    // 有効な曜日だけを「月・火・水」の文字列に結合
    List<String> activeDaysList = [];
    for (int i = 0; i < alarm.selectedDays.length; i++) {
      if (alarm.selectedDays[i]) {
        activeDaysList.add(_weekDays[i]);
      }
    }
    final activeDaysStr = activeDaysList.isEmpty ? "設定なし" : activeDaysList.join('・');

    // スマホの共有スペースに突っ込む
    await prefs.setString('saved_wakeUpTime', wakeUpStr);
    await prefs.setString('saved_sleepTime', sleepStr);
    await prefs.setString('saved_activeDays', activeDaysStr);
    await prefs.setBool('saved_isAlarmActive', alarm.isActive);
  }

  void _startClockListener() {
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
            _triggerAlarmDialog('☀️ 起床時間です！', '${alarm.title}の起床時刻になりました！朝ですよ！', true);
          }
          if (alarm.sleepTime.hour == currentHour && alarm.sleepTime.minute == currentMinute) {
            alarm.hasFiredToday = true;
            _triggerAlarmDialog('🌙 就寝時間です！', '${alarm.title}の就寝時刻になりました！そろそろおやすみの準備をしましょう。', false);
          }
        }
      }
    });
  }

  void _triggerAlarmDialog(String title, String message, bool isWakeUp) {
    final backgroundColor = isWakeUp ? Colors.red[900] : Colors.grey[850];
    final iconData = isWakeUp ? Icons.alarm_on : Icons.bedtime_rounded;
    final iconColor = isWakeUp ? Colors.white : Colors.amberAccent;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          title: Row(
            children: [
              Icon(iconData, color: iconColor, size: 30),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWakeUp ? Colors.white : Colors.black, 
                foregroundColor: isWakeUp ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _addNewAlarm() {
    setState(() {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _alarmList.add(
        AlarmSettings(
          id: newId,
          title: '新規アラーム ${_alarmList.length + 1}',
          wakeUpTime: const TimeOfDay(hour: 6, minute: 30),
          sleepTime: const TimeOfDay(hour: 22, minute: 30),
          selectedDays: [false, false, false, false, false, false, false],
        ),
      );
    });
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewAlarm,
          ),
        ],
      ),
      body: _alarmList.isEmpty
          ? const Center(child: Text('アラームがありません。右上の＋から追加してください。', style: TextStyle(color: Colors.black)))
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
                            Text(
                              alarm.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Switch(
                              activeColor: Colors.black,
                              value: alarm.isActive,
                              onChanged: (value) {
                                setState(() {
                                  alarm.isActive = value;
                                });
                                _syncToHome(); // ★スイッチON/OFFの瞬間保存
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
                                  _syncToHome(); // ★就寝時間変更の瞬間保存
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('🌙 就寝リマインド', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  Text(
                                    alarm.sleepTime.format(context),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
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
                                  _syncToHome(); // ★起床時間変更の瞬間保存
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('☀️ 起床アラーム', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  Text(
                                    alarm.wakeUpTime.format(context),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
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
                              _syncToHome(); // ★曜日カチカチ切り替えの瞬間保存
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