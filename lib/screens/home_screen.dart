import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hrm/screens/absensi_screen.dart';
import 'package:hrm/screens/lembur_screen.dart';
import 'package:hrm/screens/profile_screen.dart';
import 'package:hrm/screens/izin_screen.dart';
import 'package:hrm/screens/rekap_absensi.dart';
import 'package:hrm/screens/dinas_luar_kota_screen.dart';
import 'package:hrm/screens/payroll_screen.dart';
import 'package:hrm/screens/task_screen.dart';
import 'package:hrm/screens/navigation.dart';
import 'package:flutter/services.dart'; // Tambahkan ini
import 'package:hrm/screens/barchart.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreenContent(),
    IzinScreen(),
    AbsensiScreen(),
    DinasLuarKotaScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        // Menampilkan dialog konfirmasi untuk keluar aplikasi
        bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Keluar'),
            content: const Text('Apakah Anda yakin ingin keluar aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya'),
              ),
            ],
          ),
        );
        // Jika pengguna memilih "Ya", keluar aplikasi
        if (shouldExit) {
          // Gunakan SystemNavigator.pop() untuk menutup aplikasi
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  final Map<String, Widget> layananRoutes = {
    'Lembur': LemburScreen(),
    'Payroll': PayrollScreen(),
    'Riwayat Absensi': RekapAbsensiScreen(),
    'Tasks': TaskScreen(),
  };

  Future<List<BarChartGroupData>> fetchChartData() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: Colors.green)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4, color: Colors.red)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 2, color: Colors.orange)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 6, color: Colors.purple)]),
    ];
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              items: [
                'assets/images/example1.png',
                'assets/images/example2.png',
                'assets/images/example3.png',
              ].map((path) {
                return Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50)),
                );
              }).toList(),
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: layananRoutes.keys.map((title) {
                    IconData icon;
                    switch (title) {
                      case 'Lembur':
                        icon = Icons.timer;
                        break;
                      case 'Payroll':
                        icon = Icons.attach_money;
                        break;
                      case 'Riwayat Absensi':
                        icon = Icons.description;
                        break;
                      case 'Tasks':
                        icon = Icons.task;
                        break;

                      default:
                        icon = Icons.help;
                    }
                    return _buildLayananItem(title, icon, context);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Ganti FutureBuilder dengan PayrollBarChart
            SizedBox(
              height: 300,
              child: PayrollBarChart(), // Widget baru yang memuat chart dinamis
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildLayananItem(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (layananRoutes.containsKey(title)) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => layananRoutes[title]!),
          );
        }
      },
      child: Column(
        children: [
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}