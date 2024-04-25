/// @author caoqian
/// @since 2024-04-25 11:47
/// @Description: 首页

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 定义 GIF 图片的本地路径
  // String gifPath = 'assets/images/vibing.gif';
  // 定义不同时间段对应的 GIF 图片路径
  String morningGifPath = 'assets/images/work.gif'; // 早上
  String afternoonGifPath = 'assets/images/cat.gif'; // 下午
  String eveningGifPath = 'assets/images/rest.gif'; // 晚上
  String noonGifPath = 'assets/images/corgi.gif'; // 中午
  String lateNightGifPath = 'assets/images/vibing.gif'; // 深夜

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    getWeatherInfo(); // 页面加载时获取天气信息
  }

  // 根据时间段获取对应的 GIF 路径
  String getGifPath(DateTime date) {
    int hour = date.hour;
    if (hour >= 6 && hour < 12) {
      return morningGifPath; // 早上
    } else if (hour >= 12 && hour < 15) {
      return noonGifPath;
    } else if (hour >= 15 && hour < 18) {
      return afternoonGifPath;
    } else if (hour >= 18 && hour < 24) {
      return eveningGifPath;
    } else {
      return lateNightGifPath; // 深夜
    }
  }

  // 定义标题集合
  final List<String> appBarTitles = [
    '落叶与灰尘，都值得你献出思想；誓言与回忆，都值得你献出感伤。',
    '人生无需后悔，逝去的事就像一阵风；人生不需要遗憾，该来的终究还是要来',
    '一般的人，路只在脚下；聪明的人，路就在嘴边。',
    '治军总须脚踏实地，克勤小物，乃可日起而有功',
    '单丝不成线，独木不成林',
    '辉煌时刻人人有，别拿一刻当永久。',
    '不要等到人生垂暮，才想起俯拾朝花，且行且珍惜。',
    '以爱之心做事，感恩之心做人。',
    '恨别人，痛苦的却是自我。',
    '火车跑得快，全靠车头带。',
    '经一番挫折，长一番见识。',
    '事事如意料之外，年年有余额不足',
    '比你优秀的人还在努力你努力还有什么用',
    '“有志者事竟成。”',
    '一切随心，有心去感悟空间。',
    '耐得住寂寞，才能拥得了繁华。',
    '人可以没有骨气，但不可以做懦夫。',
  ];

  // 生成随机数
  final Random random = Random();

  // 获取随机标题
  String getRandomTitle() {
    return appBarTitles[random.nextInt(appBarTitles.length)];
  }

  String temperature = ''; // 温度
  String weatherCondition = ''; // 天气状况
  String humidity = ''; // 相对湿度

  Future<void> getWeatherInfo() async {
    //location=101200304 代表鄂州市
    var apiUrl =
        'https://devapi.qweather.com/v7/weather/now?location=101200304&key=136d3994198746db8449ca7cf791b9e2';
    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var weatherData = jsonDecode(response.body);
      // 解析天气数据并更新UI
      setState(() {
        // 更新天气信息的状态变量
        // 示例：更新温度和天气状况
        var temp = weatherData['now']['temp'];
        var weatherText = weatherData['now']['text'];
        var humidityText = weatherData['now']['humidity'];
        temperature = '$temp ℃';
        weatherCondition = weatherText;
        humidity = humidityText;
      });
    } else {
      // 处理请求失败的情况
      print('Failed to load weather data: ${response.statusCode}');
    }
  }

  List<String> todoList = [
    '完成任务1',
    '完成任务2',
    '取消任务3',
    '完成任务4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getRandomTitle()),
      ),
      body: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // Text("HomePage"),
              ],
            ),
          ),
          Positioned(
            top: 0, // 将日历网上移动一点
            right: 20, //与右边的间距
            child: Container(
              width: 300,
              height: 340,
              decoration: BoxDecoration(
                color: Colors.white, // 将背景颜色更改为白色
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Card(
                elevation: 0, // 移除 Card 的阴影
                child: CalendarCarousel<Event>(
                  onDayPressed: (DateTime date, List<Event> events) {
                    setState(() {
                      _selectedDate = date;
                    });
                    print('Selected date: $date');
                  },
                  weekendTextStyle: TextStyle(color: Colors.red),
                  thisMonthDayBorderColor: Colors.grey,
                  daysTextStyle: TextStyle(color: Colors.black),
                  weekFormat: false,
                  height: 420.0,
                  selectedDateTime: _selectedDate,
                  daysHaveCircularBorder: false,
                  customGridViewPhysics: NeverScrollableScrollPhysics(),
                  markedDateShowIcon: true,
                  markedDateIconMaxShown: 2,
                  markedDateIconBuilder: (event) {
                    return event.icon;
                  },
                  todayTextStyle: TextStyle(color: Colors.blue),
                  markedDateIconOffset: 10.0,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 20,
            child: Image.asset(
              getGifPath(_selectedDate),
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FutureBuilder<void>(
                future: getWeatherInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (temperature.isNotEmpty && weatherCondition.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日鄂州市天气信息',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('温度：$temperature'),
                          Text('天气状况：$weatherCondition'),
                          Text('相对湿度：$humidity'),
                        ],
                      );
                    } else {
                      return Container(); // 返回一个空容器
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 80,
            child: Container(
              padding: EdgeInsets.all(8),
              width: 400, // 设置固定宽度
              height: 400, // 设置固定高度
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '待办事项',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: todoList.length,
                      itemBuilder: (context, index) {
                        String todo = todoList[index];
                        bool isCompleted = todo.startsWith('完成');
                        return ListTile(
                          title: Text(todo),
                          trailing: isCompleted
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.cancel, color: Colors.red),
                          onTap: () {
                            setState(() {
                              if (isCompleted) {
                                todoList[index] = '取消' + todo.substring(2);
                              } else {
                                todoList[index] = '完成' + todo.substring(2);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
