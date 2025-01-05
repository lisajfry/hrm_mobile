import 'package:flutter/material.dart';
import 'package:hrm/screens/signin_screen.dart';
import 'package:hrm/screens/home_screen.dart'; // Import HomeScreen
import 'package:shared_preferences/shared_preferences.dart'; // Untuk token handling
import 'package:hrm/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart'; // Untuk mendapatkan informasi aplikasi

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _appVersion = ''; // Tambahkan variabel untuk menyimpan versi aplikasi

  @override
  void initState() {
    super.initState();
    _getAppVersion(); // Panggil fungsi untuk mendapatkan versi aplikasi
    _navigateToNextScreen();
  }

  // Fungsi untuk mendapatkan versi aplikasi
  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version: ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate a loading delay
    await Future.delayed(const Duration(seconds: 3));

    // Check token in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      // Lakukan pengecekan ke server untuk memverifikasi token
      bool isTokenValid = await _verifyToken(token);

      if (isTokenValid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Jika token tidak valid, hapus token dan arahkan ke SignInScreen
        prefs.remove('access_token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    } else {
      // Jika tidak ada token, arahkan ke SignInScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  // Fungsi untuk memverifikasi token dengan server
  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.40:8000/api/verify-token'), // Endpoint API untuk verifikasi token
        headers: {
          'Authorization': 'Bearer $token', // Kirim token di header
        },
      );

      if (response.statusCode == 200) {
        // Token valid, kembalikan true
        return true;
      } else {
        // Token tidak valid atau sudah dihapus, kembalikan false
        return false;
      }
    } catch (e) {
      // Jika terjadi error saat pengecekan (misalnya jaringan error)
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/images/bg.png'), // Replace with your asset
              width: 400,
              height: 200,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // Loading indicator
            const SizedBox(height: 20),
            Text(
              _appVersion, // Menampilkan versi aplikasi
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
