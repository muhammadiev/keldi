import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'storage.dart';
import '../models/models.dart';

/// Uniform result wrapper so the UI can branch on success + message.
class ApiResult<T> {
  final bool ok;
  final String message;
  final T? data;
  const ApiResult(this.ok, this.message, [this.data]);
}

class ApiService {
  /// Default backend URL. Overridable at runtime from Settings.
  ///  - Android emulator : http://10.0.2.2:8000
  ///  - iOS simulator    : http://127.0.0.1:8000
  ///  - Real device      : http://<computer-LAN-IP>:8000
  ///  - Production        : https://school.ontest.uz
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  static Future<String> _base() async =>
      (await Storage.baseUrl) ?? defaultBaseUrl;

  static const _timeout = Duration(seconds: 20);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await Storage.token;
      if (t != null) h['Authorization'] = 'Token $t';
    }
    return h;
  }

  static Uri _uri(String base, String path) => Uri.parse('$base$path');

  // ── Auth ─────────────────────────────────────────────────────
  static Future<ApiResult<UserProfile>> login(
      String username, String password) async {
    try {
      final base = await _base();
      final res = await http
          .post(
            _uri(base, '/api/api-token-auth/'),
            headers: await _headers(auth: false),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        return const ApiResult(false, "Login yoki parol noto'g'ri");
      }
      final token = (jsonDecode(res.body) as Map)['token']?.toString();
      if (token == null) return const ApiResult(false, 'Token olinmadi');
      await Storage.setToken(token);

      final profile = await getProfile();
      if (profile.ok && profile.data != null) {
        final p = profile.data!;
        await Storage.setName(p.fullName);
        await Storage.setRole(p.isStaff ? 'admin' : 'teacher');
        return ApiResult(true, 'OK', p);
      }
      // Token stored but profile failed — still logged in.
      return const ApiResult(true, 'OK', null);
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  static Future<ApiResult<UserProfile>> getProfile() async {
    try {
      final base = await _base();
      final res = await http
          .get(_uri(base, '/api/profile/'), headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ApiResult(
            true, 'OK', UserProfile.fromJson(jsonDecode(res.body)));
      }
      if (res.statusCode == 401) return const ApiResult(false, 'Avtorizatsiya kerak');
      return ApiResult(false, 'Profil yuklanmadi (${res.statusCode})');
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, 'Xatolik: $e');
    }
  }

  static Future<void> logout() => Storage.clearSession();

  // ── Attendance ───────────────────────────────────────────────
  /// Returns data map: {distance:int, arrived:'HH:MM:SS', status:String}
  static Future<ApiResult<Map<String, dynamic>>> markArrival({
    required double latitude,
    required double longitude,
    String notes = '',
  }) async {
    try {
      final base = await _base();
      final res = await http
          .post(
            _uri(base, '/api/attendance/mark-arrival/'),
            headers: await _headers(),
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'notes': notes,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = res.statusCode == 200 && body['success'] == true;
      final msg = body['message']?.toString() ?? 'Xatolik';
      final record = body['record'] as Map<String, dynamic>?;
      return ApiResult(ok, msg, {
        'distance': body['distance'],
        'arrived': record?['arrived_at'],
        'status': record?['status'],
      });
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  static Future<ApiResult<List<AttendanceRecord>>> attendanceHistory() async {
    try {
      final base = await _base();
      final res = await http
          .get(_uri(base, '/api/attendance/history/'), headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (body['results'] as List? ?? [])
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult(true, 'OK', results);
      }
      return ApiResult(false, 'Tarix yuklanmadi (${res.statusCode})');
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, 'Xatolik: $e');
    }
  }

  // ── Ariza ────────────────────────────────────────────────────
  static Future<ApiResult<void>> submitAriza({
    required String targetDate, // YYYY-MM-DD
    required String reason,
    int? schoolId,
  }) async {
    try {
      final base = await _base();
      final res = await http
          .post(
            _uri(base, '/api/ariza/submit/'),
            headers: await _headers(),
            body: jsonEncode({
              'target_date': targetDate,
              'reason': reason,
              if (schoolId != null) 'school': schoolId,
            }),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body['success'] == true) {
        return ApiResult(true, body['message']?.toString() ?? 'Yuborildi');
      }
      // Surface first validation error, if any.
      final errors = body['errors'];
      String msg = body['message']?.toString() ?? "Ariza yuborilmadi";
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        msg = (first is List && first.isNotEmpty) ? first.first.toString() : first.toString();
      }
      return ApiResult(false, msg);
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, "Serverga ulanib bo'lmadi: $e");
    }
  }

  static Future<ApiResult<List<ArizaItem>>> arizaHistory() async {
    try {
      final base = await _base();
      final res = await http
          .get(_uri(base, '/api/ariza/history/'), headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (body['results'] as List? ?? [])
            .map((e) => ArizaItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult(true, 'OK', results);
      }
      return ApiResult(false, 'Tarix yuklanmadi (${res.statusCode})');
    } on TimeoutException {
      return const ApiResult(false, 'Server javob bermadi (timeout)');
    } catch (e) {
      return ApiResult(false, 'Xatolik: $e');
    }
  }
}
