import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _checkingIn = false;
  bool _arrivedToday = false;
  String? _arrivedTime;
  int? _distance;

  List<AttendanceRecord> _recent = const [];
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    AppState.instance.refreshUser();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final res = await ApiService.attendanceHistory();
    if (!mounted) return;
    setState(() {
      _loadingRecent = false;
      if (res.ok && res.data != null) {
        _recent = res.data!;
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        AttendanceRecord? todayRec;
        for (final r in _recent) {
          if (r.date == todayStr) {
            todayRec = r;
            break;
          }
        }
        if (todayRec != null && todayRec.arrived != null) {
          _arrivedToday = true;
          _arrivedTime = todayRec.arrived;
        }
      }
    });
  }

  Future<void> _checkIn() async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);

    final loc = await LocationService.current();
    if (!mounted) return;
    if (!loc.ok || loc.position == null) {
      setState(() => _checkingIn = false);
      showSnack(context, loc.message, color: AppColors.warning);
      return;
    }

    final res = await ApiService.markArrival(
      latitude: loc.position!.latitude,
      longitude: loc.position!.longitude,
    );
    if (!mounted) return;
    setState(() => _checkingIn = false);

    if (res.ok) {
      setState(() {
        _arrivedToday = true;
        _arrivedTime = res.data?['arrived']?.toString();
        final d = res.data?['distance'];
        if (d is num) _distance = d.toInt();
      });
      showSnack(context, res.message, color: AppColors.success);
      _loadRecent();
    } else {
      showSnack(context, res.message, color: AppColors.danger);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Xayrli tong';
    if (h < 18) return 'Xayrli kun';
    return 'Xayrli kech';
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.user;

    return RefreshIndicator(
      onRefresh: () async {
        await AppState.instance.refreshUser();
        await _loadRecent();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ContentContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(greeting: _greeting, user: user),
                const SizedBox(height: 20),
                // Responsive: side-by-side on wide screens.
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 720;
                    final button = _CheckInButton(
                      arrived: _arrivedToday,
                      loading: _checkingIn,
                      arrivedTime: _arrivedTime,
                      onTap: _checkIn,
                    );
                    final status = _StatusPanel(
                      arrived: _arrivedToday,
                      arrivedTime: _arrivedTime,
                      distance: _distance,
                      school: (user != null && user.schools.isNotEmpty)
                          ? user.schools.first.name
                          : null,
                    );
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: button),
                          const SizedBox(width: 20),
                          Expanded(child: status),
                        ],
                      );
                    }
                    return Column(children: [button, const SizedBox(height: 20), status]);
                  },
                ),
                const SizedBox(height: 24),
                _StatsGrid(records: _recent),
                const SizedBox(height: 24),
                const SectionHeader('So\u2019nggi davomat'),
                _RecentList(records: _recent, loading: _loadingRecent),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String greeting;
  final UserProfile? user;
  const _Hero({required this.greeting, this.user});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting${user != null ? ',' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.fullName ?? 'Xush kelibsiz',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user != null)
            InitialsAvatar(initials: user!.initials, size: 52),
        ],
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final bool arrived;
  final bool loading;
  final String? arrivedTime;
  final VoidCallback onTap;

  const _CheckInButton({
    required this.arrived,
    required this.loading,
    required this.arrivedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = arrived;
    final gradient = done
        ? const LinearGradient(
            colors: [AppColors.success, Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppColors.brandGradient;
    final glowColor = done ? AppColors.success : AppColors.brand;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Column(
        children: [
          GestureDetector(
            onTap: (loading || done) ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.45),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 4),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            done ? Icons.check_rounded : Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            done ? 'KELDINGIZ' : 'KELDIM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            done
                ? 'Bugun ish boshlandi${arrivedTime != null ? ' • $arrivedTime' : ''}'
                : 'Ishga kelganingizni tasdiqlash uchun bosing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool arrived;
  final String? arrivedTime;
  final int? distance;
  final String? school;

  const _StatusPanel({
    required this.arrived,
    this.arrivedTime,
    this.distance,
    this.school,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bugungi holat',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _row(context, Icons.circle,
              arrived ? 'Ishda' : 'Hali kelinmagan',
              color: arrived ? AppColors.success : AppColors.slate),
          const Divider(height: 24),
          _row(context, Icons.schedule,
              arrivedTime != null ? 'Kelgan vaqt: $arrivedTime' : 'Kelgan vaqt: —'),
          const Divider(height: 24),
          _row(context, Icons.apartment,
              school ?? 'Maktab biriktirilmagan'),
          if (distance != null) ...[
            const Divider(height: 24),
            _row(context, Icons.near_me, 'Masofa: ${distance}m'),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text,
      {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: scheme.onSurface)),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _StatsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.isPresent).length;
    final late = records.where((r) => r.isLate).length;
    final onTime = present - late;
    final rate = present == 0 ? 0 : ((onTime / present) * 100).round();

    final cards = [
      StatCard(icon: Icons.event_available, value: '$present', label: 'Kelgan kunlar (30)', color: AppColors.brand),
      StatCard(icon: Icons.verified, value: '$rate%', label: 'O\u2019z vaqtida', color: AppColors.success),
      StatCard(icon: Icons.timelapse, value: '$late', label: 'Kechikkan', color: AppColors.warning),
      StatCard(icon: Icons.calendar_month, value: '${records.length}', label: 'Jami yozuv', color: AppColors.slate),
    ];

    final cols = context.gridColumns(mobile: 2, tablet: 4, desktop: 4);
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: cards,
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final bool loading;
  const _RecentList({required this.records, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (records.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Yozuvlar yo\u2019q',
          subtitle: 'Kelganingizni qayd etganingizdan so\u2019ng bu yerda ko\u2019rinadi.',
        ),
      );
    }
    final shown = records.take(5).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            _tile(context, shown[i]),
            if (i != shown.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, AttendanceRecord r) {
    final scheme = Theme.of(context).colorScheme;
    final color = r.isLate ? AppColors.warning : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmt(r.date),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Keldi: ${r.arrived ?? '—'}  ·  Ketdi: ${r.left ?? '—'}',
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant)),
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
      final d = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(d);
    } catch (_) {
      return isoDate;
    }
  }
}
