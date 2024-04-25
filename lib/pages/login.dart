import 'dart:math';
import 'dart:io'; // 导入 dart:io 包

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<String> iconPaths = [
    'assets/login/兔子.svg',
    'assets/login/小狗.svg',
    'assets/login/小猪.svg',
    'assets/login/小猫.svg',
    'assets/login/小鸡.svg',
    'assets/login/小鸭.svg',
    'assets/login/棕熊.svg',
    'assets/login/猴子.svg',
    'assets/login/白熊.svg',
    'assets/login/老虎.svg',
    'assets/login/青蛙.svg',
    'assets/login/鸽子.svg',
  ];

  late String selectedIconPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Randomly select an icon path
    selectedIconPath = iconPaths[Random().nextInt(iconPaths.length)];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeApp() async {
    await Future.delayed(Duration.zero);
    if (Platform.isWindows) {
      // 关闭 Windows 应用程序
      exit(0);
    } else {
      // 其他平台的处理逻辑
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _closeApp(); // 调用关闭应用程序的方法
            },
          ),
          // title: const Text("CLOUD DISK"),
        ),
        body: Center(
          child: Container(
            alignment: Alignment.center,
            width: 400,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  selectedIconPath,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(126, 145, 250, 1),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onPressed: () {
                    _animationController.forward().then((_) {
                      context.go("/home");
                    });
                  },
                  onLongPress: () {
                    _animationController.reverse();
                  },
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                      child: Text(
                        '进入',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
