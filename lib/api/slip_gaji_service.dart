import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SlipGajiService {
  final String apiUrl = 'http://192.168.0.101:8000/api';

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

  // Fungsi untuk mendownload slip gaji
  Future<void> downloadSlipGaji(String idKaryawan) async {
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
        Uri.parse('$apiUrl/generate-slip-gaji?idKaryawan=$idKaryawan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      print('Content-Type: ${response.headers['content-type']}');
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Simpan file PDF jika respons berhasil
        await saveFile('slip_gaji_$idKaryawan.pdf', response.bodyBytes);
        print('Slip gaji berhasil didownload.');
      } else {
        throw Exception(
            'Gagal mendownload slip gaji. Kode: ${response.statusCode}, Pesan: ${response.body}');
      }
    } catch (e) {
      print('Error saat mendownload file: $e');
      throw Exception('Error saat mendownload file.');
    }
  }

  Future<void> saveFile(String filename, List<int> bytes) async {
    try {
      final directory = await getExternalStorageDirectory(); // Get the external storage directory
      final downloadsDirectory = Directory('${directory!.path}/Download'); // Path to the Downloads directory

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true); // Create the Downloads directory if it doesn't exist
      }

      final filePath = '${downloadsDirectory.path}/$filename';
      final file = File(filePath);

      await file.writeAsBytes(bytes);
      print('File berhasil disimpan di: $filePath');
    } catch (e) {
      print('Gagal menyimpan file: $e');
      throw Exception('Gagal menyimpan file.');
    }
  }

}
