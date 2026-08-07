import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';
import 'ariza_form_screen.dart';

class ArizaListScreen extends StatefulWidget {
  const ArizaListScreen({super.key});

  @override
  State<ArizaListScreen> createState() => _ArizaListScreenState();
}

class _ArizaListScreenState extends State<ArizaListScreen> {
  bool _loading = true;
  List<ArizaItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.arizaHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) _items = res.data ?? [];
    });
  }

  Future<void> _newAriza() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ArizaFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mening arizalarim'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilledButton.icon(
                      onPressed: _newAriza,
                      icon: const Icon(Icons.add),
                      label: const Text('Yangi ariza yuborish'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Arizalar yo\u2019q',
                          subtitle:
                              'Yuqoridagi tugma orqali birinchi arizangizni yuboring.',
                        ),
                      )
                    else
                      for (final a in _items) ...[
                        _card(context, a),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 16),
                  ],
                ),
      ),
    );
  }

  Widget _card(BuildContext context, ArizaItem a) {
    final scheme = Theme.of(context).colorScheme;
    final color = StatusChip.colorFor(a.statusKey);
    return AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_fmt(a.targetDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip(text: a.statusDisplay, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.cause,
              style: TextStyle(color: scheme.onSurface, height: 1.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.tag, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(a.arizaId,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
              if (a.schoolName != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.apartment,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(a.schoolName!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
