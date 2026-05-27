import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 保存パッケージの読み込み
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

  // --- 睡眠計測・フラグ管理用の変数 ---
  bool _isSleeping = false; // 今寝ているかどうかのフラグ（0か1かの状態）
  DateTime? _sleepStartTime; // 就寝ボタンを押した時刻を記録する変数
  String _statusText = '読み込み中...'; // 初期状態

  @override
  void initState() {
    super.initState();
    _loadSleepStatus(); // アプリ起動時に、スマホのストレージに保存されたフラグをチェックする
  }

  // ★スマホの保存スペースからフラグと時間を読み出す関数
  Future<void> _loadSleepStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 保存されていたフラグ（true/false）を読み込む。データがなければfalse（0）にする
      _isSleeping = prefs.getBool('isSleeping') ?? false; 
      
      final startTimeStr = prefs.getString('sleepStartTime');
      if (startTimeStr != null) {
        _sleepStartTime = DateTime.parse(startTimeStr); // 文字列から日時に復元
      }

      // 読み込んだフラグの状態によって、起動時の画面表示を自動で切り替える
      if (_isSleeping) {
        _statusText = '睡眠計測中...\n（アプリを閉じても計測は続いています）';
      } else {
        _statusText = 'おやすみボタンを押して計測を開始してください';
      }
    });
  }

  // ★ボタンが押された時の処理（フラグの保存と切り替え）
  Future<void> _handleSleepButton() async {
    final prefs = await SharedPreferences.getInstance(); // スマホの保存スペースを開く

    setState(() {
      if (!_isSleeping) {
        // 【就寝時：フラグを1(true)にして保存】
        _isSleeping = true;
        _sleepStartTime = DateTime.now();
        _statusText = '睡眠計測中...\n（アプリを閉じても計測は続いています）';

        // スマホのストレージに状態を直接書き込む
        prefs.setBool('isSleeping', true); // フラグを保存
        prefs.setString('sleepStartTime', _sleepStartTime!.toIso8601String()); // 時間を保存
      } else {
        // 【起床時：計算してフラグを0(false)に戻す】
        _isSleeping = false;
        final wakeUpTime = DateTime.now();

        if (_sleepStartTime != null) {
          // 起きた時間と保存されていた寝た時間の引き算
          final difference = wakeUpTime.difference(_sleepStartTime!);
          final hours = difference.inHours;
          final minutes = difference.inMinutes.remainder(60);
          final seconds = difference.inSeconds.remainder(60);

          _statusText = '今回の睡眠時間:\n$hours時間 $minutes分 $seconds秒';
        }

        // 起きたので、スマホ内の就寝中フラグと時間をリセット（削除）する
        prefs.setBool('isSleeping', false);
        prefs.remove('sleepStartTime');
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _handleSleepButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSleeping ? Colors.red : Colors.black, // フラグ状態によって色が変わる
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  _isSleeping ? '起きた' : 'おやすみなさい',
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
            icon: CircleAvatar(child: Icon(Icons.alarm, color: Colors.black), backgroundColor: Colors.grey),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(child: Icon(Icons.timer, color: Colors.black), backgroundColor: Colors.grey),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(child: Icon(Icons.home, color: Colors.black), backgroundColor: Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(child: Icon(Icons.calendar_today, color: Colors.black), backgroundColor: Colors.grey),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(child: Icon(Icons.date_range, color: Colors.black), backgroundColor: Colors.grey),
            label: 'Date',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}