import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'http://10.0.2.2:4028';

class BackendException implements Exception {
  final String message;
  const BackendException(this.message);
  @override
  String toString() => message;
}

Future<Map<String, dynamic>> uploadCsv(Uint8List bytes, String filename) async {
  final uri = Uri.parse('$_base/api/parse-earnings');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
  final streamed = await request.send().timeout(const Duration(seconds: 15));
  final body = await streamed.stream.bytesToString();
  if (streamed.statusCode != 200) throw BackendException('Upload failed: $body');
  return json.decode(body) as Map<String, dynamic>;
}

Future<Uint8List> downloadReport(Map<String, dynamic> profileJson) async {
  final uri = Uri.parse('$_base/api/report');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'profile': profileJson}),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw BackendException('Report failed (${response.statusCode}): ${response.body}');
  }
  return response.bodyBytes;
}

Future<String?> sendChatMessage(List<Map<String, String>> messages, Map<String, dynamic> profileJson) async {
  final uri = Uri.parse('$_base/api/chat');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'messages': messages, 'profile': profileJson}),
  ).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) return null;
  final data = json.decode(response.body) as Map<String, dynamic>;
  return data['reply'] as String?;
}

Future<Map<String, dynamic>?> analyzeFinances(Map<String, dynamic> profileJson) async {
  final uri = Uri.parse('$_base/api/analyze');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(profileJson),
  ).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) return null;
  return json.decode(response.body) as Map<String, dynamic>;
}
