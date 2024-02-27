import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/loginButtons .dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _userName = "";
  String _passWord = "";

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: Colors.white,
          title: WindowTitleBarBox(child: MoveWindow()),
          actions: [
            Platform.isWindows
                ? Container(
                    alignment: Alignment.centerRight,
                    width: 94,
                    child: const LoginButtons(),
                  )
                : const Text("")
          ],
        ),
        body: Center(
          child: Container(
            alignment: Alignment.center,
            width: 400,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 0), // 调整此值以改变左边距
                        child: Icon(
                          Icons.cloud,
                          size: 40,
                          color: Color.fromRGBO(126, 145, 250, 1),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: 0, top: 5),
                          // 调整此值以改变左边距
                          child: Text(
                            " CLOUD DISK",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              fontFamily: "微软雅黑",
                            ),
                          ))
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  width: 360,
                  height: 68,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _userName = value;
                      });
                    },
                    decoration: const InputDecoration(
                        hintText: "账号", border: OutlineInputBorder()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  width: 360,
                  height: 68,
                  child: Stack(
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _passWord = value;
                          });
                        },
                        decoration: const InputDecoration(
                            hintText: "密码", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 320,
                  height: 42,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromRGBO(126, 145, 250, 1)),
                        shape: MaterialStateProperty.all(//圆角
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)))),
                    child: const Text('登录'),
                    onPressed: () {
                      //请求接口验证数据

                      print(_userName);
                      print(_passWord);

                      context.go("/file");

                      // appWindow.hide(); //macos需要去掉这句话
                      //
                      // sleep(const Duration(milliseconds: 50));
                      // appWindow.minSize = const Size(1000, 600);
                      // appWindow.size = const Size(1000, 600);
                      // appWindow.alignment = Alignment.center;
                      // appWindow.show();
                    },
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
