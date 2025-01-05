import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class PayrollService {
  final String _baseUrl = 'http://192.168.200.40:8000/api'; // Ganti dengan URL API Anda


/// Mengambil ringkasan payroll berdasarkan bulan dan tahun
  /// [bulan] dan [tahun] bersifat opsional, default ke bulan dan tahun saat ini.
  Future<Map<String, dynamic>?> fetchPayrollSummary({int? bulan, int? tahun}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
      }

      // Default ke bulan dan tahun saat ini jika tidak diberikan
      bulan ??= DateTime.now().month;
      tahun ??= DateTime.now().year;

      // Bangun URL dengan query parameter
      final url = Uri.parse('$_baseUrl/payroll-summary?month=$bulan&year=$tahun');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data == null || data.isEmpty) {
          return null; // Tidak ada data
        }

        return data; // Kembalikan data jika tersedia
      } else {
        throw Exception(
          'Gagal memuat ringkasan payroll. Kode: ${response.statusCode}, Pesan: ${response.body}',
        );
      }
    } catch (e) {
      // Log error untuk debugging
      print('Terjadi kesalahan: $e');
      throw Exception('Terjadi kesalahan saat memuat ringkasan payroll: $e');
    }
  }


  Future<Map<String, int>> fetchPayrollGrafik() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/payroll-summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Payroll Data: $data'); // Cek hasil response API
      

      // Memastikan data yang diterima dalam bentuk yang sesuai
      return {
  "Hadir": _parseInt(data["kehadiran_count"]),
  "Izin": _parseInt(data["izin_count"]),
  "Cuti": _parseInt(data["cuti_count"]),
  "Dinas": _parseInt(data["dinas_luar_kota_count"]),
  "Lembur": _parseToInt(data["lembur_count"]), // Pastikan double dikonversi ke int
};

    } else {
      throw Exception('Gagal memuat data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Terjadi kesalahan: $e');
  }
}

// Fungsi untuk mengonversi data menjadi integer atau 0 jika gagal
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// Fungsi untuk mengonversi data menjadi integer dari double atau 0 jika gagal
int _parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt(); // Mengonversi double ke int
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

}
