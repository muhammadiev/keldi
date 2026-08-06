import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Demo data for UI only
  final List<String> users = [
    "Azizbek Yusupov (o'qituvchi)",
    "Shaxzoda Karimova (o'qituvchi)",
    "Jahongir Rahimov (o'qituvchi)",
    "Admin User",
  ];

  DateTimeRange? selectedRange;
  final List<String> selectedUsers = [];

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
          "Admin Paneli",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
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
                        "Xush kelibsiz, Admin!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Bugun 13-yanvar 2026-yil",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 1. Hisobotlar section
              Card(
                color: cardColor,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: accent, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "Hisobotlar",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date range picker
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          selectedRange == null
                              ? "Sana oralig'ini tanlang"
                              : "${selectedRange!.start.day}.${selectedRange!.start.month} - ${selectedRange!.end.day}.${selectedRange!.end.month}.${selectedRange!.end.year}",
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: lavender),
                          foregroundColor: textColor,
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now(),
                            initialDateRange: selectedRange,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.fromSeed(seedColor: lavender),
                              ),
                              child: child!,
                            ),
                          );
                          if (range != null) {
                            setState(() => selectedRange = range);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Users multi-select
                      OutlinedButton.icon(
                        icon: const Icon(Icons.people),
                        label: Text(
                          selectedUsers.isEmpty
                              ? "Xodimlarni tanlang"
                              : "${selectedUsers.length} ta xodim tanlandi",
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: lavender),
                          foregroundColor: textColor,
                        ),
                        onPressed: () {
                          // Simple dialog for demo (later can be better picker)
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Xodimlarni tanlang"),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    final isSelected = selectedUsers.contains(user);
                                    return CheckboxListTile(
                                      title: Text(user),
                                      value: isSelected,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            selectedUsers.add(user);
                                          } else {
                                            selectedUsers.remove(user);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Yopish"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Download button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text("Hisobotni yuklab olish (Excel)"),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: real excel generation & download later
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Hisobot yuklanmoqda... (demo)"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Foydalanuvchilar section
              Card(
                color: cardColor,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_alt_rounded, color: accent, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "Foydalanuvchilar",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6, // demo count
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final names = [
                            "Azizbek Yusupov",
                            "Shaxzoda Karimova",
                            "Jahongir Rahimov",
                            "Dilnoza Sobirova",
                            "Admin User",
                            "Sardor To‘xtayev",
                          ];
                          final roles = [
                            "O'qituvchi",
                            "O'qituvchi",
                            "O'qituvchi",
                            "O'qituvchi",
                            "Admin",
                            "O'qituvchi",
                          ];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: lavender.withOpacity(0.2),
                              child: Text(
                                names[index][0],
                                style: TextStyle(color: lavender),
                              ),
                            ),
                            title: Text(names[index], style: TextStyle(color: textColor)),
                            subtitle: Text(
                              roles[index],
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    // TODO: edit dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Tahrirlash oynasi (demo)")),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    // TODO: delete confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("O'chirildi (demo)")),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}