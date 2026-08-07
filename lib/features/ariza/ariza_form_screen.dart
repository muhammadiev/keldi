import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';

/// Full-page ariza (leave request) form. Can be pre-filled from the
/// history screen (initialDate / initialSchool).
class ArizaFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final SchoolRef? initialSchool;
  const ArizaFormScreen({super.key, this.initialDate, this.initialSchool});

  @override
  State<ArizaFormScreen> createState() => _ArizaFormScreenState();
}

class _ArizaFormScreenState extends State<ArizaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  late DateTime _date;
  SchoolRef? _school;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _school = widget.initialSchool;
  }

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
    final schools = AppState.instance.user?.schools ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi ariza'), centerTitle: true),
      body: ContentContainer(
        maxWidth: 560,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 4),
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
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Sabab',
                  alignLabelWithHint: true,
                  hintText: 'Nima uchun kela olmadingiz?',
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
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Yuborish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
