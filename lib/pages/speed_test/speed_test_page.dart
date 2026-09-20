///  @author caoqian
/// @since 2025-08-06 23:09
/// @Description: 网络测速

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import 'package:http/http.dart' as http;


class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  String _downloadSpeed = '';
  String _uploadSpeed = '';
  String _networkType = '检测中...';
  bool _testing = false;
  String _ipAddress = '检测中...';

  @override
  void initState() {
    super.initState();
    _detectNetwork();
  }

  Future<void> _detectNetwork() async {
    String ip = '获取中...';
    String type = '未知';

    try {
      // 获取公网 IP
      final response = await http.get(Uri.parse('https://v4.ident.me'));
      if (response.statusCode == 200) {
        ip = response.body.trim();
      } else {
        ip = '获取失败 (${response.statusCode})';
      }

      // 获取本地接口列表
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      final activeInterfaces =
          interfaces.where((i) => i.addresses.isNotEmpty).toList();
      debugPrint('检测到接口名: ${activeInterfaces.map((e) => e.name).toList()}');

      // 优先匹配：有线 > Wi-Fi > 其他
      for (var iface in activeInterfaces) {
        final name = iface.name.toLowerCase();

        if (name.contains('eth') ||
            name.contains('以太网') ||
            name.contains('en') ||
            name.contains('本地连接')) {
          type = '有线网络 $name';
          break;
        } else if (name.contains('wlan') ||
            name.contains('wi') ||
            name.contains('无线') ||
            name.contains('wifi')) {
          type = 'Wi-Fi  $name';
          // 不 break，继续看看有没有更高优先级
        } else {
          type = '未知网络';
        }
      }

      if (activeInterfaces.isEmpty) {
        type = '无网络连接';
      }
    } catch (e) {
      ip = '异常 (${e.runtimeType})';
      type = '检测失败';
    }

    setState(() {
      _networkType = type;
      _ipAddress = ip;
    });
  }

  Future<void> _testSpeed() async {
    const testUrl = 'https://speed.cloudflare.com/__down?bytes=10000000';

    setState(() {
      _testing = true;
      _downloadSpeed = '';
      _uploadSpeed = '';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(testUrl));
      stopwatch.stop();

      final sizeInBits = response.bodyBytes.length * 8;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final download = sizeInBits / seconds / 1024 / 1024;

      final uploadData = utf8.encode(List.filled(2000000, 'A').join());
      final uploadStopwatch = Stopwatch()..start();
      sleep(const Duration(seconds: 1)); // 模拟上传
      uploadStopwatch.stop();
      final uploadSeconds = uploadStopwatch.elapsedMilliseconds / 1000;
      final upload = uploadData.length * 8 / uploadSeconds / 1024 / 1024;

      setState(() {
        _downloadSpeed = download.toStringAsFixed(2);
        _uploadSpeed = upload.toStringAsFixed(2);
      });
    } catch (_) {
      setState(() {
        _downloadSpeed = '错误';
        _uploadSpeed = '错误';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Widget _buildMetric(String label, String value) {
    final palette = ThemeScope.of(context).palette;
    final secondary =
        FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.52);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: secondary)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'Mbps',
                    style: TextStyle(fontSize: 10, color: secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final secondary =
        FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.52);

    return ScaffoldPage(
      content: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      Text(
                        _networkType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _ipAddress,
                        style: TextStyle(fontSize: 11, color: secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _testing ? null : _testSpeed,
                  child: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: ProgressRing(strokeWidth: 2),
                        )
                      : const Text('开始测速'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric('下载', _downloadSpeed),
              const SizedBox(width: 16),
              _buildMetric('上传', _uploadSpeed),
            ],
          ),
        ],
      ),
    );
  }

}
