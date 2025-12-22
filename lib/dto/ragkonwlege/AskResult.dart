import 'package:cloud_disk/dto/ragkonwlege/SourceRef.dart';

///  @author caoqian
/// @since 2025-12-21 19:22
/// @Description: 响应 DTO

class AskResult {
  final String status; // SUCCESS / NO_ANSWER / ERROR
  final String answer;
  final List<SourceRef> sources;
  final String? errorCode;
  final String? errorMessage;

  AskResult({
    required this.status,
    required this.answer,
    required this.sources,
    this.errorCode,
    this.errorMessage,
  });

  factory AskResult.fromJson(Map<String, dynamic> json) {
    return AskResult(
      status: json['status'] as String,
      answer: json['answer'] as String,
      sources: (json['sources'] as List)
          .map((e) => SourceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorCode: json['errorCode'],
      errorMessage: json['errorMessage'],
    );
  }

  /// 工程上非常好用的几个辅助判断
  bool get isSuccess => status == 'SUCCESS';
  bool get isNoAnswer => status == 'NO_ANSWER';
  bool get isError => status == 'ERROR';
}


