import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Demo user data (later from provider / api)
  String firstName = "Azizbek";
  String lastName = "Yusupov";
  String phone = "+998 99 123 45 67";

  // Demo schools with active status
  final List<Map<String, dynamic>> schools = [
    {"name": "17-sonli maktab", "active": true},
    {"name": "12-sonli maktab", "active": false},
    {"name": "5-sonli akademik litsey", "active": true},
  ];

  bool darkMode = false; // will sync with system later

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
          "Sozlamalar",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Profile section
          Card(
            color: cardColor,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Shaxsiy ma'lumotlar",
                    style: TextStyle(
                      color: lavender,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _EditableField(
                    label: "Ism",
                    value: firstName,
                    onChanged: (v) => setState(() => firstName = v),
                  ),
                  const Divider(height: 32),

                  _EditableField(
                    label: "Familiya",
                    value: lastName,
                    onChanged: (v) => setState(() => lastName = v),
                  ),
                  const Divider(height: 32),

                  _EditableField(
                    label: "Telefon raqam",
                    value: phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => setState(() => phone = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active schools
          Card(
            color: cardColor,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Faol maktablar",
                    style: TextStyle(
                      color: lavender,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...schools.map((school) {
                    return SwitchListTile(
                      title: Text(
                        school["name"],
                        style: TextStyle(color: textColor),
                      ),
                      value: school["active"],
                      activeColor: accent,
                      onChanged: (bool value) {
                        setState(() {
                          school["active"] = value;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Appearance & other settings
          Card(
            color: cardColor,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text("Qorong'i rejim", style: TextStyle(color: textColor)),
                  subtitle: Text(
                    "Tizim sozlamalariga moslash",
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                  value: darkMode,
                  activeColor: accent,
                  onChanged: (value) {
                    setState(() => darkMode = value);
                    // Later: change theme mode globally
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline, color: lavender),
                  title: Text("Ilova haqida", style: TextStyle(color: textColor)),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "Keldim / Ketdim",
                      applicationVersion: "1.0.0",
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text("Davlat xizmatlari uchun qatnashuvni qayd etish tizimi"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Danger zone
          Card(
            color: cardColor,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text("Chiqish", style: TextStyle(color: Colors.orange)),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // or remove specific keys
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text("Hisobni o'chirish", style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    // Show confirmation dialog in real app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Hisob o'chirish jarayoni boshlandi..."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final TextInputType? keyboardType;

  const _EditableField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }
}