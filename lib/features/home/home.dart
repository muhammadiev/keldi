import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ← add to pubspec: intl: ^0.19.0

// Import for navigation
import '../ariza/ariza_list.dart';
import '../history/history.dart';
import '../settings/settings_screen.dart'; // adjust path according to your structure
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool hasCheckedInToday = false;
  bool hasCheckedOutToday = false;
  bool isInsideRadius = true;
  bool _isSubmitting = false;
  String currentSchool = "—";
  String? arrivedTimeLabel; // e.g. "08:17", from server response
  double? distanceMeters;
  DateTime today = DateTime.now();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await ApiService.getProfile();
    if (!mounted || !res.success || res.data == null) return;
    final p = res.data as Map<String, dynamic>;
    final schools = (p["schools"] as List?) ?? [];
    setState(() {
      if (schools.isNotEmpty) currentSchool = schools.first["name"] ?? "—";
    });
  }

  /// The KELDIM / KETDIM action: read GPS, then call the backend.
  Future<void> _handleCheck() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // 1. Get GPS position
    final loc = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (!loc.success || loc.position == null) {
      setState(() => _isSubmitting = false);
      _snack(loc.message, Colors.orange);
      return;
    }

    // 2. Send to backend (mark-arrival verifies distance server-side)
    final res = await ApiService.markArrival(
      latitude: loc.position!.latitude,
      longitude: loc.position!.longitude,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      final record = (res.data is Map) ? res.data["record"] : null;
      setState(() {
        if (!hasCheckedInToday) {
          hasCheckedInToday = true;
          arrivedTimeLabel = record?["arrived_at"]?.toString();
        } else {
          hasCheckedOutToday = true;
        }
        if (res.data is Map && res.data["distance"] != null) {
          distanceMeters = (res.data["distance"] as num).toDouble();
          isInsideRadius = true;
        }
      });
      _snack(res.message, const Color(0xFF10B981));
    } else {
      // e.g. "You are 250m away..." (403) or auth/server errors
      setState(() => isInsideRadius = false);
      _snack(res.message, Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get currentDateFormatted => DateFormat('dd MMMM yyyy', 'uz_UZ').format(today);
  String get weekdayUz => DateFormat('EEEE', 'uz_UZ').format(today);

  String get buttonMainText {
    if (hasCheckedOutToday) return "Bugun yakunlandi";
    if (hasCheckedInToday) return "KETDIM";
    return "KELDIM";
  }

  String get buttonSubtitle {
    if (hasCheckedOutToday) return "Bugungi ish yakunlandi ✓";
    if (hasCheckedInToday) return "Ishdan chiqish";
    return "Ishga kelish";
  }

  bool get buttonEnabled => !hasCheckedOutToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0617) : const Color(0xFFFAF8FF);
    final cardColor = isDark ? const Color(0xFF1C1430) : Colors.white;
    final textColor = isDark ? const Color(0xFFDFD4FF) : const Color(0xFF2A1845);
    final lavender = isDark ? const Color(0xFFCC99FF) : const Color(0xFFB794F4);
    final neonGreen = isDark ? const Color(0xFF39FF14) : const Color(0xFF4CAF50);
    final neonRed = isDark ? const Color(0xFFFF3366) : const Color(0xFFE53935);

    final distanceColor = isInsideRadius ? neonGreen : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentDateFormatted,
              style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w600),
            ),
            Text(
              weekdayUz,
              style: TextStyle(color: textColor.withOpacity(0.65), fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: distanceColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: distanceColor.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 17, color: distanceColor),
                  const SizedBox(width: 6),
                  Text(
                    distanceMeters == null
                        ? currentSchool
                        : "$currentSchool • ${distanceMeters!.toStringAsFixed(0)} m",
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: hasCheckedOutToday
                              ? neonGreen.withOpacity(0.18)
                              : (hasCheckedInToday
                              ? neonGreen.withOpacity(0.12)
                              : cardColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: hasCheckedOutToday
                                ? neonGreen
                                : (hasCheckedInToday ? neonGreen : lavender),
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          hasCheckedOutToday
                              ? "Bugun ish yakunlandi ✓"
                              : hasCheckedInToday
                              ? "Ishda • Keldi: ${arrivedTimeLabel ?? '--:--'}"
                              : "Bugun hali kelinmagan",
                          style: TextStyle(
                            color: hasCheckedOutToday || hasCheckedInToday ? neonGreen : lavender,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Main Action Button ──
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTapDown: (_) => _animController.forward(),
                        onTapUp: (_) => _animController.reverse(),
                        onTapCancel: () => _animController.reverse(),
                        onTap: (buttonEnabled && !_isSubmitting)
                            ? _handleCheck
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasCheckedOutToday
                                  ? [const Color(0xFF4A4A6A), const Color(0xFF2A2A44)]
                                  : hasCheckedInToday
                                  ? [neonRed.withOpacity(0.9), neonRed.withOpacity(0.65)]
                                  : [neonGreen.withOpacity(0.9), neonGreen.withOpacity(0.65)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (hasCheckedOutToday
                                    ? Colors.grey
                                    : (hasCheckedInToday ? neonRed : neonGreen))
                                    .withOpacity(0.45),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 4,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        buttonMainText,
                                        style: TextStyle(
                                          fontSize: hasCheckedOutToday ? 38 : 52,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        buttonSubtitle,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.82),
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    if (!buttonEnabled)
                      Text(
                        "Bugungi kun uchun barcha amallar bajarildi",
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom navigation row
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomActionItem(
                    icon: Icons.history,
                    label: "Tarix",
                    color: lavender,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  _BottomActionItem(
                    icon: Icons.description_outlined,
                    label: "Arizalarim",
                    color: lavender,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArizaListScreen(),
                        ),
                      );
                    },
                  ),
                  _BottomActionItem(
                    icon: Icons.settings_outlined,
                    label: "Sozlamalar",
                    color: lavender,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}