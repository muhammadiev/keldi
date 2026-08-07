/// Data models mirroring the Django REST responses.

class UserProfile {
  final String username;
  final String fullName;
  final String? employeeId;
  final String? phone;
  final bool isStaff;
  final bool isTeacher;
  final List<SchoolRef> schools;

  const UserProfile({
    required this.username,
    required this.fullName,
    this.employeeId,
    this.phone,
    required this.isStaff,
    required this.isTeacher,
    this.schools = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        username: j['username']?.toString() ?? '',
        fullName: j['full_name']?.toString() ?? '',
        employeeId: j['employee_id']?.toString(),
        phone: j['phone']?.toString(),
        isStaff: j['is_staff'] == true,
        isTeacher: j['is_teacher'] == true,
        schools: ((j['schools'] as List?) ?? [])
            .map((e) => SchoolRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class SchoolRef {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;

  const SchoolRef({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory SchoolRef.fromJson(Map<String, dynamic> j) => SchoolRef(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        latitude: _toD(j['latitude']),
        longitude: _toD(j['longitude']),
      );

  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class AttendanceRecord {
  final int id;
  final String date; // YYYY-MM-DD
  final String? arrived;
  final String? left;
  final String statusDisplay;
  final bool isPresent;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.arrived,
    this.left,
    required this.statusDisplay,
    required this.isPresent,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: (j['id'] as num?)?.toInt() ?? 0,
        date: j['date']?.toString() ?? '',
        arrived: j['arrived_at_formatted']?.toString(),
        left: j['left_at_formatted']?.toString(),
        statusDisplay: j['status_display']?.toString() ?? '',
        isPresent: j['is_present'] == true,
        notes: j['notes']?.toString(),
      );

  bool get isLate => statusDisplay.toLowerCase().contains('late');
}

class ArizaItem {
  final String arizaId;
  final String targetDate;
  final String? schoolName;
  final String statusDisplay;
  final String cause;
  final String submittedAt;

  const ArizaItem({
    required this.arizaId,
    required this.targetDate,
    this.schoolName,
    required this.statusDisplay,
    required this.cause,
    required this.submittedAt,
  });

  factory ArizaItem.fromJson(Map<String, dynamic> j) => ArizaItem(
        arizaId: j['ariza_id']?.toString() ?? '',
        targetDate: j['target_date']?.toString() ?? '',
        schoolName: j['school_name']?.toString(),
        statusDisplay: j['status_display']?.toString() ?? '',
        cause: j['cause']?.toString() ?? '',
        submittedAt: j['submitted_at']?.toString() ?? '',
      );

  String get statusKey {
    final s = statusDisplay.toLowerCase();
    if (s.contains('tasdiq') || s.contains('approv')) return 'approved';
    if (s.contains('rad') || s.contains('reject')) return 'rejected';
    return 'pending';
  }
}
