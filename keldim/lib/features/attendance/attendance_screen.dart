import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Davomat tarixi')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Yuklab bo\u2019lmadi',
                      subtitle: _error,
                    ),
                  ])
                : _records.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Davomat yozuvlari yo\u2019q',
                        ),
                      ])
                    : ContentContainer(child: _buildList(context)),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final present = _records.where((r) => r.isPresent).length;
    final late = _records.where((r) => r.isLate).length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                  icon: Icons.event_available,
                  value: '$present',
                  label: 'Kelgan kunlar',
                  color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                  icon: Icons.timelapse,
                  value: '$late',
                  label: 'Kechikkan',
                  color: AppColors.warning),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader('Barcha yozuvlar'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (int i = 0; i < _records.length; i++) ...[
                _row(context, _records[i]),
                if (i != _records.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(BuildContext context, AttendanceRecord r) {
    final scheme = Theme.of(context).colorScheme;
    final color = !r.isPresent
        ? AppColors.danger
        : (r.isLate ? AppColors.warning : AppColors.success);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              r.isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmt(r.date),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Keldi: ${r.arrived ?? '—'}   ·   Ketdi: ${r.left ?? '—'}',
                  style:
                      TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          StatusChip(text: r.statusDisplay, color: color),
        ],
      ),
    );
  }

  String _fmt(String isoDate) {
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }
}
