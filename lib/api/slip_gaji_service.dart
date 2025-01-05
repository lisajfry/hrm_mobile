import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SlipGajiService {
  final String apiUrl = 'http://192.168.200.40:8000/api'; // Pastikan URL API sesuai

  // Fungsi untuk meminta izin penyimpanan
  Future<bool> requestPermission() async {
    final permission = await Permission.storage.request(); 
    if (permission.isGranted) {
      print("Izin penyimpanan diberikan.");
      return true;
    } else {
      print("Izin penyimpanan ditolak.");
      return false;
    }
  }

  // Fungsi untuk mengambil token
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Fungsi untuk mengambil nama karyawan
  Future<String?> getNamaKaryawan() async {
    try {
      String? token = await getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
      }

      // Panggil endpoint API untuk mendapatkan data pengguna
      final response = await http.get(
        Uri.parse('$apiUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Periksa apakah data memiliki nama karyawan
        if (data['nama_karyawan'] != null) {
          return data['nama_karyawan'];
        } else {
          throw Exception('Nama karyawan tidak ditemukan dalam respons API.');
        }
      } else {
        throw Exception('Gagal mendapatkan data pengguna: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Gagal memuat nama karyawan: $e');
    }
  }

  // Fungsi untuk mendownload slip gaji dan mengembalikan path lokasi file
Future<String> downloadSlipGaji(String filename, int month, int year) async {
  String? token = await getToken();

  if (token == null) {
    throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
  }

  // Periksa izin penyimpanan
  bool permissionGranted = await requestPermission();
  if (!permissionGranted) {
    throw Exception('Akses penyimpanan diperlukan untuk mendownload file.');
  }

  try {
    final response = await http.get(
      Uri.parse('$apiUrl/generate-slip-gaji?month=$month&year=$year'), // Menambahkan month dan year sebagai query params
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf',
      },
    );

    if (response.statusCode == 200) {
      // Cek apakah file sudah ada dan tambahkan angka berturut-turut jika perlu
      int counter = 1;
      String originalFilename = filename;
      while (await fileExists(filename)) {
        filename = originalFilename.replaceAll('.pdf', '($counter).pdf');
        counter++;
      }

      String filePath = await saveFile(filename, response.bodyBytes);
      print('Slip gaji berhasil didownload: $filename');
      return filePath;
    } else {
      throw Exception(
          'Gagal mendownload slip gaji. Kode: ${response.statusCode}, Pesan: ${response.body}');
    }
  } catch (e) {
    print('Error saat mendownload file: $e');
    throw Exception('Error saat mendownload file.');
  }
}

// Fungsi untuk mengecek apakah file sudah ada
Future<bool> fileExists(String filename) async {
  try {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('Direktori penyimpanan tidak ditemukan.');
    }

    final downloadsDirectory = Directory('${directory.path}/Download');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    final filePath = '${downloadsDirectory.path}/$filename';
    final file = File(filePath);
    return await file.exists();
  } catch (e) {
    print('Error saat memeriksa file: $e');
    return false;
  }
}

// Fungsi untuk menyimpan file dan mengembalikan path lokasi file
Future<String> saveFile(String filename, List<int> bytes) async {
  try {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('Direktori penyimpanan tidak ditemukan.');
    }

    final downloadsDirectory = Directory('${directory.path}/Download');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    final filePath = '${downloadsDirectory.path}/$filename';
    final file = File(filePath);

    await file.writeAsBytes(bytes);
    print('File berhasil disimpan di: $filePath');

    return filePath; // Mengembalikan path lokasi file
  } catch (e) {
    print('Gagal menyimpan file: $e');
    throw Exception('Gagal menyimpan file.');
  }
}
}
