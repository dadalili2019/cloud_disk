import 'package:fluent_ui/fluent_ui.dart';

//横向列表展示
Widget gridViewWidget(List<Map<String, String>> _filesList) {
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
                    ? const Color.fromRGBO(245, 245, 246, 1)
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