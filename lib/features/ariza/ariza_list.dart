import 'package:flutter/material.dart';
import 'ariza.dart'; // Make sure this imports your ArizaScreen

class ArizaListScreen extends StatefulWidget {
  const ArizaListScreen({super.key});

  @override
  State<ArizaListScreen> createState() => _ArizaListScreenState();
}

class _ArizaListScreenState extends State<ArizaListScreen> {
  // Demo data (later replace with real API data)
  List<Map<String, dynamic>> arizalar = [
    {
      "id": "ARZ-20260113-001",
      "date": "13.01.2026",
      "school": "17-sonli maktab",
      "reason": "Kasallik tufayli kela olmadim, shifokor ma'lumotnomasi ilova qilingan",
      "status": "pending",
      "submittedAt": "13.01.2026 09:45",
      "response": null,
    },
    {
      "id": "ARZ-20260110-002",
      "date": "10.01.2026",
      "school": "12-sonli maktab",
      "reason": "Texnik muammo (GPS ishlamadi)",
      "status": "approved",
      "submittedAt": "10.01.2026 18:12",
      "response": "Tasdiqlandi, qayd tuzatildi",
    },
    {
      "id": "ARZ-20260105-003",
      "date": "05.01.2026",
      "school": "17-sonli maktab",
      "reason": "Oilaviy vaziyat",
      "status": "rejected",
      "submittedAt": "05.01.2026 14:30",
      "response": "Sabab yetarli darajada asoslanmagan",
    },
    {
      "id": "ARZ-20251228-004",
      "date": "28.12.2025",
      "school": "5-sonli akademik litsey",
      "reason": "Transport muammosi",
      "status": "pending",
      "submittedAt": "28.12.2025 17:55",
      "response": null,
    },
  ];

  bool _isRefreshing = false;

  Future<void> _refreshList() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate network delay

    // Here you would normally call your API to fetch fresh data
    // For demo we just keep current data

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Ko‘rib chiqilmoqda";
      case "approved":
        return "Tasdiqlandi";
      case "rejected":
        return "Rad etildi";
      default:
        return "Noma'lum";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0617) : const Color(0xFFFAF8FF);
    final cardColor = isDark ? const Color(0xFF1C1430) : Colors.white;
    final textColor = isDark ? const Color(0xFFDFD4FF) : const Color(0xFF2A1845);
    final lavender = isDark ? const Color(0xFFCC99FF) : const Color(0xFFB794F4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Mening arizalarim",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        color: lavender,
        backgroundColor: cardColor,
        child: arizalar.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 90,
                color: lavender.withOpacity(0.35),
              ),
              const SizedBox(height: 24),
              Text(
                "Hozircha hech qanday ariza yuborilmagan",
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Yangi ariza yuborish uchun tugmani bosing",
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Yangi ariza yuborish"),
                style: FilledButton.styleFrom(
                  backgroundColor: lavender,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToNewAriza(),
              ),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            // Top button for quick access
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.add, size: 20),
                label: const Text("Yangi ariza yuborish"),
                style: FilledButton.styleFrom(
                  backgroundColor: lavender,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToNewAriza,
              ),
            ),

            ...arizalar.asMap().entries.map((entry) {
              final index = entry.key;
              final ariza = entry.value;
              final statusColor = _getStatusColor(ariza["status"]);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: cardColor,
                  elevation: isDark ? 0 : 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // TODO: Navigate to detailed ariza view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Ariza #${ariza["id"]} tafsilotlari"),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ariza["date"],
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(ariza["status"]),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ariza["school"],
                            style: TextStyle(
                              color: lavender,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ariza["reason"].length > 100
                                ? "${ariza["reason"].substring(0, 97)}..."
                                : ariza["reason"],
                            style: TextStyle(
                              color: textColor.withOpacity(0.85),
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Yuborilgan: ${ariza["submittedAt"]}",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "#${ariza["id"]}",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.45),
                                  fontSize: 12,
                                  fontFamily: "monospace",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: lavender,
        foregroundColor: Colors.white,
        onPressed: _navigateToNewAriza,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToNewAriza() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ArizaScreen(),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Here you would normally:
        // 1. Add new ariza to list (demo)
        // 2. Or refresh from API
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Yangi ariza yuborildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}