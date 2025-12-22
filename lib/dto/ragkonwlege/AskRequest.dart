///  @author caoqian
/// @since 2025-12-21 19:20
/// @Description: 请求 DTO

class AskRequest {
  final String question;
  final bool debug;
  final bool returnSources;

  AskRequest({
    required this.question,
    this.debug = false,
    this.returnSources = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'debug': debug,
      'returnSources': returnSources,
    };
  }
}
