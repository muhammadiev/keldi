import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/ui.dart';
import '../history/history_screen.dart';
import '../ariza/ariza_list_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  bool _arrived = false;
  bool _left = false;
  String? _arrivedTime;
  String? _leftTime;
  int? _distance;

  List<AttendanceRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    AppState.instance.refreshUser();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final res = await ApiService.attendanceHistory();
    if (!mounted) return;
    if (res.ok && res.data != null) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      AttendanceRecord? today;
      for (final r in res.data!) {
        if (r.date == todayStr) {
          today = r;
          break;
        }
      }
      setState(() {
        _records = res.data!;
        _arrived = today?.arrived != null;
        _left = today?.left != null;
        _arrivedTime = today?.arrived;
        _leftTime = today?.left;
      });
    }
  }

  Future<void> _action() async {
    if (_busy || _left) return;
    setState(() => _busy = true);

    final loc = await LocationService.current();
    if (!mounted) return;
    if (!loc.ok || loc.position == null) {
      setState(() => _busy = false);
      showSnack(context, loc.message, color: AppColors.warning);
      return;
    }

    final isArrival = !_arrived;
    final res = isArrival
        ? await ApiService.markArrival(
            latitude: loc.position!.latitude, longitude: loc.position!.longitude)
        : await ApiService.markDeparture(
            latitude: loc.position!.latitude, longitude: loc.position!.longitude);

    if (!mounted) return;
    setState(() => _busy = false);

    if (res.ok) {
      setState(() {
        final d = res.data?['distance'];
        if (d is num) _distance = d.toInt();
        if (isArrival) {
          _arrived = true;
          _arrivedTime = res.data?['arrived']?.toString();
        } else {
          _left = true;
          _leftTime = res.data?['left']?.toString();
        }
      });
      showSnack(context, res.message,
          color: isArrival ? AppColors.success : AppColors.danger);
      _loadToday();
    } else {
      showSnack(context, res.message, color: AppColors.danger);
    }
  }

  String get _mainLabel {
    if (_left) return 'YAKUNLANDI';
    if (_arrived) return 'KETDIM';
    return 'KELDIM';
  }

  String get _subLabel {
    if (_left) return 'Bugungi ish yakunlandi';
    if (_arrived) return 'Ishdan chiqish';
    return 'Ishga kelish';
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.user;
    final scheme = Theme.of(context).colorScheme;
    final dateStr = _fmtDate(DateTime.now());
    final weekday = _weekdayUz(DateTime.now());
    final schoolName =
        (user != null && user.schools.isNotEmpty) ? user.schools.first.name : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(weekday,
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          if (schoolName != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.brand.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 15, color: AppColors.brand),
                  const SizedBox(width: 5),
                  Text(
                    _distance != null ? '$schoolName • ${_distance}m' : schoolName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await AppState.instance.refreshUser();
                  await _loadToday();
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ContentContainer(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 720;
                          final button = _CheckButton(
                            label: _mainLabel,
                            sub: _subLabel,
                            arrived: _arrived,
                            done: _left,
                            busy: _busy,
                            arrivedTime: _arrivedTime,
                            leftTime: _leftTime,
                            onTap: _action,
                          );
                          final kpis = _KpiGrid(records: _records);
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: button),
                                const SizedBox(width: 20),
                                Expanded(child: kpis),
                              ],
                            );
                          }
                          return Column(children: [
                            button,
                            const SizedBox(height: 24),
                            kpis,
                          ]);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _BottomNav(),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  String _weekdayUz(DateTime d) {
    const days = [
      'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
      'Juma', 'Shanba', 'Yakshanba'
    ];
    return days[(d.weekday - 1) % 7];
  }
}

class _CheckButton extends StatelessWidget {
  final String label;
  final String sub;
  final bool arrived;
  final bool done;
  final bool busy;
  final String? arrivedTime;
  final String? leftTime;
  final VoidCallback onTap;

  const _CheckButton({
    required this.label,
    required this.sub,
    required this.arrived,
    required this.done,
    required this.busy,
    required this.arrivedTime,
    required this.leftTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final gradient = done
        ? const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)])
        : arrived
            ? const LinearGradient(
                colors: [AppColors.danger, Color(0xFFF87171)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(
                colors: [AppColors.success, Color(0xFF34D399)],
                begin: Alignment.topLeft, end: Alignment.bottomRight);
    final glow = done ? Colors.grey : (arrived ? AppColors.danger : AppColors.success);

    // status pill text
    final String pill;
    final Color pillColor;
    if (done) {
      pill = 'Bugun ish yakunlandi ✓';
      pillColor = AppColors.success;
    } else if (arrived) {
      pill = 'Ishda${arrivedTime != null ? ' • Keldi: $arrivedTime' : ''}';
      pillColor = AppColors.success;
    } else {
      pill = 'Bugun hali kelinmagan';
      pillColor = AppColors.brand;
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: pillColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: pillColor.withOpacity(0.4)),
          ),
          child: Text(pill,
              style: TextStyle(
                  color: pillColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: (busy || done) ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: glow.withOpacity(0.45),
                    blurRadius: 40,
                    spreadRadius: 4),
              ],
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 4))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_outline
                              : arrived
                                  ? Icons.logout_rounded
                                  : Icons.login_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1)),
                        const SizedBox(height: 4),
                        Text(sub,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14)),
                      ],
                    ),
            ),
          ),
        ),
        if (done && leftTime != null) ...[
          const SizedBox(height: 16),
          Text('Keldi: ${arrivedTime ?? '—'}   ·   Ketdi: $leftTime',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5)),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _KpiGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.isPresent).length;
    final late = records.where((r) => r.isLate).length;
    final onTime = present - late;
    final rate = present == 0 ? 0 : ((onTime / present) * 100).round();

    final cards = [
      StatCard(icon: Icons.event_available, value: '$present', label: 'Kelgan kunlar', color: AppColors.brand),
      StatCard(icon: Icons.verified, value: '$rate%', label: "O'z vaqtida", color: AppColors.success),
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
      childAspectRatio: 1.2,
      children: cards,
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Tarix',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _NavItem(
            icon: Icons.description_outlined,
            label: 'Arizalarim',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ArizaListScreen())),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Sozlamalar',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brand, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
