/// @author caoqian
/// @since 2024-04-25 11:47
/// @Description: 首页

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dto/home/weather.dart';
import '../utils/DBHelper.dart';
import '../utils/HttpUtils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final Logger logger = Logger('HomePage'); // 创建一个日志记录器对象

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
    '吃屎者事竟成',
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

  bool isLoading = true;

  getWeatherInfo() async {
    //location=101200304 代表鄂州市
    //先去DB中查询是否存在当日的数据，如果不存在则进行接口调用获取，如果返回成功则进行数据库记录，并且展示

    // 先查询数据库中是否存在当日数据
    List<Weather> weatherList = await checkWeatherDataExist();
    if (weatherList.isEmpty) {
      var baseUrl =
          'https://devapi.qweather.com/v7/weather/now?location=101200304&key=136d3994198746db8449ca7cf791b9e2';
      var path = '';
      var response = await HttpUtils.getRequest(baseUrl, path);
      if (response.statusCode == 200) {
        var weatherData = jsonDecode(response.body);
        setState(() {
          var temp = weatherData['now']['temp'];
          var weatherText = weatherData['now']['text'];
          var humidityText = weatherData['now']['humidity'];
          temperature = '$temp ℃';
          weatherCondition = weatherText;
          humidity = humidityText;
        });
        //将数据存入数据库
        insertweatherdata(weatherData);
      } else {
        logger.severe('Failed to load weather data: ${response.statusCode}');
      }
    } else {
      //如果不是空的 那就直接用DB中查询的数据
      Weather firstWeather = weatherList[0];
      setState(() {
        temperature = '${firstWeather.temp} ℃';
        weatherCondition = firstWeather.text!;
        humidity = firstWeather.humidity!;
      });
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
              // child: FutureBuilder<void>(
              //   future: getWeatherInfo(),
              //   builder: (context, snapshot) {
              //     if (isLoading = true) {
              //       if (temperature.isNotEmpty && weatherCondition.isNotEmpty) {
              //         return Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             const Text(
              //               '今日鄂州市天气信息',
              //               style: TextStyle(
              //                   fontSize: 16, fontWeight: FontWeight.bold),
              //             ),
              //             const SizedBox(height: 8),
              //             Text('温度：$temperature'),
              //             Text('天气状况：$weatherCondition'),
              //             Text('相对湿度：$humidity'),
              //           ],
              //         );
              //       } else {
              //         return Container(); // 返回一个空容器
              //       }
              //     } else {
              //       return const CircularProgressIndicator();
              //     }
              //   },
              // ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日鄂州市天气信息',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('温度：$temperature'),
                  Text('天气状况：$weatherCondition'),
                  if (humidity != null) Text('相对湿度：$humidity'),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 150,
            child: Container(
              padding: EdgeInsets.all(8),
              width: 350,
              // 设置固定宽度
              height: 300,
              // 设置固定高度
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

  checkWeatherDataExist() async {
    // 初始化 sqflite_common_ffi
    sqfliteFfiInit();
    // 设置 databaseFactoryFfi 作为默认的 databaseFactory
    databaseFactory = databaseFactoryFfi;

    // 数据库配置
    const tableName = 'weather';
    const columns = ['location', 'temp', 'text', 'humidity', 'date'];
    const columnProperties = ['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'];

    // 创建 DBHelper 实例
    final dbHelper = DBHelper();

    // 初始化数据库和表
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    // 获取当前日期和时间
    DateTime now = DateTime.now();

    // 创建一个 DateFormat 对象来指定日期格式
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');

    // 使用 DateFormat 对象来格式化日期
    String desiredDateValue = dateFormat.format(now);

    Map<String, dynamic> conditions = {
      'location': '101200304',
      'date': desiredDateValue,
    };

    List<Map<String, dynamic>> allRows =
        await dbHelper.getByMultipleFields(tableName, conditions);

    List<Weather> weatherList = [];
    for (var map in allRows) {
      Weather weather = Weather.fromJson(map);
      weatherList.add(weather);
    }

    await db.close();

    return weatherList;
  }

  void insertweatherdata(weatherData) async {
    // 初始化 sqflite_common_ffi
    sqfliteFfiInit();
    // 设置 databaseFactoryFfi 作为默认的 databaseFactory
    databaseFactory = databaseFactoryFfi;

    // 数据库配置
    const tableName = 'weather';
    const columns = ['location', 'temp', 'text', 'humidity', 'date'];
    const columnProperties = ['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'];

    // 创建 DBHelper 实例
    final dbHelper = DBHelper();

    // 初始化数据库和表
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    // 获取当前日期和时间
    DateTime now = DateTime.now();

    // 创建一个 DateFormat 对象来指定日期格式
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');

    // 使用 DateFormat 对象来格式化日期
    String desiredDateValue = dateFormat.format(now);

    var temp = weatherData['now']['temp'];
    var weatherText = weatherData['now']['text'];
    var humidityText = weatherData['now']['humidity'];

    await dbHelper.insert(tableName, {
      'location': '101200304',
      'temp': temp,
      'text': weatherText,
      'humidity': humidityText,
      'date': desiredDateValue
    });

    await db.close();
  }
}
