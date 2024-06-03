import 'package:http/http.dart' as http;

class HttpHelper {
  final String baseUrl = 'http://localhost:8089/DesktopServiceApplication';

  Future<http.Response> getRequest(String path, {int timeoutSeconds = 10}) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl$path')).timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      throw Exception('Failed to send GET request: $e');
    }
  }

  Future<http.Response> postRequest(String path, Map<String, String> body, {int timeoutSeconds = 10}) async {
    try {
      var response = await http.post(Uri.parse('$baseUrl$path'), body: body).timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      throw Exception('Failed to send POST request: $e');
    }
  }

  Future<http.Response> putRequest(String path, Map<String, String> body, {int timeoutSeconds = 10}) async {
    try {
      var response = await http.put(Uri.parse('$baseUrl$path'), body: body).timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      throw Exception('Failed to send PUT request: $e');
    }
  }

  Future<http.Response> deleteRequest(String path, {int timeoutSeconds = 10}) async {
    try {
      var response = await http.delete(Uri.parse('$baseUrl$path')).timeout(Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      throw Exception('Failed to send DELETE request: $e');
    }
  }
}