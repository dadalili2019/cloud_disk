// share_folder_list_view.dart
import 'package:fluent_ui/fluent_ui.dart';

Widget listViewWidget(List<Map<String, String>> filesList) {
  return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      itemCount: filesList.length,
      itemBuilder: (context, index) {
        bool isFolder = filesList[index]["size"] == "Directory"; // 判断是否是文件夹

        return HoverButton(
            onPressed: () {}, // 必须配置，配置后才能监听到 state 状态
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                    color: state.isHovering
                        ? const Color.fromRGBO(245, 245, 246, 1)
                        : Colors.white),
                padding: const EdgeInsets.all(6.0),
                child: ListTile(
                  leading: Icon(
                    isFolder ? FluentIcons.fabric_folder_fill : FluentIcons.document,
                    color: isFolder
                        ? const Color.fromRGBO(126, 145, 250, 1)
                        : const Color.fromRGBO(31, 41, 55, 1),
                    size: 28,
                  ),
                  title: Text("${filesList[index]["title"]}"),
                ),
              );
            });
      });
}
