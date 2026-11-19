import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiResponse {
  final bool ok;
  final int status;
  final Map<String, dynamic> json;
  final String? error;
  final bool network; // true = gagal terhubung (server mati / alamat salah / tidak ada internet)
  const ApiResponse(this.ok, this.status, this.json, this.error, this.network);
}

/// Pembungkus HTTP sederhana untuk backend PHP.
class ApiClient {
  String? token;

  Future<ApiResponse> send(
    String method,
    String route, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    try {
      final base = Uri.parse(ApiConfig.baseUrl);
      final q = Map<String, String>.from(base.queryParameters);
      q['r'] = route;
      final uri = base.replace(queryParameters: q);
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      final t = token;
      if (t != null && t.isNotEmpty) {
        headers['Authorization'] = 'Bearer $t';
        headers['X-Auth-Token'] = t;
      }
      http.Response res;
      if (method == 'GET') {
        res = await http.get(uri, headers: headers).timeout(timeout);
      } else {
        res = await http.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{})).timeout(timeout);
      }
      Map<String, dynamic> j = <String, dynamic>{};
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d is Map) j = Map<String, dynamic>.from(d);
      } catch (_) {
        return ApiResponse(false, res.statusCode, j, 'Respons server tidak valid (cek PHP / config.php)', false);
      }
      final ok = res.statusCode >= 200 && res.statusCode < 300 && j['ok'] != false;
      final err = ok ? null : (j['error'] ?? 'Permintaan gagal (${res.statusCode})').toString();
      return ApiResponse(ok, res.statusCode, j, err, false);
    } catch (_) {
      return const ApiResponse(false, 0, <String, dynamic>{}, 'Tidak dapat terhubung ke server', true);
    }
  }
}
