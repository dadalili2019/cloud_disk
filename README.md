# cloud_disk

自用小工具合集 ~.~
将来会集成例如:天气显示小组件、日历、提醒待办项等等。。。。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 目前已完成功能介绍

- 获取局域网内共享目录中的内容(目前只支持windows系统)

PS：需要提前设置好windows电脑之间的网络共享，并且暂不支持加密访问。

1. 可以通过指定共享目录读取目录下所有的文件和文件夹
2. 支持TXT文件双击打开和编译保存。
3. 支持png&jpg&jpeg文件双击预览。
4. 刷新当前目录的内容。
5. 返回顶级目录的按钮。
6. 通过文件名搜索文件所在位置。
7. 支持目录下对文件的排序规则。
8. 支持不同的网络共享目录地址的切换访问(需要填写对应的目录访问路径)。
9. 可以添加待办事项，与主页面的待办事项展示关联。

- 欢迎页面

1. 天气显示
2. 日历显示
3. 待办事项展示
4. gif图片展示


## 目前项目中遇到的待解决的问题

- 共享网络目录功能中，操作上传或者新增文件夹或者文件，存在Access Denied的问题。(目前还未找到问题发生的原因)
- 首页中 天气展示需要调用API，每天调用次数是1000次，需要考虑是否首次调用就将数据存储起来。减少调用次数，发生浪费的现象。(已解决)



