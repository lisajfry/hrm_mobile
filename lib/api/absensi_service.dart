import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrm/model/absen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AbsensiService {
  final String baseUrl = 'http://192.168.200.40:8000/api';

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<LatLng> getOfficeLocation() async {
  final double latitude = -7.636870688302552;
  final double longitude = 111.54264772255189;

  final url = "https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json";

  final response = await http.get(
    Uri.parse(url),
    headers: {'User-Agent': 'hrm_mobile (liaaa.ty127@gmail.com)'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final address = data['display_name'] ?? 'Unknown location';

    print("Address: $address");

    return LatLng(latitude, longitude); // Tetap gunakan koordinat asli
  } else {
    throw Exception('Failed to fetch office location: ${response.statusCode}');
  }
}

  Future<List<Absensi>> getAbsensi() async {
    String? token = await getToken();
    print('Token yang digunakan: $token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/absensi'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      print('Response: ${response.body}');
      return jsonResponse.map((data) => Absensi.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.body}');
    }
  }


  Future<List<Absensi>> getAbsensiFilter({int? bulan, int? tahun}) async {
  String? token = await getToken();
  print('Token yang digunakan: $token');

  if (token == null) {
    throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
  }

  // Bangun URL dengan query parameter
  String url = '$baseUrl/absensi';
  if (bulan != null && tahun != null) {
    url = '$url?bulan=$bulan&tahun=$tahun';
  }

  final response = await http.get(
    Uri.parse(url), // Gunakan URL yang sudah dibangun
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    print('Response: ${response.body}');
    return jsonResponse.map((data) => Absensi.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load tasks: ${response.body}');
  }
}


  // Absen Masuk
  Future<Absensi> absenMasuk(Map<String, dynamic> data) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/absensi/masuk'), // gunakan endpoint yang benar
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'tanggal': data['tanggal'],
          'jam_masuk': data['jam_masuk'],
          'foto_masuk': data['foto_masuk'],
          'latitude_masuk': data['latitude_masuk'],
          'longitude_masuk': data['longitude_masuk'],
          'status': data['status'],
        }),
      );

      if (response.statusCode == 201) {
        return Absensi.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal melakukan absen masuk: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Absen Keluar
  Future<Absensi> absenKeluar(Map<String, dynamic> data) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    try {
      final response = await http.post(
                Uri.parse('$baseUrl/absensi/keluar'), // gunakan endpoint yang benar

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'tanggal': data['tanggal'],
          'jam_keluar': data['jam_keluar'],
          'foto_keluar': data['foto_keluar'],
          'latitude_keluar': data['latitude_keluar'],
          'longitude_keluar': data['longitude_keluar'],
          'status': data['status'],
        }),
      );

      if (response.statusCode == 201) {
        return Absensi.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal melakukan absen keluar: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

