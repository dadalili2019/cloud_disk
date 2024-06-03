///  @author caoqian
/// @since 2024-04-30 12:13
/// @Description: 日志记录配置文件

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class LoggingConfig {
  static String logDirectory = 'log'; // 设置日志输出目录为当前项目下的log目录
  static late File logFile;

  static void setupLogging() {
    Directory logFolder = Directory(logDirectory);
    if (!logFolder.existsSync()) {
      logFolder.createSync(recursive: true);
    }

    // 根据当前日期创建日志文件
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String logFilePath = '$logDirectory/app_$today.log';
    logFile = File(logFilePath);

    // 将日志消息追加到文件中
    Logger.root.onRecord.listen((record) {
      String logMessage =
          '${record.level.name}: ${record.time}: ${record.message}\n';
      logFile.writeAsStringSync(logMessage, mode: FileMode.append);
    });
  }
}
