import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  DateTime _focusedMonth = DateTime.now();

  List<double> _monthScores = [];
  List<String> _monthDays = [];

  double _avgAll = 0.0;
  double _avgWeekday = 0.0;
  double _avgWeekend = 0.0;

  // ★ ベストパターンの表示用変数
  String _bestBedTime = '--:--';
  String _bestDuration = '-.-';

  @override
  void initState() {
    super.initState();
    _analyzeMonthSleepLogs();
  }

  Future<void> _analyzeMonthSleepLogs() async {
    final prefs = await SharedPreferences.getInstance();
    
    double totalHoursAll = 0;
    double totalHoursWeekday = 0;
    double totalHoursWeekend = 0;
    int weekdayCount = 0;
    int weekendCount = 0;
    int validLogCount = 0;

    // ベスト時間算出用の変数
    double totalSleepMinutesForBest = 0;
    double totalBedTimeMinutesForBest = 0; // 0:00からの経過分数で計算
    double totalWeight = 0;

    List<double> scores = [];
    List<String> dayLabels = [];

    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1).subtract(const Duration(days: 1));

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      String label = "$day";

      final String? logString = prefs.getString(dateKey);

      if (logString != null && logString.isNotEmpty) {
        try {
          final Map<String, dynamic> log = jsonDecode(logString);
          
          int minutes = log['durationMinutes'] ?? 0;
          double hours = minutes / 60.0;
          
          int weekday = targetDate.weekday; 
          String condition = log['quality'] ?? '普通'; 

          // 1. 本人の睡眠の調子（主観）をベース点数にする
          double score = 60.0;
          double currentWeight = 0; // ベストパターン計算用の重み

          if (condition == '快眠') {
            score = 90.0;
            currentWeight = 2.0; // 快眠は影響度2倍
          } else if (condition == '普通') {
            score = 70.0; 
            currentWeight = 1.0; // 普通は影響度1倍
          } else {
            score = 45.0;
            currentWeight = 0.0; // 眠い日は計算に入れない
          }

          // 2. 生活リズムによる減点ロジック
          if (log['sleepStartTime'] != null && log['wakeUpTime'] != null) {
            final DateTime start = DateTime.parse(log['sleepStartTime']);
            final DateTime wake = DateTime.parse(log['wakeUpTime']);

            if (start.hour >= 3 && start.hour < 5) score -= 20;
            if (wake.hour >= 11 && wake.hour < 15) score -= 20;
            if ((start.hour >= 22 || start.hour <= 1) && (hours >= 6.5 && hours <= 8.5)) score += 10;

            // ★ 快眠・普通の日であれば、ベスト時間算出用のデータを集計
            if (currentWeight > 0) {
              // 就寝時刻を「当日の正午(12:00)」からの経過分数をベースに直す（23時や深夜1時を連続した時間として平均化するため）
              int baseMinutes = start.hour * 60 + start.minute;
              if (start.hour < 12) {
                baseMinutes += 24 * 60; // 深夜・早朝は翌日分として加算
              }
              
              totalBedTimeMinutesForBest += baseMinutes * currentWeight;
              totalSleepMinutesForBest += minutes * currentWeight;
              totalWeight += currentWeight;
            }
          }

          if (score > 100) score = 100;
          if (score < 0) score = 0;

          totalHoursAll += hours;
          if (weekday == 6 || weekday == 7) {
            totalHoursWeekend += hours;
            weekendCount++;
          } else {
            totalHoursWeekday += hours;
            weekdayCount++;
          }

          validLogCount++;
          scores.add(score);
          dayLabels.add(label);

        } catch (e) {
          print('$dateKey のデータ解析エラー: $e');
          scores.add(0.0);
          dayLabels.add(label);
        }
      } else {
        scores.add(0.0);
        dayLabels.add(label);
      }
    }

    // 平均値の計算
    double avgAll = validLogCount > 0 ? totalHoursAll / validLogCount : 0.0;
    double avgWeekday = weekdayCount > 0 ? totalHoursWeekday / weekdayCount : 0.0;
    double avgWeekend = weekendCount > 0 ? totalHoursWeekend / weekendCount : 0.0;

    // ★ ベスト睡眠パターンの最終算出
    String bestBedTimeStr = '--:--';
    String bestDurationStr = '-.-';

    if (totalWeight > 0) {
      // 平均就寝分数を出す
      int avgBedTimeRaw = (totalBedTimeMinutesForBest / totalWeight).round();
      if (avgBedTimeRaw >= 24 * 60) {
        avgBedTimeRaw -= 24 * 60; // 24時間を超えていたら元に戻す
      }
      int bestHour = avgBedTimeRaw ~/ 60;
      int bestMinute = avgBedTimeRaw % 60;
      bestBedTimeStr = "${bestHour.toString().padLeft(2, '0')}:${bestMinute.toString().padLeft(2, '0')}";

      // 平均睡眠時間を出す
      double avgSleepHours = (totalSleepMinutesForBest / totalWeight) / 60.0;
      bestDurationStr = avgSleepHours.toStringAsFixed(1);
    }

    setState(() {
      _monthScores = scores;
      _monthDays = dayLabels;
      _avgAll = double.parse(avgAll.toStringAsFixed(1));
      _avgWeekday = double.parse(avgWeekday.toStringAsFixed(1));
      _avgWeekend = double.parse(avgWeekend.toStringAsFixed(1));
      _bestBedTime = bestBedTimeStr;
      _bestDuration = bestDurationStr;
    });
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment, 1);
    });
    _analyzeMonthSleepLogs(); 
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月切り替えヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => _changeMonth(-1), 
                ),
                Text(
                  '${_focusedMonth.year}年 ${_focusedMonth.month}月',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onPressed: () => _changeMonth(1), 
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              '📊 月間睡眠スコア推移',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.white24, 
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, 
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_monthScores.length, (index) {
                      double score = _monthScores[index];
                      double barHeight = (score / 100.0) * 120;
                      if (barHeight < 0) barHeight = 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0), 
                        child: Column(
                          children: [
                            Text(
                              score > 0 ? '${score.toInt()}' : '-', 
                              style: const TextStyle(color: Colors.black54, fontSize: 9),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 14, 
                              height: barHeight == 0 ? 4 : barHeight,
                              decoration: BoxDecoration(
                                color: score > 0 ? Colors.black : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _monthDays[index], 
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '🕒 ${_focusedMonth.month}月の平均睡眠時間',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.white24,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAverageTile('平日平均', '$_avgWeekday', Colors.black),
                    _buildAverageTile('休日平均', '$_avgWeekend', Colors.black),
                    _buildAverageTile('月間平均', '$_avgAll', Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ★ ここを「ベスト睡眠パターン」のUIにリニューアル！
            Text(
              '✨ ${_focusedMonth.month}月のベスト睡眠パターン',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.white24,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('一番スッキリ眠れた就寝時間', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(_bestBedTime, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('一番スッキリ眠れた睡眠時間', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('$_bestDuration h', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      '※この数値は、あなたが「快眠」および「普通」と回答した日の就寝時刻と睡眠時間を分析し、体が最も調子が良いと感じているリズムを割り出したものです。',
                      style: TextStyle(color: Colors.black45, fontSize: 11, height: 1.4),
                    ),
                  ],
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

  Widget _buildAverageTile(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 8),
        Text('$val h', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}