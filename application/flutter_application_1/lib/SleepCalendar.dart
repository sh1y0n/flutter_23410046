import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart'; 
import 'AlarmPage.dart';
import 'SleepTimerPage.dart';
import 'SleepDate.dart';
import 'main.dart';

class SleepCalendarPage extends StatefulWidget {
  const SleepCalendarPage({super.key, required this.title});

  final String title;

  @override
  State<SleepCalendarPage> createState() => _SleepCalendarPageState();
}

class _SleepCalendarPageState extends State<SleepCalendarPage> {
  int _selectedIndex = 3; 

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, Map<String, dynamic>> _sleepHistory = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllSleepData(); 
  }

  Future<void> _loadAllSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, Map<String, dynamic>> temporaryHistory = {};

    for (String key in keys) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            temporaryHistory[key] = jsonDecode(jsonString);
          } catch (e) {
            print('JSONパースエラー ($key): $e');
          }
        }
      }
    }

    setState(() {
      _sleepHistory = temporaryHistory;
    });
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final key = _formatDateKey(day);
    if (_sleepHistory.containsKey(key)) {
      return [_sleepHistory[key]]; 
    }
    return [];
  }

  String _getShortDurationText(Map<String, dynamic>? data) {
    if (data == null || data['durationMinutes'] == null) return '';
    final int totalMinutes = data['durationMinutes'];
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    
    if (hours == 0) {
      return '${minutes}m'; 
    }
    return '${hours}h'; 
  }

  void _showEditDialog(DateTime targetDay, Map<String, dynamic>? existingData) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDateKey(targetDay);

    String currentQuality = existingData?['quality'] ?? '普通';
    TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);

    if (existingData != null) {
      if (existingData['sleepStartTime'] != null) {
        final dt = DateTime.parse(existingData['sleepStartTime']);
        sleepTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
      if (existingData['wakeUpTime'] != null) {
        final dt = DateTime.parse(existingData['wakeUpTime']);
        wakeUpTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                existingData != null ? '🌙 睡眠記録の修正' : '📝 睡眠記録の新規追加',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('日付: $dateKey', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 20),

                  ListTile(
                    title: const Text('就寝時刻', style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: Text(sleepTime.format(context), style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final selected = await showTimePicker(context: context, initialTime: sleepTime);
                      if (selected != null) {
                        setDialogState(() => sleepTime = selected);
                      }
                    },
                  ),

                  ListTile(
                    title: const Text('起床時刻', style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: Text(wakeUpTime.format(context), style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final selected = await showTimePicker(context: context, initialTime: wakeUpTime);
                      if (selected != null) {
                        setDialogState(() => wakeUpTime = selected);
                      }
                    },
                  ),
                  const Divider(color: Colors.white24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('睡眠の質', style: TextStyle(color: Colors.white, fontSize: 15)),
                      DropdownButton<String>(
                        dropdownColor: Colors.grey[850],
                        value: currentQuality,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        items: <String>['快眠', '普通', '眠い'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() => currentQuality = newValue);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: () async {
                    final sleepDateTime = DateTime(targetDay.year, targetDay.month, targetDay.day, sleepTime.hour, sleepTime.minute);
                    var wakeUpDateTime = DateTime(targetDay.year, targetDay.month, targetDay.day, wakeUpTime.hour, wakeUpTime.minute);
                    if (wakeUpDateTime.isBefore(sleepDateTime)) {
                      wakeUpDateTime = wakeUpDateTime.add(const Duration(days: 1));
                    }

                    final difference = wakeUpDateTime.difference(sleepDateTime);
                    final hours = difference.inHours;
                    final minutes = difference.inMinutes.remainder(60);
                    
                    final updatedData = {
                      'sleepStartTime': sleepDateTime.toIso8601String(),
                      'wakeUpTime': wakeUpDateTime.toIso8601String(),
                      'durationMinutes': difference.inMinutes,
                      'durationText': '$hours時間 ${minutes}分 0秒',
                      'quality': currentQuality,
                    };

                    await prefs.setString(dateKey, jsonEncode(updatedData));
                    _loadAllSleepData();

                    if (!mounted) return;
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$dateKey の記録を更新しました！')),
                    );
                  },
                  child: const Text('保存する'),
                ),
              ],
            );
          },
        );
      },
    );
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
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const MyHomePage(title: 'MainPage'), transitionDuration: Duration.zero));
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => SleepDate(), transitionDuration: Duration.zero));
        break;
    }
  }

  Widget _buildCellContent(DateTime day, String shortRecord, {bool isSelected = false, bool isToday = false}) {
    BoxDecoration decoration = const BoxDecoration();
    Color textColor = Colors.black;

    if (isSelected) {
      decoration = const BoxDecoration(color: Colors.black, shape: BoxShape.circle);
      textColor = Colors.white;
    } else if (isToday) {
      decoration = const BoxDecoration(color: Colors.black, shape: BoxShape.circle);
      textColor = Colors.black;
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2.0),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          if (shortRecord.isNotEmpty)
            Text(
              shortRecord,
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.w600, 
                color: isSelected ? Colors.cyanAccent : Colors.indigo[900]
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedKey = _selectedDay != null ? _formatDateKey(_selectedDay!) : "";
    final dayData = _sleepHistory[selectedKey];

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('睡眠カレンダー'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            rowHeight: 52, 
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final key = _formatDateKey(day);
                final shortRecord = _getShortDurationText(_sleepHistory[key]);
                return _buildCellContent(day, shortRecord);
              },
              outsideBuilder: (context, day, focusedDay) {
                return const SizedBox(); 
              },
              selectedBuilder: (context, day, focusedDay) {
                final key = _formatDateKey(day);
                final shortRecord = _getShortDurationText(_sleepHistory[key]);
                return _buildCellContent(day, shortRecord, isSelected: true);
              },
              todayBuilder: (context, day, focusedDay) {
                final key = _formatDateKey(day);
                final shortRecord = _getShortDurationText(_sleepHistory[key]);
                return _buildCellContent(day, shortRecord, isToday: true);
              },
              // ★ここに空のビルダーを指定することで、余計な丸ポッチが描画されるのを完全に防ぎます
              markerBuilder: (context, day, events) {
                return const SizedBox();
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: _selectedDay == null
                  ? const Center(child: Text('日付を選択してください'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 $selectedKey の詳細',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 15),
                        if (dayData != null) ...[
                          Text('⏳ 睡眠時間: ${dayData['durationText']}', style: const TextStyle(fontSize: 16, color: Colors.black)),
                          const SizedBox(height: 5),
                          Text('😆 睡眠の質: ${dayData['quality']}', style: const TextStyle(fontSize: 16, color: Colors.black)),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              icon: const Icon(Icons.edit),
                              label: const Text('この日の記録を修正する', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showEditDialog(_selectedDay!, dayData),
                            ),
                          ),
                        ] else ...[
                          const Text('この日の睡眠記録はありません。', style: TextStyle(fontSize: 15, color: Colors.black54)),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white70, foregroundColor: Colors.black),
                              icon: const Icon(Icons.add),
                              label: const Text('新しく記録を追加する', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showEditDialog(_selectedDay!, null),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
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