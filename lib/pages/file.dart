import 'package:fluent_ui/fluent_ui.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  bool _isGridView = false;

  //TODO 未来替换为共享磁盘的 文件内容列表
  final List _filesList = [
    {
      "id": "1",
      "title": "Nestjs仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "2",
      "title": "Flutter仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "3",
      "title": "Linux+Docker运维系列教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "4",
      "title": "Golang Beego仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "5",
      "title": "Serverless Egg.js Mysql Vue3.x打造全栈无人点餐 无人收银系统",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "6",
      "title": "Vue3教程_Vue3.x+Ts+Antd打造舆情监控系统",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      padding: const EdgeInsets.only(left: 3), // 调整此值以改变左边距
      header: _headerWidget(),
      content: _isGridView ? _gridViewWidget() : _listViewWidget(),
    );
  }

  Widget _headerWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "文件",
                style: TextStyle(fontSize: 20, fontFamily: "微软雅黑"),
              ),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                        icon: const Icon(
                          FluentIcons.search,
                          size: 17,
                        ),
                        onPressed: () {}),
                    MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                              icon: const Icon(
                                FluentIcons.add,
                                size: 16,
                              ),
                              style: ButtonStyle(
                                  backgroundColor: ButtonState.all(Colors.blue),
                                  foregroundColor:
                                      ButtonState.all(Colors.white),
                                  shape: ButtonState.all(RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15)))),
                              onPressed: () {}),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(30, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //左侧
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Container(
                      width: 15, // 设置宽度
                      height: 15, // 设置高度
                      child: Checkbox(
                        checked: false,
                        onChanged: (value) {
                          // 处理Checkbox状态变化的逻辑
                        },
                      ),
                    ),
                    const Text("  共10项")
                  ],
                ),
              ),
              //右侧
              SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Icon(
                            FluentIcons.sort,
                            size: 12,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "按照名称排序",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ],
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _isGridView
                            ? IconButton(
                                icon: const Icon(
                                  FluentIcons.collapse_menu,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                  FluentIcons.table,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                              ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _listViewWidget() {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: _filesList.length,
        itemBuilder: (context, index) {
          return HoverButton(
              onPressed: () {}, //必须配置 配置以后才可以监听到state状态
              builder: (context, state) {
                // print(state);
                // print(state.isHovering);
                return Container(
                  decoration: BoxDecoration(
                      color: state.isHovering
                          ? const Color.fromRGBO(169, 178, 226, 1)
                          : Colors.white),
                  padding: const EdgeInsets.all(6.0),
                  child: ListTile(
                    leading: const Icon(
                      FluentIcons.fabric_folder_fill,
                      color: Color.fromRGBO(126, 145, 250, 1),
                      size: 28,
                    ),
                    title: Text("${_filesList[index]["title"]}"),
                  ),
                );
              });
        });
  }

  //横向列表展示
  Widget _gridViewWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 0), // 调整此值以改变左边距
      child: GridView.builder(
        itemCount: _filesList.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          maxCrossAxisExtent: 160,
        ),
        itemBuilder: (context, index) {
          return HoverButton(
            onPressed: () {}, // 必须配置 配置以后才可以监听到state状态
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: state.isHovering
                      ? const Color.fromRGBO(169, 178, 226, 1)
                      : Colors.white,
                ),
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      FluentIcons.fabric_folder_fill,
                      size: 68,
                      color: Color.fromRGBO(126, 145, 250, 1),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      height: 46,
                      width: double.infinity,
                      child: Text(
                        "${_filesList[index]["title"]}",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
