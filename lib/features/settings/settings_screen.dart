import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/storage.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ContentContainer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Profile header
            AppCard(
              child: Row(
                children: [
                  InitialsAvatar(initials: user?.initials ?? '?', size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Foydalanuvchi',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (user?.employeeId != null) user!.employeeId!,
                            if (user?.phone != null) user!.phone!,
                          ].join('  ·  '),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const SectionHeader('Ko\u2019rinish'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  _themeTile('Tizim bo\u2019yicha', ThemeMode.system,
                      Icons.brightness_auto),
                  _themeTile('Yorug\u2019', ThemeMode.light, Icons.light_mode),
                  _themeTile('Qorong\u2019u', ThemeMode.dark, Icons.dark_mode),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const SectionHeader('Server'),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Server manzili'),
                subtitle: FutureBuilder<String?>(
                  future: Storage.baseUrl,
                  builder: (_, snap) =>
                      Text(snap.data ?? ApiService.defaultBaseUrl),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editBaseUrl,
              ),
            ),
            const SizedBox(height: 20),

            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger.withOpacity(0.12),
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Chiqish'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('Keldim v2.0.0',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(String label, ThemeMode mode, IconData icon) {
    final current = AppState.instance.themeMode;
    final selected = current == mode;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppColors.brand : null),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.brand)
          : null,
      onTap: () => AppState.instance.setThemeMode(mode),
    );
  }

  Future<void> _editBaseUrl() async {
    final ctrl = TextEditingController(
        text: (await Storage.baseUrl) ?? ApiService.defaultBaseUrl);
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Server manzili'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://10.0.2.2:8000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await Storage.setBaseUrl(result);
      if (mounted) {
        setState(() {});
        showSnack(context, 'Saqlandi', color: AppColors.success);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Hisobdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\u2019q'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AppState.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
