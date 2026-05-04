import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dto/todoList/todoList.dart';
import '../theme/theme_controller.dart';
import '../utils/DBHelper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _now = DateTime.now();
  Timer? _tick;
  int _todoPendingCount = 0;
  int _todoTotalCount = 0;
  int _localFileCount = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadQuickStats();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final accent = t.accentColor;

    final dateStr = DateFormat('yyyy年M月d日', 'zh_CN').format(_now);
    final weekStr = DateFormat('EEEE', 'zh_CN').format(_now);
    final timeStr = DateFormat('HH:mm:ss').format(_now);

    return ScaffoldPage(
      content: LayoutBuilder(
        builder: (ctx, cons) {
          final twoCols = cons.maxWidth > 980;
          final clockCardWidth = twoCols ? 380.0 : 320.0;
          final progress = _computeProgress(_now);
          final quickStats = _buildQuickStats(progress);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cons.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Card(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Opacity(
                                    opacity: .78,
                                    child: Text(
                                      weekStr,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .5,
                                          fontFeatures: [ui.FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: accent.lighter,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Opacity(
                                          opacity: .95,
                                          child: Text(
                                            _greeting(_now),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: t.resources.cardBackgroundFillColorSecondary.withOpacity(.55),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '今日状态：待办 $_todoPendingCount 项 · 数据已同步',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _Card(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '快捷概览',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 12),
                                  _QuickStatsGrid(items: quickStats),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: clockCardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Card(
                              padding: const EdgeInsets.all(18),
                              child: Center(
                                child: _AnalogClock(
                                  time: _now,
                                  size: twoCols ? 320 : 280,
                                  accent: accent.normal,
                                  faceBase: t.resources.cardBackgroundFillColorDefault,
                                  faceHalo: const Color(0xFFEEF1F5),
                                  tickColor: const Color(0xFFAEB6C2),
                                  numberColor: const Color(0xFF545A64),
                                  hourMinuteColor: const Color(0xFF1E1F22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '今日进度',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _ProgressRingGrid(
                          items: [
                            _RingItem(label: '日', percent: progress.day),
                            _RingItem(label: '周', percent: progress.week),
                            _RingItem(label: '月', percent: progress.month),
                            _RingItem(label: '年', percent: progress.year),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: .7,
                          child: Text(
                            '日${(progress.day * 100).toStringAsFixed(0)}% · '
                            '周${(progress.week * 100).toStringAsFixed(0)}% · '
                            '月${(progress.month * 100).toStringAsFixed(0)}% · '
                            '年${(progress.year * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 6) return '深夜好';
    if (h < 12) return '早上好';
    if (h < 15) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  _Progress _computeProgress(DateTime now) {
    double ratio(DateTime a, DateTime b, DateTime c) {
      final n = a.millisecondsSinceEpoch - b.millisecondsSinceEpoch;
      final d = c.millisecondsSinceEpoch - b.millisecondsSinceEpoch;
      return (n / d).clamp(0, 1);
    }

    final startDay = DateTime(now.year, now.month, now.day);
    final nextDay = startDay.add(const Duration(days: 1));
    final day = ratio(now, startDay, nextDay);

    final startWeek = startDay.subtract(Duration(days: now.weekday - 1));
    final nextWeek = startWeek.add(const Duration(days: 7));
    final week = ratio(now, startWeek, nextWeek);

    final startMonth = DateTime(now.year, now.month);
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1) : DateTime(now.year, now.month + 1);
    final month = ratio(now, startMonth, nextMonth);

    final startYear = DateTime(now.year);
    final nextYear = DateTime(now.year + 1);
    final year = ratio(now, startYear, nextYear);

    return _Progress(day: day, week: week, month: month, year: year);
  }

  List<_QuickStatItem> _buildQuickStats(_Progress progress) {
    final dayPercent = (progress.day * 100).toStringAsFixed(0);
    final weekPercent = (progress.week * 100).toStringAsFixed(0);
    final monthPercent = (progress.month * 100).toStringAsFixed(0);

    return [
      _QuickStatItem(
        title: '待办清单',
        value: '$_todoPendingCount',
        hint: '总任务 $_todoTotalCount 项',
      ),
      _QuickStatItem(
        title: '本日进度',
        value: '$dayPercent%',
        hint: '今天已过 $dayPercent%',
      ),
      _QuickStatItem(
        title: '本周进度',
        value: '$weekPercent%',
        hint: '本月累计 $monthPercent%',
      ),
      _QuickStatItem(
        title: '本地文件',
        value: '$_localFileCount',
        hint: '当前工作目录统计',
      ),
    ];
  }

  Future<void> _loadQuickStats() async {
    await Future.wait([
      _loadTodoStats(),
      _loadLocalFileStats(),
    ]);
  }

  Future<void> _loadTodoStats() async {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      const tableName = TodoList.tableName;
      const columns = TodoList.columns;
      const columnProperties = TodoList.columnsType;

      final dbHelper = DBHelper();
      final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);
      final allRows = await dbHelper.getAll(tableName);
      await db.close();

      final pending = allRows.where((row) {
        final category = (row['category'] ?? '').toString();
        final done = category.contains('完成');
        final waiting = category.contains('待');
        return waiting && !done;
      }).length;

      if (!mounted) return;
      setState(() {
        _todoTotalCount = allRows.length;
        _todoPendingCount = pending;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todoTotalCount = 0;
        _todoPendingCount = 0;
      });
    }
  }

  Future<void> _loadLocalFileStats() async {
    try {
      final root = Directory.current;
      var count = 0;
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          count++;
        }
      }

      if (!mounted) return;
      setState(() {
        _localFileCount = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localFileCount = 0;
      });
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder.withOpacity(0.72), width: 0.8),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 10),
            color: palette.shadow.withOpacity(0.85),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickStatItem {
  const _QuickStatItem({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.items});

  final List<_QuickStatItem> items;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: 170,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.resources.cardBackgroundFillColorSecondary.withOpacity(.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.cardBorder.withOpacity(0.66), width: 0.7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(item.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: .72,
                    child: Text(item.hint, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RingItem {
  const _RingItem({required this.label, required this.percent});

  final String label;
  final double percent;
}

class _ProgressRingGrid extends StatelessWidget {
  const _ProgressRingGrid({required this.items});

  final List<_RingItem> items;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final accent = t.accentColor.normal;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((item) => _ProgressRingCard(
                label: item.label,
                percent: item.percent.clamp(0, 1),
                accent: accent,
                track: t.resources.cardBackgroundFillColorSecondary,
              ))
          .toList(),
    );
  }
}

class _ProgressRingCard extends StatelessWidget {
  const _ProgressRingCard({
    required this.label,
    required this.percent,
    required this.accent,
    required this.track,
  });

  final String label;
  final double percent;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final value = (percent * 100).toStringAsFixed(0);

    return Container(
      width: 128,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.cardBackground.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder.withOpacity(0.64), width: 0.7),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(70, 70),
                  painter: _RingPainter(
                    percent: percent,
                    accent: accent,
                    track: track,
                  ),
                ),
                Text(
                  '$value%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.accent,
    required this.track,
  });

  final double percent;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 8) / 2;
    const start = -pi / 2;
    final sweep = 2 * pi * percent;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [accent.withOpacity(.5), accent],
        startAngle: start,
        endAngle: start + 2 * pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.percent != percent || old.accent != accent || old.track != track;
  }
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock({
    required this.time,
    required this.size,
    required this.accent,
    required this.faceBase,
    required this.faceHalo,
    required this.tickColor,
    required this.numberColor,
    required this.hourMinuteColor,
  });

  final DateTime time;
  final double size;
  final Color accent;
  final Color faceBase;
  final Color faceHalo;
  final Color tickColor;
  final Color numberColor;
  final Color hourMinuteColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClockPainter(
          time: time,
          accent: accent,
          faceBase: faceBase,
          faceHalo: faceHalo,
          tickColor: tickColor,
          numberColor: numberColor,
          hourMinuteColor: hourMinuteColor,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.time,
    required this.accent,
    required this.faceBase,
    required this.faceHalo,
    required this.tickColor,
    required this.numberColor,
    required this.hourMinuteColor,
  });

  final DateTime time;
  final Color accent;
  final Color faceBase;
  final Color faceHalo;
  final Color tickColor;
  final Color numberColor;
  final Color hourMinuteColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final halo = Paint()
      ..color = faceHalo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(c, r - 6, halo);

    final border = Paint()
      ..color = const Color(0x11000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r - 6, border);

    final face = Paint()
      ..shader = RadialGradient(
        colors: [faceBase, const Color(0xFFF7F9FC)],
        center: Alignment.topLeft,
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r - 20, face);

    final tick = Paint()
      ..color = tickColor
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * (i / 60);
      final isHour = i % 5 == 0;
      final len = isHour ? r * .10 : r * .03;
      tick.strokeWidth = isHour ? 2.6 : 1.4;
      final p1 = c + Offset(cos(angle), sin(angle)) * (r - 38 - len);
      final p2 = c + Offset(cos(angle), sin(angle)) * (r - 38);
      canvas.drawLine(p1, p2, tick);
    }

    void drawNum(String s, double deg) {
      final rad = (deg - 90) * pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: 12.5,
            color: numberColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        c + Offset(cos(rad), sin(rad)) * (r - 60) - Offset(tp.width / 2, tp.height / 2),
      );
    }

    for (int i = 1; i <= 12; i++) {
      drawNum('$i', i * 30);
    }

    final h = time.hour % 12;
    final m = time.minute;
    final s = time.second;

    final hourAngle = 2 * pi * ((h + m / 60 + s / 3600) / 12);
    final minuteAngle = 2 * pi * ((m + s / 60) / 60);
    final secondAngle = 2 * pi * (s / 60);
    final minuteProgress = (m + s / 60) / 60;
    final secondProgress = s / 60;

    final hourPaint = Paint()
      ..color = hourMinuteColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    final minutePaint = Paint()
      ..color = hourMinuteColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    final secondPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    Offset hand(double a, double len) => c + Offset(cos(a - pi / 2), sin(a - pi / 2)) * len;

    canvas.drawLine(c, hand(hourAngle, r * .42), hourPaint);
    canvas.drawLine(c, hand(minuteAngle, r * .60), minutePaint);
    canvas.drawLine(c, hand(secondAngle, r * .66), secondPaint);
    canvas.drawLine(c, hand(secondAngle + pi, r * .14), secondPaint);

    final hub = Paint()..color = accent;
    canvas.drawCircle(c, 4.2, hub);
    canvas.drawCircle(hand(secondAngle + pi, r * .14), 3.0, hub);

    final outerTrack = Paint()
      ..color = tickColor.withOpacity(.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(c, r - 6, outerTrack);

    final minuteRing = Paint()
      ..color = accent.withOpacity(.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 6),
      -pi / 2,
      2 * pi * minuteProgress,
      false,
      minuteRing,
    );

    final secondTrack = Paint()
      ..color = tickColor.withOpacity(.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, r - 17, secondTrack);

    final secondRing = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 17),
      -pi / 2,
      2 * pi * secondProgress,
      false,
      secondRing,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) {
    return old.time.second != time.second || old.accent != accent || old.faceBase != faceBase;
  }
}

class _Progress {
  const _Progress({
    required this.day,
    required this.week,
    required this.month,
    required this.year,
  });

  final double day;
  final double week;
  final double month;
  final double year;
}
