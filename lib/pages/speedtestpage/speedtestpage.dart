///  @author caoqian
/// @since 2025-08-06 23:09
/// @Description: 网络测速

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: SpeedTestPage()));

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

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

  Widget _buildSpeedCircle(String label, String value, Color color) {
    return Column(
      children: [
        Text('$label Mbps',
            style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('网络测速',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('当前网络类型：$_networkType',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('当前IP地址：$_ipAddress',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _testing ? null : _testSpeed,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.blueAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blue.withOpacity(0.3), blurRadius: 10)
                      ]),
                  alignment: Alignment.center,
                  child: _testing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('测试',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSpeedCircle('下载', _downloadSpeed, Colors.cyan),
                  const SizedBox(width: 40),
                  _buildSpeedCircle('上传', _uploadSpeed, Colors.pink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
