///  @author caoqian
/// @since 2024-04-30 12:07
/// @Description: HTTP请求工具类

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class HttpUtils {
  static final HttpUtils _instance = HttpUtils._internal();
  static final Logger _logger = Logger('HttpUtils');
  static final http.Client _client = http.Client(); // 定义一个全局的 HTTP 客户端实例

  factory HttpUtils() {
    return _instance;
  }

  HttpUtils._internal();

  static Future<http.Response> getRequest(String baseUrl, String path,
      {int timeoutSeconds = 10}) async {
    try {
      var response = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      _logger.severe('Error in getRequest: $e');
      throw Exception('Failed to send GET request: $e');
    } finally {
      _logger.info('Cleaning up resources in finally block');
      _client.close();
    }
  }

  static Future<http.Response> postRequest(
      String baseUrl, String path, Map<String, String> body,
      {int timeoutSeconds = 10}) async {
    try {
      var response = await http
          .post(Uri.parse('$baseUrl$path'), body: body)
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      _logger.severe('Error in postRequest: $e');
      throw Exception('Failed to send POST request: $e');
    } finally {
      _logger.info('Cleaning up resources in finally block');
      _client.close();
    }
  }

  static Future<http.Response> putRequest(
      String baseUrl, String path, Map<String, String> body,
      {int timeoutSeconds = 10}) async {
    try {
      var response = await http
          .put(Uri.parse('$baseUrl$path'), body: body)
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      _logger.severe('Error in putRequest: $e');
      throw Exception('Failed to send PUT request: $e');
    } finally {
      _logger.info('Cleaning up resources in finally block');
      _client.close();
    }
  }

  static Future<http.Response> deleteRequest(String baseUrl, String path,
      {int timeoutSeconds = 10}) async {
    try {
      var response = await http
          .delete(Uri.parse('$baseUrl$path'))
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      _logger.severe('Error in deleteRequest: $e');
      throw Exception('Failed to send DELETE request: $e');
    } finally {
      _logger.info('Cleaning up resources in finally block');
      _client.close();
    }
  }
}
