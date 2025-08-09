/// 极简首页：日期 + 等宽数字时刻 + 模拟时钟 + 极简时间线
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // TextDirection / FontFeature
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _now = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
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

    final dateStr = DateFormat('yyyy年MM月dd日', 'zh_CN').format(_now);
    final weekStr = DateFormat('EEEE', 'zh_CN').format(_now);
    final timeStr = DateFormat('HH:mm:ss').format(_now);

    return ScaffoldPage(
      // header: const PageHeader(title: Text('首页')),
      content: LayoutBuilder(
        builder: (ctx, cons) {
          final twoCols = cons.maxWidth > 980;
          final clockCardWidth = twoCols ? 380.0 : 320.0;
          final progress = _computeProgress(_now);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cons.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部两列
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左：日期 + 时间
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _sectionTitle(''),
                            _Card(
                              padding:
                              const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .5,
                                          fontFeatures: const [
                                            ui.FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: accent.lighter,
                                          borderRadius:
                                          BorderRadius.circular(10),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 右：模拟时钟
                      SizedBox(
                        width: clockCardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _sectionTitle(''),
                            _Card(
                              padding: const EdgeInsets.all(18),
                              child: Center(
                                child: _AnalogClock(
                                  time: _now,
                                  size: twoCols ? 320 : 280,
                                  accent: accent.normal,
                                  faceBase: t.resources
                                      .cardBackgroundFillColorDefault,
                                  faceHalo: const Color(0xFFE6E9EF),
                                  tickColor: const Color(0xFFB5BCC6),
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

                  // 极简时间线
                  // _sectionTitle('时间线'),
                  _Card(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      children: [
                        _MiniTimeline(
                          items: [
                            MiniPoint(label: '日', percent: progress.day),
                            MiniPoint(label: '周', percent: progress.week),
                            MiniPoint(label: '月', percent: progress.month),
                            MiniPoint(label: '年', percent: progress.year),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: .7,
                          child: Text(
                            '日 ${(progress.day * 100).toStringAsFixed(0)}% · '
                                '周 ${(progress.week * 100).toStringAsFixed(0)}% · '
                                '月 ${(progress.month * 100).toStringAsFixed(0)}% · '
                                '年 ${(progress.year * 100).toStringAsFixed(0)}%',
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
    final nextMonth =
    now.month == 12 ? DateTime(now.year + 1, 1) : DateTime(now.year, now.month + 1);
    final month = ratio(now, startMonth, nextMonth);

    final startYear = DateTime(now.year);
    final nextYear = DateTime(now.year + 1);
    final year = ratio(now, startYear, nextYear);

    return _Progress(day: day, week: week, month: month, year: year);
  }
}

// ———————————————————— 小部件 ————————————————————

Widget _sectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8, left: 2),
  child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
);

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 22, offset: Offset(0, 10), color: Color(0x14000000)),
        ],
      ),
      child: child,
    );
  }
}

/// 极简时间线：一条细线 + 四个小点（0~1 百分比）
class MiniPoint {
  const MiniPoint({required this.label, required this.percent});
  final String label;
  final double percent;
}

class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline({required this.items});
  final List<MiniPoint> items;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final accent = t.accentColor;

    return SizedBox(
      height: 72,
      width: double.infinity, // ← 铺满可用宽度
      child: CustomPaint(
        painter: _MiniTimelinePainter(
          items: items
              .map((e) => MiniPoint(label: e.label, percent: e.percent.clamp(0, 1)))
              .toList(),
          baseColor: t.resources.cardBackgroundFillColorSecondary,
          dotColor: accent.normal,
          dotColorDim: accent.normal.withOpacity(.45),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF35363A),
          ),
        ),
      ),
    );
  }
}


class _MiniTimelinePainter extends CustomPainter {
  _MiniTimelinePainter({
    required this.items,
    required this.baseColor,
    required this.dotColor,
    required this.dotColorDim,
    required this.labelStyle,
  });

  final List<MiniPoint> items;
  final Color baseColor;
  final Color dotColor;
  final Color dotColorDim;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final left = 8.0, right = size.width - 8.0;
    final y = size.height / 2;

    final base = Paint()
      ..color = baseColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), base);

    for (int i = 0; i < items.length; i++) {
      final p = items[i];
      final x = left + (right - left) * p.percent;
      final r = 6.0;
      final color = (i == 0) ? dotColor : dotColorDim;

      final shadow = Paint()
        ..color = color.withOpacity(.25)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), r + 1.2, shadow);

      final dot = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), r, dot);

      final tp = TextPainter(
        text: TextSpan(text: p.label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTimelinePainter old) =>
      old.items != items || old.baseColor != baseColor || old.dotColor != dotColor;
}

// ———————————————— 模拟时钟 ————————————————

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
    canvas.drawCircle(c, r - 12, face);

    final tick = Paint()
      ..color = tickColor
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * (i / 60);
      final isHour = i % 5 == 0;
      final len = isHour ? r * .12 : r * .035;
      tick.strokeWidth = isHour ? 2.6 : 1.4;
      final p1 = c + Offset(cos(angle), sin(angle)) * (r - 26 - len);
      final p2 = c + Offset(cos(angle), sin(angle)) * (r - 26);
      canvas.drawLine(p1, p2, tick);
    }

    void drawNum(String s, double deg) {
      final rad = (deg - 90) * pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: 13.5,
            color: numberColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        c + Offset(cos(rad), sin(rad)) * (r - 52) - Offset(tp.width / 2, tp.height / 2),
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

    Offset hand(double a, double len) =>
        c + Offset(cos(a - pi / 2), sin(a - pi / 2)) * len;

    canvas.drawLine(c, hand(hourAngle, r * .46), hourPaint);
    canvas.drawLine(c, hand(minuteAngle, r * .68), minutePaint);
    canvas.drawLine(c, hand(secondAngle, r * .76), secondPaint);
    canvas.drawLine(c, hand(secondAngle + pi, r * .16), secondPaint);

    final hub = Paint()..color = accent;
    canvas.drawCircle(c, 4.2, hub);
    canvas.drawCircle(hand(secondAngle + pi, r * .16), 3.2, hub);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.time.second != time.second ||
          old.accent != accent ||
          old.faceBase != faceBase;
}

// 进度结构
class _Progress {
  const _Progress({
    required this.day,
    required this.week,
    required this.month,
    required this.year,
  });
  final double day, week, month, year;
}
