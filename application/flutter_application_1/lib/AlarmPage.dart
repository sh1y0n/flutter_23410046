import 'package:flutter/material.dart';
import 'SleepTimerPage.dart';  
import 'SleepCalendar.dart';
import 'SleepDate.dart';
import 'main.dart';

// ★追加：この画面を直接実行（flutter run）した時にリボンを消すための設定
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // ★これで右上の赤い「DEBUG」リボンが消えます！
      home: AlarmPage(title: 'アラーム設定'),
      
    );
  }
}

// --- アラーム1個分のデータを表すクラス ---
class AlarmSettings {
  String id;
  String title;          // アラームの名前（「平日の起床」など）
  TimeOfDay wakeUpTime;  // 起きる時間
  TimeOfDay sleepTime;   // 寝る時間
  List<bool> selectedDays; // 曜日ごとのON/OFF [月, 火, 水, 木, 金, 土, 日]
  bool isActive;         // アラーム自体が有効かどうか

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
  int _selectedIndex = 0; // アラームを初期選択

  // ★複数のアラームを管理するリスト
  List<AlarmSettings> _alarmList = [
    AlarmSettings(
      id: '1',
      title: '平日のスケジュール',
      wakeUpTime: const TimeOfDay(hour: 7, minute: 0),
      sleepTime: const TimeOfDay(hour: 23, minute: 0),
      selectedDays: [true, true, true, true, true, false, false], // 月〜金
    ),
    AlarmSettings(
      id: '2',
      title: '休日のスケジュール',
      wakeUpTime: const TimeOfDay(hour: 9, minute: 0),
      sleepTime: const TimeOfDay(hour: 0, minute: 30),
      selectedDays: [false, false, false, false, false, true, true], // 土日
    ),
  ];

  final List<String> _weekDays = ['月', '火', '水', '木', '金', '土', '日'];

  // ★新しいアラームを追加する関数
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

  // ★時間を設定するポップアップを出す関数
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('アラーム設定'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // ★リボンが消えれば、この右上の「＋」ボタンがちゃんと見えるようになります！
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewAlarm,
          ),
        ],
      ),
      body: _alarmList.isEmpty
          ? const Center(child: Text('アラームがありません。右上の＋から追加してください。'))
          : ListView.builder(
              itemCount: _alarmList.length,
              itemBuilder: (context, index) {
                final alarm = _alarmList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 2,
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Switch(
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
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('🌙 就寝リマインド', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(
                                    alarm.sleepTime.format(context),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.grey),
                            GestureDetector(
                              onTap: () async {
                                final selected = await _selectTime(context, alarm.wakeUpTime);
                                if (selected != null) {
                                  setState(() {
                                    alarm.wakeUpTime = selected;
                                  });
                                }
                              },
                              child: Column(
                                children: [
                                  const Text('☀️ 起床アラーム', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(
                                    alarm.wakeUpTime.format(context),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: Colors.black,
                            selectedColor: Colors.white,
                            fillColor: Colors.black,
                            color: Colors.black,
                            constraints: const BoxConstraints(
                              minHeight: 35.0,
                              minWidth: 40.0,
                            ),
                            isSelected: alarm.selectedDays,
                            children: _weekDays.map((day) => Text(day)).toList(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _alarmList.removeAt(index);
                              });
                            },
                          ),
                        )
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