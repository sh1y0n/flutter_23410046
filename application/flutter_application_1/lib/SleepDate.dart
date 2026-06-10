import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ★データ読み込み用
import 'AlarmPage.dart';
import 'SleepTimerPage.dart';
import 'SleepCalendar.dart';
import 'main.dart';

class SleepDate extends StatefulWidget {
  const SleepDate({super.key});

  @override
  State<SleepDate> createState() => _SleepDateState();
}

class _SleepDateState extends State<SleepDate> {
  int _selectedIndex = 4; 

  // --- 計算されたリアルタイムデータを格納する変数 ---
  String _averageSleepTime = "計算中...";
  String _bestConditionTime = "計算中...";
  final String _sleepEfficiency = "88%"; // 固定のモック（デザイン用）
  final String _socialJetlag = "1時間15分"; // 固定のモック（デザイン用）

  @override
  void initState() {
    super.initState();
    _calculateSleepAnalytics(); // ★画面が開いた瞬間にデータを集計・計算する
  }

  // ★カレンダーの全データを走査して平均などを割り出す関数
  Future<void> _calculateSleepAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int totalMinutes = 0;
    int totalCount = 0;

    int bestTotalMinutes = 0;
    int bestCount = 0;

    for (String key in keys) {
      // YYYY-MM-DD 形式のデータ（カレンダーの記録）だけを対象にする
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(jsonString);
            final int minutes = data['durationMinutes'] ?? 0;
            final String quality = data['quality'] ?? '普通';

            if (minutes > 0) {
              // ① 全体の平均用カウント
              totalMinutes += minutes;
              totalCount++;

              // ② 調子がいいとき（快眠）だけの平均用カウント
              if (quality == '快眠') {
                bestTotalMinutes += minutes;
                bestCount++;
              }
            }
          } catch (e) {
            print('JSONパースエラー: $e');
          }
        }
      }
    }

    setState(() {
      // 全体平均の計算とテキスト整形
      if (totalCount > 0) {
        final int avgMinutes = totalMinutes ~/ totalCount;
        _averageSleepTime = '${avgMinutes ~/ 60}時間 ${avgMinutes % 60}分';
      } else {
        _averageSleepTime = '--時間 --分';
      }

      // 快眠平均の計算とテキスト整形
      if (bestCount > 0) {
        final int avgBestMinutes = bestTotalMinutes ~/ bestCount;
        _bestConditionTime = '${avgBestMinutes ~/ 60}時間 ${avgBestMinutes % 60}分';
      } else {
        _bestConditionTime = '--時間 --分';
      }
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
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const MyHomePage(title: 'MainPage'), transitionDuration: Duration.zero));
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepCalendarPage(title: 'Calendar Page'), transitionDuration: Duration.zero));
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey, 
      appBar: AppBar(
        title: const Text('睡眠データ分析'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '【睡眠ステータス】',
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          _buildDataItem(
            icon: Icons.access_time_rounded,
            iconColor: Colors.blueAccent,
            title: '平均睡眠時間',
            value: _averageSleepTime, // ★リアルタイムに変動
            description: 'これまでにカレンダーに記録された全データの平均時間です。',
          ),
          _buildDataItem(
            icon: Icons.sentiment_satisfied_alt_rounded,
            iconColor: Colors.orangeAccent,
            title: '調子がいいときの睡眠時間',
            value: _bestConditionTime, // ★快眠データのみの平均
            description: 'タイマー停止時やカレンダーで「快眠」と選んだ日の平均です。',
          ),
          _buildDataItem(
            icon: Icons.bolt_rounded,
            iconColor: Colors.purpleAccent,
            title: '直近1週間の睡眠効率',
            value: _sleepEfficiency,
            description: '布団に入っている時間と実際に寝ている時間の割合です。',
          ),
          _buildDataItem(
            icon: Icons.sync_alt_rounded,
            iconColor: Colors.redAccent,
            title: '平日と休日の睡眠ズレ',
            value: _socialJetlag,
            description: '平日のアラームと休日のアラームの差によるズレです。',
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

  Widget _buildDataItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String description,
  }) {
    return Card(
      color: Colors.white24, 
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}