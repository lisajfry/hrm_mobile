import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:hrm/screens/absensi_screen.dart';
import 'package:hrm/screens/lembur_screen.dart';
import 'package:hrm/screens/profile_screen.dart';
import 'package:hrm/screens/izin_screen.dart';
import 'package:hrm/screens/rekap_absensi.dart';
import 'package:hrm/screens/dinas_luar_kota_screen.dart';
import 'package:hrm/screens/payroll_screen.dart';
import 'package:hrm/screens/task_screen.dart';
import 'package:hrm/screens/navigation.dart';
import 'package:flutter/services.dart';
import 'package:hrm/screens/barchart.dart'; // Tetap menggunakan BarChart dari file ini

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
        if (shouldExit) {
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

class HomeScreenContent extends StatefulWidget {
  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<void> _chartRefreshFuture;

  @override
  void initState() {
    super.initState();
    _chartRefreshFuture = Future.value(); // Inisialisasi agar tidak error
  }

  Future<void> _refreshData() async {
    setState(() {
      _chartRefreshFuture = Future.delayed(const Duration(seconds: 1)); // Simulasi waktu refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      children: [
                        _buildLayananItem('Lembur', Icons.timer, context),
                        _buildLayananItem('Payroll', Icons.attach_money, context),
                        _buildLayananItem('Riwayat Absensi', Icons.description, context),
                        _buildLayananItem('Tasks', Icons.task, context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<void>(
                  future: _chartRefreshFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return SizedBox(
                        height: 300,
                        child: PayrollBarChart(), // Tetap menggunakan widget PayrollBarChart
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayananItem(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        
      // Navigasi ke halaman sesuai
      switch (title) {
        case 'Lembur':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LemburScreen()),
          );
          break;
        case 'Payroll':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PayrollScreen()),
          );
          break;
        case 'Riwayat Absensi':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RekapAbsensiScreen()),
          );
          break;
        case 'Tasks':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskScreen()),
          );
          break;
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
