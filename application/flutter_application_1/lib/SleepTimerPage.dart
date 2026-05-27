import 'package:flutter/material.dart';
import 'AlarmPage.dart';
import 'SleepCalendar.dart';
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
      home: const SleepTimerPage(title: '睡眠記録'),
    );
  }
}

class SleepTimerPage extends StatefulWidget {
  const SleepTimerPage({super.key, required this.title});

  final String title;

  @override
  State<SleepTimerPage> createState() => _SleepTimerPageState();
}

class _SleepTimerPageState extends State<SleepTimerPage> {
  int _selectedIndex = 1; // Timer を初期選択

  // ==========================================
  // ★ 睡眠計測に必要な変数を定義（ここから追加）
  // ==========================================
  bool _isSleeping = false; // 今寝ているかどうかの状態フラグ
  DateTime? _sleepStartTime; // 就寝ボタンを押した時刻を記録する変数
  String _statusText = 'おやすみボタンを押して計測を開始してください'; // 画面に表示するテキスト

  // ==========================================
  // ★ ボタンが押された時の処理（ロジック）
  // ==========================================
  void _handleSleepButton() {
    setState(() {
      if (!_isSleeping) {
        // 【就寝時の動き】
        _isSleeping = true;
        _sleepStartTime = DateTime.now(); // 現在の時刻（タイムスタンプ）をセット
        _statusText = '睡眠計測中...';
      } else {
        // 【起床時の動き】
        _isSleeping = false;
        final wakeUpTime = DateTime.now(); // 起きた現在の時刻をセット

        if (_sleepStartTime != null) {
          // 起きた時刻と寝た時刻の「差分（Duration）」を計算
          final difference = wakeUpTime.difference(_sleepStartTime!);
          
          final hours = difference.inHours;
          final minutes = difference.inMinutes.remainder(60);
          final seconds = difference.inSeconds.remainder(60); // テスト用に秒数も計算

          _statusText = '今回の睡眠時間:\n$hours時間 $minutes分 $seconds秒';
        }
      }
    });
  }

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
        // Timerなので何もしない
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
            pageBuilder: (context, animation, secondaryAnimation) =>  SleepDate(),
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
      // ==========================================
      // ★ bodyの中身をCenterからColumnを使ったレイアウトへ修正
      // ==========================================
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 現在の状態や、計測結果を表示するテキスト
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40), // パーツ間の隙間
              
              // 計測のON/OFFを切り替えるボタン
              ElevatedButton(
                onPressed: _handleSleepButton, // タップした時に上で作った関数を呼び出す
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSleeping ? Colors.red : Colors.black, // 寝ている間は「赤」、起きている間は「黒」に変化
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  _isSleeping ? '起きる' : 'おやすみなさい',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        showSelectedLabels: false,    
        showUnselectedLabels: false,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.alarm, color: Colors.black),
              backgroundColor: Colors.grey,
            ),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.timer, color: Colors.black),
              backgroundColor: Colors.grey,
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.home, color: Colors.black),
              backgroundColor: Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.calendar_today, color: Colors.black),
              backgroundColor: Colors.grey,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              child: Icon(Icons.date_range, color: Colors.black),
              backgroundColor: Colors.grey,
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