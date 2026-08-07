import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';

class ArizaScreen extends StatefulWidget {
  const ArizaScreen({super.key});

  @override
  State<ArizaScreen> createState() => _ArizaScreenState();
}

class _ArizaScreenState extends State<ArizaScreen> {
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

  Future<void> _openForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ArizaFormSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Arizalar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yangi ariza'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Arizalar yo\u2019q',
                      subtitle: 'Pastdagi tugma orqali yangi ariza yuboring.',
                    ),
                  ])
                : ContentContainer(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _card(context, _items[i]),
                    ),
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
              Expanded(
                child: Text(a.arizaId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              StatusChip(text: a.statusDisplay, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.cause,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Sana: ${_fmt(a.targetDate)}',
                  style: TextStyle(
                      fontSize: 12.5, color: scheme.onSurfaceVariant)),
              if (a.schoolName != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.apartment, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(a.schoolName!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: scheme.onSurfaceVariant)),
                ),
              ],
            ],
          ),
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

/// Bottom-sheet form to submit a new ariza.
class _ArizaFormSheet extends StatefulWidget {
  const _ArizaFormSheet();

  @override
  State<_ArizaFormSheet> createState() => _ArizaFormSheetState();
}

class _ArizaFormSheetState extends State<_ArizaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  SchoolRef? _school;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final res = await ApiService.submitAriza(
      targetDate: DateFormat('yyyy-MM-dd').format(_date),
      reason: _reasonCtrl.text.trim(),
      schoolId: _school?.id,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.ok) {
      showSnack(context, res.message, color: AppColors.success);
      Navigator.of(context).pop(true);
    } else {
      showSnack(context, res.message, color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final schools = AppState.instance.user?.schools ?? const [];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Yangi ariza',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sana',
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(DateFormat('dd.MM.yyyy').format(_date)),
                  ),
                ),
                const SizedBox(height: 16),

                // School (optional)
                if (schools.isNotEmpty) ...[
                  DropdownButtonFormField<SchoolRef>(
                    value: _school,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Maktab (ixtiyoriy)',
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    items: [
                      for (final s in schools)
                        DropdownMenuItem(value: s, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _school = v),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reason
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Sabab',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.edit_note),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Sababni batafsil yozing'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Yuborish'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
