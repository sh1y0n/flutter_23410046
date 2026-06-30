import 'dart:convert'; // ★JSON変換用
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AlarmPage.dart';
import 'SleepCalendar.dart';
import 'SleepDate.dart';
import 'main.dart';

class SleepTimerPage extends StatefulWidget {
  const SleepTimerPage({super.key, required this.title});

  final String title;

  @override
  State<SleepTimerPage> createState() => _SleepTimerPageState();
}

class _SleepTimerPageState extends State<SleepTimerPage> {
  int _selectedIndex = 1; 

  // --- 状態管理用の変数 ---
  bool _isCounting = false;    
  DateTime? _sleepStartTime;   
  String _statusText = '読み込み中...';
  String _sleepQuality = "未記録"; 
  String _lastResultText = "";     

  @override
  void initState() {
    super.initState();
    _loadSleepStatus(); 
  }

  Future<void> _loadSleepStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCounting = prefs.getBool('isCounting') ?? false;
      final startTimeStr = prefs.getString('sleepStartTime');
      if (startTimeStr != null) {
        _sleepStartTime = DateTime.parse(startTimeStr);
      }

      _sleepQuality = prefs.getString('lastSleepQuality') ?? "未記録";
      _lastResultText = prefs.getString('lastSleepResult') ?? "";

      if (_isCounting) {
        _statusText = '就寝中...';
      } else {
        _statusText = '起きています';
      }
    });
  }

  Future<void> _handleTimerButton() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isCounting) {
      // 【就寝開始】
      final now = DateTime.now();
      setState(() {
        _isCounting = true;
        _sleepStartTime = now;
        _statusText = '就寝中...';
      });

      await prefs.setBool('isCounting', true);
      await prefs.setString('sleepStartTime', now.toIso8601String());
    } else {
      // 【起床（計測停止）】
      setState(() {
        _isCounting = false;
        _statusText = '起きています';
      });

      await prefs.setBool('isCounting', false);

      // 睡眠の質を選ばせるポップアップを起動
      _showQualitySelectionDialog(prefs);
    }
  }

  void _showQualitySelectionDialog(SharedPreferences prefs) {
    final wakeUpTime = DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '睡眠の質はどうでしたか？',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '今の気分に一番近いものを選択してください。',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // ★このボタンを押したときの「中身のデータ」が分析画面に送られます！
              _buildQualityButton(context, prefs, '😆 快眠（スッキリ）', '快眠', wakeUpTime),
              _buildQualityButton(context, prefs, '🙂 普通（いつも通り）', '普通', wakeUpTime),
              _buildQualityButton(context, prefs, '🥱 眠い（寝足りない）', '眠い', wakeUpTime),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityButton(BuildContext context, SharedPreferences prefs, String label, String value, DateTime wakeUpTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            String durationText = "0分";
            int durationMinutes = 0;

            if (_sleepStartTime != null) {
              final difference = wakeUpTime.difference(_sleepStartTime!);
              final hours = difference.inHours;
              final minutes = difference.inMinutes.remainder(60);
              final seconds = difference.inSeconds.remainder(60);
              durationText = '$hours時間 $minutes分 $seconds秒';
              
              durationMinutes = difference.inMinutes; // データの合計分数
            }

            // 寝た日の日付をキーにする
            final targetDate = _sleepStartTime ?? DateTime.now();
            final dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

            // ★カレンダー＆分析画面と完全に共有するJSON用マップデータ
            final sleepData = {
              'sleepStartTime': _sleepStartTime?.toIso8601String(),
              'wakeUpTime': wakeUpTime.toIso8601String(),
              'durationMinutes': durationMinutes,
              'durationText': durationText,
              'quality': value, // ★ここに「快眠」などの文字がカチッと入ります
            };

            // 日付をキーにしてローカルストレージに確定保存
            await prefs.setString(dateKey, jsonEncode(sleepData));

            // 前回の表示用データも更新
            await prefs.setString('lastSleepQuality', value);
            await prefs.setString('lastSleepResult', durationText);
            await prefs.remove('sleepStartTime'); 

            setState(() {
              _sleepQuality = value;
              _lastResultText = durationText;
            });

            Navigator.of(context).pop(); 
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('[$dateKey] に「$value」の記録を保存しました！')),
            );
          },
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
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
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const MyHomePage(title: 'MainPage'), transitionDuration: Duration.zero));
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
        title: const Text('睡眠記録'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCounting ? Icons.bedtime : Icons.wb_sunny_rounded,
              size: 100,
              color: _isCounting ? Colors.indigo : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            
            if (_lastResultText.isNotEmpty) ...[
              Card(
                color: Colors.white24,
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('【前回の睡眠記録】', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('睡眠時間: $_lastResultText', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('睡眠の質: $_sleepQuality', style: const TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),

            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCounting ? Colors.red : Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _handleTimerButton, 
                child: Text(
                  _isCounting ? '起きる（計測停止）' : '寝る（計測開始）',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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