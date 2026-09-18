import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> extractWordContent(String wordFilePath, String outputPdfPath) async {
  // 读取 Word 文件
  final bytes = File(wordFilePath).readAsBytesSync();

  // 解压 .docx 文件
  final archive = ZipDecoder().decodeBytes(bytes);

  // 提取文档中的 XML 内容
  String? documentXml;
  for (var file in archive) {
    if (file.isFile && file.name == 'word/document.xml') {
      documentXml = String.fromCharCodes(file.content);
      break;
    }
  }

  if (documentXml == null) {
    print("未找到 document.xml 文件！");
    return;
  }

  // 解析 XML 内容
  var document = XmlDocument.parse(documentXml);

  // 提取文本内容（解析 <w:t> 标签）
  List<String> extractedTexts = [];
  var texts = document.findAllElements('w:t');
  for (var text in texts) {
    extractedTexts.add(text.innerText);
  }

  // 打印提取的文本内容（仅供调试）
  for (var text in extractedTexts) {
    print(text);
  }

  // 生成 PDF 文件
  await generatePdf(extractedTexts, outputPdfPath);
}

Future<void> generatePdf(List<String> texts, String outputPath) async {
  final pdf = pw.Document();

  // 添加提取的文本到 PDF（每个文本一行）
  pdf.addPage(pw.Page(build: (pw.Context context) {
    return pw.Column(
      children: texts.map((text) => pw.Text(text)).toList(),
    );
  }));

  // 保存 PDF 文件
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(await pdf.save());
  print('PDF 文件已生成：$outputPath');
}

void main() async {
  // // WidgetsFlutterBinding.ensureInitialized();
  // // 初始化 sqflite_common_ffi
  // sqfliteFfiInit();
  // // 设置 databaseFactoryFfi 作为默认的 databaseFactory
  // databaseFactory = databaseFactoryFfi;
  //
  // // 数据库配置
  // const tableName = 'ToDolist';
  // const columns = ['title', 'details', 'category', 'create_date'];
  // const columnProperties = ['TEXT', 'TEXT', 'TEXT', 'INTEGER'];
  //
  // // 创建 DBHelper 实例
  // final dbHelper = DBHelper();
  //
  // // 初始化数据库和表
  // final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);
  //
  // await dbHelper.insert(tableName, {
  //   'title': 'Test Title',
  //   'details': 'Test Details',
  //   'category': 'Test Category',
  //   'createDate': DateTime.now().millisecondsSinceEpoch,
  // });
  //
  // await db.close();
  // var millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
  // print(millisecondsSinceEpoch);

// 用户输入 Word 文件路径和输出 PDF 文件路径
  String wordFilePath = 'C:\\Users\\12814\\Desktop\\杰尼亚2024年10月8日迁移365中台\\3PL GCR WMS Integration_8_30.docx';  // 输入 Word 文件路径
  String outputPdfPath = 'C:\\Users\\12814\\Desktop\\杰尼亚2024年10月8日迁移365中台\\output.pdf';   // 输出 PDF 文件路径

  // 调用函数进行转换
  await extractWordContent(wordFilePath, outputPdfPath);



}
