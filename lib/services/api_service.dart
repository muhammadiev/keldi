import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result wrapper so screens can branch on success/failure with a message.
class ApiResult {
  final bool success;
  final String message;
  final dynamic data;
  const ApiResult(this.success, this.message, [this.data]);
}

/// Single place that talks to the Django backend.
///
/// IMPORTANT: set [baseUrl] for your environment:
///   - Android emulator : http://10.0.2.2:8000
///   - iOS simulator    : http://127.0.0.1:8000
///   - Real device      : http://<your-computer-LAN-IP>:8000  (e.g. 192.168.1.20)
///   - Production        : https://school.ontest.uz
class ApiService {
  // TODO: change this to match where your Django server runs.
  static const String baseUrl = "https://school.ontest.uz";

  static const String _tokenKey = "auth_token";
  static const String _roleKey = "role";
  static const String _nameKey = "full_name";

  // ── Token helpers ──────────────────────────────────────────
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async => (await _token()) != null;

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.setBool('isLoggedIn', false);
  }

  static Map<String, String> _authHeaders(String token) => {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      };

  // ── Auth ───────────────────────────────────────────────────
  /// Logs in against /api/api-token-auth/, stores the token, then fetches
  /// the profile to learn the user's name and whether they are staff.
  static Future<ApiResult> login(String username, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/api-token-auth/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"username": username, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return const ApiResult(false, "Login yoki parol noto'g'ri");
      }

      final token = jsonDecode(res.body)["token"] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setBool('isLoggedIn', true);

      // Fetch profile to determine role + name (non-fatal if it fails)
      final profile = await getProfile();
      String role = "teacher";
      if (profile.success && profile.data != null) {
        final p = profile.data as Map<String, dynamic>;
        role = (p["is_staff"] == true) ? "admin" : "teacher";
        await prefs.setString(_nameKey, p["full_name"]?.toString() ?? username);
      }
      await prefs.setString(_roleKey, role);

      return ApiResult(true, "OK", {"role": role});
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  /// GET /api/profile/
  static Future<ApiResult> getProfile() async {
    final token = await _token();
    if (token == null) return const ApiResult(false, "Not logged in");
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/api/profile/"), headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return ApiResult(true, "OK", jsonDecode(res.body));
      }
      return ApiResult(false, "Profil yuklanmadi (${res.statusCode})");
    } catch (e) {
      return ApiResult(false, "Xatolik: $e");
    }
  }

  // ── Attendance ─────────────────────────────────────────────
  /// POST /api/attendance/mark-arrival/  — the KELDIM action.
  /// Backend verifies the coordinates are within ~200m of a school.
  static Future<ApiResult> markArrival({
    required double latitude,
    required double longitude,
    String notes = "",
  }) async {
    final token = await _token();
    if (token == null) return const ApiResult(false, "Not logged in");
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/attendance/mark-arrival/"),
            headers: _authHeaders(token),
            body: jsonEncode({
              "latitude": latitude,
              "longitude": longitude,
              "notes": notes,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = res.statusCode == 200 && (body["success"] == true);
      return ApiResult(ok, body["message"]?.toString() ?? "Xatolik", body);
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  /// GET /api/attendance/history/
  static Future<ApiResult> attendanceHistory() async {
    final token = await _token();
    if (token == null) return const ApiResult(false, "Not logged in");
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/api/attendance/history/"),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return ApiResult(true, "OK", jsonDecode(res.body));
      }
      return ApiResult(false, "Tarix yuklanmadi (${res.statusCode})");
    } catch (e) {
      return ApiResult(false, "Xatolik: $e");
    }
  }

  // ── Ariza ──────────────────────────────────────────────────
  /// POST /api/ariza/submit/
  static Future<ApiResult> submitAriza({
    required String targetDate, // "YYYY-MM-DD"
    required String reason,
    int? schoolId,
  }) async {
    final token = await _token();
    if (token == null) return const ApiResult(false, "Not logged in");
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/ariza/submit/"),
            headers: _authHeaders(token),
            body: jsonEncode({
              "target_date": targetDate,
              "reason": reason,
              if (schoolId != null) "school": schoolId,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = res.statusCode == 201 && (body["success"] == true);
      return ApiResult(ok, body["message"]?.toString() ?? "Xatolik", body);
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  /// GET /api/ariza/history/
  static Future<ApiResult> arizaHistory() async {
    final token = await _token();
    if (token == null) return const ApiResult(false, "Not logged in");
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/api/ariza/history/"),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return ApiResult(true, "OK", jsonDecode(res.body));
      }
      return ApiResult(false, "Tarix yuklanmadi (${res.statusCode})");
    } catch (e) {
      return ApiResult(false, "Xatolik: $e");
    }
  }
}
