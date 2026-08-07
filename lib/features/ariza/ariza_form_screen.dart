import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _attachmentPath;

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

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galereya'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (picked != null) setState(() => _attachmentPath = picked.path);
    } catch (e) {
      if (mounted) showSnack(context, 'Rasm tanlanmadi: $e', color: AppColors.warning);
    }
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
      attachmentPath: _attachmentPath,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),

              // Attachment (proof) — optional
              Text('Dalil (ixtiyoriy)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              if (_attachmentPath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_attachmentPath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _attachmentPath = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Rasm biriktirish'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
    );
  }
}
