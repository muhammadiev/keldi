import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for better date formatting (uz locale already initialized in main)

class ArizaScreen extends StatefulWidget {
  const ArizaScreen({
    super.key,
    this.initialDate,     // optional: prefill from history
    this.initialSchool,   // optional: prefill from history
  });

  final DateTime? initialDate;
  final String? initialSchool;

  @override
  State<ArizaScreen> createState() => _ArizaScreenState();
}

class _ArizaScreenState extends State<ArizaScreen> {
  late DateTime selectedDate;
  String? selectedSchool;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  // Demo schools – later load from user profile / provider / API
  final List<String> schools = [
    "17-sonli maktab",
    "12-sonli maktab",
    "5-sonli akademik litsey",
    "1-sonli maktab",
    "29-sonli maktab",
  ];

  @override
  void initState() {
    super.initState();

    // Priority: use prefilled values from history → else today/first school
    selectedDate = widget.initialDate ?? DateTime.now();
    selectedSchool = widget.initialSchool ?? schools.first;
  }

  // Nice formatted date for display (Uzbek style)
  String get dateFormatted {
    final formatter = DateFormat('dd.MM.yyyy', 'uz');
    return formatter.format(selectedDate);
  }

  // Open date picker – user can always change date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),           // reasonable min date
      lastDate: DateTime.now().add(const Duration(days: 30)), // allow future if needed
      helpText: "Tuzatiladigan sanani tanlang",
      confirmText: "Tanlash",
      cancelText: "Bekor qilish",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB794F4), // lavender theme
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _submitAriza() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos, sababni kiriting")),
      );
      return;
    }

    if (selectedSchool == null || selectedSchool!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maktab tanlanmagan")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate API
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ariza muvaffaqiyatli yuborildi!"),
        backgroundColor: Colors.green,
      ),
    );

    // Return success to previous screen (list) so it can refresh
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0617) : const Color(0xFFFAF8FF);
    final cardColor = isDark ? const Color(0xFF1C1430) : Colors.white;
    final textColor = isDark ? const Color(0xFFDFD4FF) : const Color(0xFF2A1845);
    final lavender = isDark ? const Color(0xFFCC99FF) : const Color(0xFFB794F4);
    final accent = isDark ? const Color(0xFF39FF14) : Colors.green.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Ariza yuborish",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editable info card
              Card(
                color: cardColor,
                elevation: isDark ? 0 : 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tuzatiladigan ma'lumot",
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Changeable DATE
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: lavender),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Sana: $dateFormatted",
                                  style: TextStyle(color: textColor, fontSize: 16),
                                ),
                              ),
                              Icon(Icons.edit_calendar, size: 20, color: lavender.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 32),

                      // Changeable SCHOOL (dropdown)
                      DropdownButtonFormField<String>(
                        value: selectedSchool,
                        decoration: InputDecoration(
                          labelText: "Maktab",
                          labelStyle: TextStyle(color: lavender),
                          prefixIcon: Icon(Icons.school, color: lavender),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF140F20) : const Color(0xFFF8F5FF),
                        ),
                        items: schools.map((school) {
                          return DropdownMenuItem<String>(
                            value: school,
                            child: Text(school),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedSchool = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reason field
              Text(
                "Sabab *",
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 5,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: "Masalan: Kasal bo'lib qoldim, shu sababli kela olmadim...",
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF140F20) : const Color(0xFFF8F5FF),
                ),
                style: TextStyle(color: textColor),
              ),

              const SizedBox(height: 32),

              // Attachment area (placeholder – later add image_picker)
              Text(
                "Ilova (ixtiyoriy)",
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lavender.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: lavender, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Dalil sifatida rasm, PDF yoki hujjat qo'shishingiz mumkin",
                        style: TextStyle(color: textColor.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitAriza,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text(
                    "Ariza yuborish",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  "Ariza ko'rib chiqilgandan so'ng sizga xabar beriladi",
                  style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}