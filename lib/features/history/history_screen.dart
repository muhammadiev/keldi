import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';
import '../ariza/ariza_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<AttendanceRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.attendanceHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _records = res.data ?? [];
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarix'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 90),
                    EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Yuklab bo\u2019lmadi',
                        subtitle: _error),
                  ])
                : _records.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 90),
                        EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'Davomat yozuvlari yo\u2019q'),
                      ])
                    : ContentContainer(child: _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _WeeklyChart(records: _records),
        const SizedBox(height: 8),
        const SectionHeader('Kunlar bo\u2019yicha'),
        for (final r in _records) ...[
          _RecordCard(record: r),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Dependency-free 7-day worked-hours chart (bars).
class _WeeklyChart extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _WeeklyChart({required this.records});

  double _hours(AttendanceRecord r) {
    if (r.arrived == null || r.left == null) return 0;
    final a = _mins(r.arrived!);
    final l = _mins(r.left!);
    if (a == null || l == null || l <= a) return 0;
    return (l - a) / 60.0;
  }

  int? _mins(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // last 7 days (oldest -> newest)
    final last7 = records.take(7).toList().reversed.toList();
    final data = [for (final r in last7) _hours(r)];
    final maxH = data.isEmpty ? 1.0 : (data.reduce((a, b) => a > b ? a : b));
    final maxScale = maxH < 1 ? 1.0 : maxH;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Oxirgi 7 kun ish vaqti',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: last7.isEmpty
                ? Center(
                    child: Text('Ma\u2019lumot yo\u2019q',
                        style: TextStyle(color: scheme.onSurfaceVariant)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < last7.length; i++)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                data[i] > 0 ? data[i].toStringAsFixed(1) : '',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: (data[i] / maxScale) * 90 + 2,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_dow(last7[i].date),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _dow(String iso) {
    try {
      final d = DateTime.parse(iso);
      const days = ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Ya'];
      return days[(d.weekday - 1) % 7];
    } catch (_) {
      return '';
    }
  }
}

class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordCard({required this.record});

  static const _months = [
    'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn',
    'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'
  ];
  String _dd(DateTime d) => d.day.toString().padLeft(2, '0');
  String _mon(DateTime d) => _months[(d.month - 1) % 12];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incomplete = record.left == null;
    final color = !record.isPresent
        ? AppColors.danger
        : (record.isLate ? AppColors.warning : AppColors.success);
    DateTime? d;
    try {
      d = DateTime.parse(record.date);
    } catch (_) {}

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(d != null ? _dd(d) : '--',
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand)),
                Text(d != null ? _mon(d) : '',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.login, size: 15, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(record.arrived ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 14),
                    Icon(Icons.logout, size: 15, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Text(record.left ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(record.statusDisplay,
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (incomplete)
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArizaFormScreen(initialDate: d),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Ariza', style: TextStyle(fontSize: 12)),
            )
          else
            StatusChip(text: record.statusDisplay, color: color),
        ],
      ),
    );
  }
}
