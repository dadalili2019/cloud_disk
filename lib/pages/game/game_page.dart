import 'dart:async';
import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart'; // SFX: 音效/背景音乐

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // 棋盘
  static const int rows = 20;
  static const int columns = 20;
  static const int cellSize = 18;

  // 状态
  late List<Point<int>> snake;
  late Point<int> food;
  String direction = 'right';
  int score = 0;

  // 计时
  static const Duration step = Duration(milliseconds: 140);
  Timer? _timer;
  bool _ticking = false;

  final FocusNode _focusNode = FocusNode();

  // ===== 音频相关 =====
  bool isPlaying = true;         // 是否在跑
  bool musicOn = true;           // 音频开关（含BGM和音效；如需分开，可再加 sfxOn）
  final AudioPlayer _bgm = AudioPlayer();      // 背景音乐（循环）
  final AudioPlayer _sfxEat = AudioPlayer();   // SFX: 吃到
  final AudioPlayer _sfxFail = AudioPlayer();  // SFX: 撞墙/自撞

  // 路径（按你的目录）
  static const String _pathEat  = 'mp3/eat.mp3';
  static const String _pathFail = 'mp3/fail.wav';
  static const String _pathBgm  = 'mp3/bgm_small.wav';

  @override
  void initState() {
    super.initState();
    _reset();
    _arm();
    _initAudio(); // SFX: 初始化音频
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgm.dispose();
    _sfxEat.dispose();
    _sfxFail.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(0.5);

    await _sfxEat.setReleaseMode(ReleaseMode.stop);
    await _sfxEat.setVolume(0.9);
    await _sfxFail.setReleaseMode(ReleaseMode.stop);
    await _sfxFail.setVolume(0.9);

    // NEW: 仅预载，不自动播放；根据状态同步一次
    try { await _bgm.setSourceAsset(_pathBgm); } catch (_) {}
    await _syncBgm();
  }

  // NEW: 统一同步 BGM 状态：只有在 musicOn && isPlaying 才播放
  Future<void> _syncBgm() async {
    if (!musicOn || !isPlaying) {
      try { await _bgm.pause(); } catch (_) {}
    } else {
      try {
        await _bgm.resume();
      } catch (_) {
        // 某些平台 resume 前需要先 play 一次
        try { await _bgm.play(AssetSource(_pathBgm)); } catch (_) {}
      }
    }
  }

  // 背景音乐开/关（顺带影响音效；想让音效独立就再加 sfxOn）
  Future<void> _toggleMusic() async {
    setState(() => musicOn = !musicOn);
    await _syncBgm(); // NEW
  }

  // SFX: 播放吃到音效
  Future<void> _playEatSfx() async {
    if (!musicOn) return;
    try {
      await _sfxEat.stop(); // 迅速重触发
      await _sfxEat.play(AssetSource(_pathEat));
    } catch (_) {}
  }

  // SFX: 撞墙/自撞
  Future<void> _playFailSfx() async {
    if (!musicOn) return;
    try {
      await _sfxFail.stop();
      await _sfxFail.play(AssetSource(_pathFail));
    } catch (_) {}
  }

  // ===================

  void _reset() {
    const start = Point<int>(columns ~/ 2, rows ~/ 2);
    setState(() {
      snake = [start];
      direction = 'right';
      food = _randFood();
      score = 0;
    });
  }

  Point<int> _randFood() {
    final r = Random();
    Point<int> p;
    do {
      p = Point(r.nextInt(columns), r.nextInt(rows));
    } while (snake.contains(p));
    return p;
  }

  void _arm() {
    if (!isPlaying) return;
    if (_timer != null) return;
    _timer = Timer(step, () async {
      _timer = null;
      await _tick();
      _arm();
    });
  }

  Future<void> _tick() async {
    if (!mounted || _ticking || !isPlaying) return;
    _ticking = true;
    try {
      final head = snake.last;
      late Point<int> next;
      switch (direction) {
        case 'up':    next = Point(head.x, head.y - 1); break;
        case 'down':  next = Point(head.x, head.y + 1); break;
        case 'left':  next = Point(head.x - 1, head.y); break;
        case 'right':
        default:      next = Point(head.x + 1, head.y);
      }

      final body = snake.length > 1 ? snake.sublist(0, snake.length - 1) : const <Point<int>>[];
      final hitWall = next.x < 0 || next.y < 0 || next.x >= columns || next.y >= rows;
      final hitSelf = body.contains(next);

      if (hitWall || hitSelf) {
        await _playFailSfx();
        _timer?.cancel();

        // NEW: 失败时先标记不在玩 & 同步让 BGM 停止
        setState(() => isPlaying = false);
        await _syncBgm();
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => ContentDialog(
            title: const Text('游戏结束'),
            content: Text('得分：$score'),
            actions: [
              Button(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('重来'),
              )
            ],
          ),
        );
        if (!mounted) return;

        // 重置并自动继续玩（如果你想失败后不自动继续，把下面三行移到“开始”按钮里）
        setState(() => isPlaying = true);
        _reset();
        _arm();
        await _syncBgm(); // NEW: 继续玩 => 开 BGM
        return;
      }

      setState(() {
        if (next == food) {
          snake.add(next);
          score++;
          food = _randFood();
          _playEatSfx();
        } else {
          snake
            ..add(next)
            ..removeAt(0);
        }
      });
    } finally {
      _ticking = false;
    }
  }

  void _turn(String d) {
    final invalid = (direction == 'up' && d == 'down') ||
        (direction == 'down' && d == 'up') ||
        (direction == 'left' && d == 'right') ||
        (direction == 'right' && d == 'left');
    if (invalid) return;
    direction = d;
    if (isPlaying) _arm();
  }

  // 控制：空格开始/暂停，M 开关音频
  void _start() {
    if (!isPlaying) {
      setState(() => isPlaying = true);
      _arm();
      _syncBgm(); // NEW
    }
  }

  void _pause() {
    if (isPlaying)  {
      setState(() => isPlaying = false);
      _timer?.cancel();
      _timer = null;
      _syncBgm(); // NEW
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyDownEvent) {
      final k = e.logicalKey;
      if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) { _turn('up');    return KeyEventResult.handled; }
      if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS){ _turn('down');  return KeyEventResult.handled; }
      if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA){ _turn('left');  return KeyEventResult.handled; }
      if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD){_turn('right'); return KeyEventResult.handled; }
      if (k == LogicalKeyboardKey.space) { isPlaying ? _pause() : _start(); return KeyEventResult.handled; }
      if (k == LogicalKeyboardKey.keyM) { _toggleMusic(); return KeyEventResult.handled; }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp):    const DoNothingAndStopPropagationIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):  const DoNothingAndStopPropagationIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):  const DoNothingAndStopPropagationIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationIntent(),
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ScaffoldPage(
          content: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '得分 $score',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Button(
                      onPressed: isPlaying ? _pause : _start,
                      child: Text(isPlaying ? '暂停' : '开始'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _toggleMusic,
                      child: Text(musicOn ? '音乐开' : '音乐关'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: () {
                        final wasPlaying = isPlaying;
                        _pause();
                        _reset();
                        if (wasPlaying) _start();
                        _focusNode.requestFocus();
                      },
                      child: const Text('重置'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF303133),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3D4042)),
                      ),
                      child: GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: SizedBox(
                          width: columns * cellSize.toDouble(),
                          height: rows * cellSize.toDouble(),
                          child: CustomPaint(
                            painter: _Painter(
                              snake: snake,
                              food: food,
                              cell: cellSize.toDouble(),
                              rows: rows,
                              columns: columns,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final double cell;
  final int rows;
  final int columns;

  _Painter({
    required this.snake,
    required this.food,
    required this.cell,
    required this.rows,
    required this.columns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF3D4042)..strokeWidth = 1;
    for (int i = 1; i < columns; i++) {
      final x = i * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int j = 1; j < rows; j++) {
      final y = j * cell;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // 食物
    final foodRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(food.x * cell, food.y * cell, cell, cell),
      Radius.circular(cell * .3),
    );
    final foodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(foodRect.outerRect);
    canvas.drawRRect(foodRect, foodPaint);

    // 蛇
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2),
        Radius.circular(cell * .35),
      );
      final t = i / max(1, snake.length - 1);
      final c1 = Color.lerp(const Color(0xFF2EC7A6), const Color(0xFF1AA6F6), t)!;
      final c2 = Color.lerp(const Color(0xFF25B08F), const Color(0xFF1588D8), t)!;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      if (i == snake.length - 1) {
        final eye = Paint()..color = Colors.white;
        final pupil = Paint()..color = Colors.black;
        final cx = p.x * cell + cell * .65;
        final cy = p.y * cell + cell * .35;
        canvas.drawCircle(Offset(cx, cy), cell * .09, eye);
        canvas.drawCircle(Offset(cx, cy), cell * .05, pupil);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
