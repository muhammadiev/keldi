import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../ariza/ariza.dart'; // ← add to pubspec.yaml: fl_chart: ^0.68.0

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F081A) : const Color(0xFFFAF9FF);
    final cardColor = isDark ? const Color(0xFF1A1428) : Colors.white;
    final textColor = isDark ? const Color(0xFFE0D4FF) : const Color(0xFF2D1B47);
    final lavender = isDark ? const Color(0xFFD0A8FF) : const Color(0xFFC9A0DC);
    final accentGreen = isDark ? const Color(0xFF39FF14) : Colors.green.shade600;
    final accentRed = isDark ? const Color(0xFFFF3366) : Colors.redAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Tarix",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chart section - top 35%
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: isDark ? 0 : 2,
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Oxirgi 7 kun ish vaqti",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Du', 'Se', 'Chor', 'Pa', 'Ju', 'Sha', 'Yak'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Text(
                                      days[value.toInt()],
                                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()} soat',
                                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 7.8),
                                FlSpot(1, 8.2),
                                FlSpot(2, 7.1),
                                FlSpot(3, 8.5),
                                FlSpot(4, 6.9),
                                FlSpot(5, 0),
                                FlSpot(6, 0),
                              ],
                              isCurved: true,
                              color: accentGreen,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: accentGreen.withOpacity(0.15),
                              ),
                            ),
                          ],
                          minY: 0,
                          maxY: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // List of attendance records
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 12, // demo data
              itemBuilder: (context, index) {
                final date = DateTime(2026, 1, 13 - index);
                final dayName = ['Yak', 'Du', 'Se', 'Chor', 'Pa', 'Ju', 'Sha'][date.weekday % 7];

                // Demo logic for different states
                final hasFullRecord = index % 4 != 0;
                final hasKeldi = index % 5 != 2;
                final hasKetdi = hasFullRecord && index % 3 != 1;
                final hours = hasFullRecord ? (7 + (index % 3)).toDouble() : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: isDark ? 0 : 1,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Date column
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: lavender.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  date.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: lavender,
                                  ),
                                ),
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Main info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "17-sonli maktab",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (hasKeldi) ...[
                                      Icon(Icons.login, size: 16, color: accentGreen),
                                      const SizedBox(width: 4),
                                      Text("08:17", style: TextStyle(color: textColor)),
                                    ],
                                    if (hasKeldi && hasKetdi) const SizedBox(width: 16),
                                    if (hasKetdi) ...[
                                      Icon(Icons.logout, size: 16, color: accentRed),
                                      const SizedBox(width: 4),
                                      Text("16:45", style: TextStyle(color: textColor)),
                                    ],
                                  ],
                                ),
                                if (hours != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "$hours soat ${((hours % 1) * 60).toInt()} daqiqa",
                                    style: TextStyle(
                                      color: accentGreen,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Ariza button (only if incomplete)
                          if (!hasFullRecord || !hasKetdi)
                            OutlinedButton(
                              onPressed: () {

                                final safeDate = date ?? DateTime.now(); // fallback
                                // final safeSchool = schoolName?.isNotEmpty == true
                                //     ? schoolName
                                //     : (schools.isNotEmpty ? schools.first : null);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArizaScreen(
                                      initialDate: safeDate,
                                      initialSchool: "29-sonli maktab",
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accentRed),
                                foregroundColor: accentRed,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Ariza", style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}