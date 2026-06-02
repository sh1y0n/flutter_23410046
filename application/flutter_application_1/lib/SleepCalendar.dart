import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // ★カレンダーのパッケージをインポート
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
  int _selectedIndex = 3; // カレンダー（インデックス3）を初期選択

  // ★カレンダー用の変数
  CalendarFormat _calendarFormat = CalendarFormat.month; // 月表示モード
  DateTime _focusedDay = DateTime.now();                 // 今日表示されている月
  DateTime? _selectedDay;                                // ユーザーがタップして選択した日

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 最初は今日を選択状態にする
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    // 既存のナビゲーション処理
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const AlarmPage(title: 'Alarm Page'), transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, b) => const SleepTimerPage(title: '睡眠記録'), transitionDuration: Duration.zero));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // カレンダーが見やすいように一旦白にしています
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      // ==========================================
      // ★ body の中に TableCalendar を配置
      // ==========================================
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2026, 1, 1),   // カレンダーの開始日
              lastDay: DateTime.utc(2026, 12, 31), // カレンダーの終了日
              focusedDay: _focusedDay,             // 現在表示する月
              calendarFormat: _calendarFormat,     // 月表示
              
              // 日付が選択された時の見た目の設定
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              
              // 日付をタップした時の処理
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // 月の表示を更新
                });
                
                // デバッグ用：タップした日付をターミナルに表示
                print('選択された日付: $_selectedDay');
              },

              // カレンダーの見た目をシンプルにカスタマイズ（Figmaの黒ベースに合わせやすくするため）
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey, // 今日の日付はグレー
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.black, // 選択した日付は黒
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // 「1か月」などの表示切替ボタンを非表示
                titleCentered: true,        // 月のタイトルを中央寄せ
              ),
            ),
            
            const Divider(height: 30, thickness: 1),
            
            // ★日付の下に、選択した日の詳細（予定や睡眠時間）を出すスペースを作っておく
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_selectedDay?.month}月${_selectedDay?.day}日の睡眠データ\n（ここに後でデータを表示します）',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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