// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_disk/main.dart';

import 'dart:io';

void main() {
  // 共享目录的路径
  var sharedFolderPath = r'\\ALPHA\shareFolder';

  // 创建目录对象
  var sharedDirectory = Directory(sharedFolderPath);

  // 判断目录是否存在
  if (sharedDirectory.existsSync()) {
    // 获取目录下的文件和子目录列表
    var files = sharedDirectory.listSync(recursive: true);

    // 遍历文件和子目录列表
    for (var entity in files) {
      if (entity is File) {
        print('File: ${entity.path}');
      } else if (entity is Directory) {
        print('Directory: ${entity.path}');
      }
    }
  } else {
    print('Shared directory not found.');
  }
}
