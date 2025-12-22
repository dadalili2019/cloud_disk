///  @author caoqian
/// @since 2025-12-21 19:21
/// @Description: 命中来源 DTO

class SourceRef {
  final String source;
  final String title;
  final double score;

  SourceRef({
    required this.source,
    required this.title,
    required this.score,
  });

  factory SourceRef.fromJson(Map<String, dynamic> json) {
    return SourceRef(
      source: json['source'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}


