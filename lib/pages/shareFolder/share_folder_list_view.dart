import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show AlertDialog, TextButton, TextField;

Widget listViewWidget(
  List<Map<String, String>> filesList,
  Function(String) onFolderDoubleTap,
  String currentFolderPath,
  VoidCallback updateFilesList, // 新增参数用于更新文件列表
) {
  return ListView.builder(
    padding: const EdgeInsets.only(top: 20),
    itemCount: filesList.length,
    itemBuilder: (context, index) {
      bool isFolder = filesList[index]["size"] == "Directory"; // 判断是否是文件夹
      return HoverButton(
        onPressed: () {}, // 必须配置，配置后才能监听到 state 状态
        builder: (context, state) {
          return GestureDetector(
            // 使用 GestureDetector 监听双击事件
            onDoubleTap: () {
              String filePath = filesList[index]["path"]!;
              String fileExtension = filePath.split('.').last.toLowerCase();
              if (isFolder && filesList[index]["path"] != null) {
                print("Folder path: ${filesList[index]["path"]}");
                onFolderDoubleTap(
                    filesList[index]["path"]!); // 处理双击文件夹的事件，并传递文件夹路径
                updateFilesList(); // 调用更新文件列表的逻辑
              } else if (fileExtension == 'txt') {
                // 双击文件时打开并编辑文件
                openAndEditTxtFile(
                    context, filesList[index]["path"]!); // 传递 BuildContext 参数
              } else if (fileExtension == 'png' ||
                  fileExtension == 'jpg' ||
                  fileExtension == 'jpeg') {
                showImagePreview(context, filePath);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: state.isHovering
                    ? const Color.fromRGBO(245, 245, 246, 1)
                    : Colors.white,
              ),
              padding: const EdgeInsets.all(6.0),
              child: ListTile(
                leading: Icon(
                  isFolder
                      ? FluentIcons.fabric_folder_fill
                      : FluentIcons.document,
                  color: isFolder
                      ? const Color.fromRGBO(126, 145, 250, 1)
                      : const Color.fromRGBO(31, 41, 55, 1),
                  size: 28,
                ),
                title: Text("${filesList[index]["title"]}"),
              ),
            ),
          );
        },
      );
    },
  );
}

//打开TXT文件并且进行内容编辑以及保存
Future<void> openAndEditTxtFile(BuildContext context, String filePath) async {
  try {
    String fileContent = await File(filePath).readAsString();
    String? editedContent = await showDialog<String?>(
      context: context, // 使用传递进来的 BuildContext
      builder: (BuildContext context) {
        TextEditingController controller =
            TextEditingController(text: fileContent);
        return AlertDialog(
          title: Text('Edit File'),
          content: TextField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
          actions: [
            TextButton(
              // 修改这里的 FlatButton 为 TextButton
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
              },
              child: Text('Cancel'),
            ),
            TextButton(
              // 修改这里的 FlatButton 为 TextButton
              onPressed: () async {
                String content = controller.text;
                await File(filePath).writeAsString(content);
                Navigator.pop(context, content); // 关闭对话框并返回修改后的内容
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
    if (editedContent != null) {
      // 处理修改后的内容
      print('Edited Content: $editedContent');
    }
  } catch (e) {
    print('Error opening/editing file: $e');
  }
}

void showImagePreview(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Container(
          width: 300,
          height: 300,
          child: Image.file(File(imagePath)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}
