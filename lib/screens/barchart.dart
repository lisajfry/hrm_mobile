import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hrm/api/payroll_service.dart';

class PayrollBarChart extends StatefulWidget {
  @override
  _PayrollBarChartState createState() => _PayrollBarChartState();
}

class _PayrollBarChartState extends State<PayrollBarChart> {
  final PayrollService payrollService = PayrollService();
  late Future<Map<String, int>> _payrollDataFuture;

  final List<Color> barColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  void _fetchPayrollData() {
    setState(() {
      _payrollDataFuture = payrollService.fetchPayrollGrafik();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
title: const Text(
  "Grafik Laporan Absensi Bulan Ini",
  style: TextStyle(
    fontSize: 16.0, // Atur ukuran font sesuai keinginan
    fontWeight: FontWeight.bold, // Opsional untuk memberikan penekanan
  ),
),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchPayrollData();
        },
        child: FutureBuilder<Map<String, int>>(
          future: _payrollDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              final categories = data.keys.toList();
              final values = data.values.toList();

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                children: [
                  SizedBox(
                    height: 350, // Menambah tinggi untuk menghindari navbar
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: values.reduce((a, b) => a > b ? a : b).toDouble() + 3,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                // Hanya tampilkan kelipatan 3
                                if (value % 1 == 0) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30, // Memberikan ruang lebih untuk label
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < categories.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      categories[value.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (value) {
                            if (value % 3 == 0) {
                              return FlLine(color: Colors.grey, strokeWidth: 0.5);
                            }
                            return FlLine(color: Colors.transparent);
                          },
                        ),
                        barGroups: values.asMap().entries.map((entry) {
                          final colorIndex = entry.key % barColors.length;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: barColors[colorIndex],
                                width: 12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('Tidak ada data untuk ditampilkan.'));
            }
          },
        ),
      ),
    );
  }
}