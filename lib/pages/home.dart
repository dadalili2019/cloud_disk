import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dto/todoList/todoList.dart';
import '../theme/theme_controller.dart';
import '../utils/DBHelper.dart';
import '../widgets/app_surfaces.dart';

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
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final progress = _computeProgress(_now);

    return ScaffoldPage(
      content: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final showMascot = constraints.maxWidth >= 560;

          return Container(
            color: palette.appBackground,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: max(0, constraints.maxHeight - 40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TodayCard(
                              now: _now,
                              pendingCount: _todoPendingCount,
                              showMascot: showMascot,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 300,
                            child: _ProgressCard(
                              now: _now,
                              progress: progress,
                              accent: theme.accentColor.normal,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _TodayCard(
                        now: _now,
                        pendingCount: _todoPendingCount,
                        showMascot: showMascot,
                      ),
                      const SizedBox(height: 12),
                      _ProgressCard(
                        now: _now,
                        progress: progress,
                        accent: theme.accentColor.normal,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CloudCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel(
                            title: '快捷概览',
                            trailing: SoftPill(
                              label: '数据已同步',
                              icon: FluentIcons.sync,
                              backgroundColor: palette.successSoft,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StatsGrid(
                            pendingCount: _todoPendingCount,
                            totalCount: _todoTotalCount,
                            localFileCount: _localFileCount,
                            progress: progress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final nextMonth = now.month == 12
        ? DateTime(now.year + 1, 1)
        : DateTime(now.year, now.month + 1);
    final month = ratio(now, startMonth, nextMonth);

    final startYear = DateTime(now.year);
    final nextYear = DateTime(now.year + 1);
    final year = ratio(now, startYear, nextYear);

    return _Progress(day: day, week: week, month: month, year: year);
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
      await for (final entity
          in root.list(recursive: true, followLinks: false)) {
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.now,
    required this.pendingCount,
    required this.showMascot,
  });

  final DateTime now;
  final int pendingCount;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final dateStr = DateFormat('yyyy年M月d日', 'zh_CN').format(now);
    final weekStr = DateFormat('EEEE', 'zh_CN').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    return CloudCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SoftPill(
                      label: _greeting(now),
                      icon: FluentIcons.clock,
                      backgroundColor: palette.dangerSoft,
                    ),
                    const SizedBox(width: 8),
                    SoftPill(
                      label: weekStr,
                      backgroundColor: palette.softAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Microsoft YaHei UI',
                    letterSpacing: 0,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Segoe UI',
                    letterSpacing: 0,
                    color: Color(0xFF202124),
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '今日状态：待办 $pendingCount 项 · 数据已同步',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showMascot) ...[
            const SizedBox(width: 16),
            _MascotBubble(),
          ],
        ],
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
}

class _MascotBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.dangerSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: palette.cardBorder.withOpacity(0.45),
          width: 0.8,
        ),
      ),
      child: SvgPicture.asset(
        'assets/login/小猫.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(
          FluentIcons.info,
          color: FluentTheme.of(context).accentColor.normal,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.now,
    required this.progress,
    required this.accent,
  });

  final DateTime now;
  final _Progress progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final dayPercent = (progress.day * 100).toStringAsFixed(0);
    final clockAccent = Color.lerp(accent, const Color(0xFF6EBB8F), 0.65)!;

    return CloudCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: palette.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: CustomPaint(
                  painter: _MiniClockPainter(
                    time: now,
                    accent: clockAccent,
                    track: palette.cardBorder,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日进度',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dayPercent%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: Color(0xFF202124),
                      ),
                    ),
                    Opacity(
                      opacity: 0.68,
                      child: Text(
                        '今天已经过去 $dayPercent%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressLine(
              label: '日',
              percent: progress.day,
              color: const Color(0xFF6EBB8F)),
          _ProgressLine(
              label: '周',
              percent: progress.week,
              color: const Color(0xFF83AEE8)),
          _ProgressLine(
              label: '月',
              percent: progress.month,
              color: const Color(0xFF7FB79B)),
          _ProgressLine(
              label: '年',
              percent: progress.year,
              color: const Color(0xFFE29AAF)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.pendingCount,
    required this.totalCount,
    required this.localFileCount,
    required this.progress,
  });

  final int pendingCount;
  final int totalCount;
  final int localFileCount;
  final _Progress progress;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final dayPercent = (progress.day * 100).toStringAsFixed(0);
    final weekPercent = (progress.week * 100).toStringAsFixed(0);
    final monthPercent = (progress.month * 100).toStringAsFixed(0);

    final items = [
      StatTile(
        icon: FluentIcons.to_do_logo_inverse,
        label: '待办清单',
        value: '$pendingCount',
        caption: '总任务 $totalCount 项',
        accentColor: const Color(0xFF3E8B68),
        backgroundColor: palette.successSoft,
      ),
      StatTile(
        icon: FluentIcons.clock,
        label: '本日进度',
        value: '$dayPercent%',
        caption: '今天已过 $dayPercent%',
        accentColor: const Color(0xFF5C8FE8),
        backgroundColor: palette.softAccent,
      ),
      StatTile(
        icon: FluentIcons.calendar,
        label: '本周进度',
        value: '$weekPercent%',
        caption: '本月累计 $monthPercent%',
        accentColor: const Color(0xFFD77C96),
        backgroundColor: palette.dangerSoft,
      ),
      StatTile(
        icon: FluentIcons.fabric_folder_fill,
        label: '本地文件',
        value: '$localFileCount',
        caption: '当前工作目录统计',
        accentColor: const Color(0xFF9A79D7),
        backgroundColor: palette.surfaceMuted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: item,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final value = (percent * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 8,
                color: palette.cardBorder.withOpacity(0.46),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent.clamp(0, 1),
                  child: Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniClockPainter extends CustomPainter {
  _MiniClockPainter({
    required this.time,
    required this.accent,
    required this.track,
  });

  final DateTime time;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final seconds = time.second / 60;
    final minutes = (time.minute + seconds) / 60;
    final hours = ((time.hour % 12) + minutes) / 12;

    final facePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, facePaint);

    final borderPaint = Paint()
      ..color = track.withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius - 5, borderPaint);

    final secondRing = Paint()
      ..color = accent.withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -pi / 2,
      2 * pi * seconds,
      false,
      secondRing,
    );

    Offset hand(double turn, double length) {
      final angle = 2 * pi * turn - pi / 2;
      return center + Offset(cos(angle), sin(angle)) * length;
    }

    final hourPaint = Paint()
      ..color = const Color(0xFF2E3438)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final minutePaint = Paint()
      ..color = const Color(0xFF2E3438)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final secondPaint = Paint()
      ..color = accent
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, hand(hours, radius * 0.36), hourPaint);
    canvas.drawLine(center, hand(minutes, radius * 0.56), minutePaint);
    canvas.drawLine(center, hand(seconds, radius * 0.62), secondPaint);
    canvas.drawCircle(center, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _MiniClockPainter old) {
    return old.time.second != time.second ||
        old.accent != accent ||
        old.track != track;
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
