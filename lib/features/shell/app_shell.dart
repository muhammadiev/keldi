import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../ariza/ariza_screen.dart';
import '../settings/settings_screen.dart';

/// Adaptive navigation container:
///  - mobile  → bottom NavigationBar
///  - tablet+ → side NavigationRail
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Bosh sahifa', 'Davomat', 'Arizalar', 'Sozlamalar'];

  final _pages = const [
    DashboardScreen(),
    AttendanceScreen(),
    ArizaScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    _Dest(Icons.home_outlined, Icons.home_rounded, 'Bosh sahifa'),
    _Dest(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Davomat'),
    _Dest(Icons.description_outlined, Icons.description_rounded, 'Arizalar'),
    _Dest(Icons.settings_outlined, Icons.settings_rounded, 'Sozlamalar'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    final body = SafeArea(
      child: IndexedStack(index: _index, children: _pages),
    );

    if (wide) {
      final extended = context.isDesktop;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 200,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white),
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selected;
  final String label;
  const _Dest(this.icon, this.selected, this.label);
}
