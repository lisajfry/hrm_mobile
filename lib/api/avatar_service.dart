import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  final String apiUrl = 'http://192.168.200.40:8000/api'; // Ganti dengan URL backend Anda

  // Fetch token from SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Fungsi untuk mengambil avatar karyawan
  Future<String?> getAvatarKaryawan() async {
    try {
      String? token = await getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
      }

      // Panggil endpoint API untuk mendapatkan data pengguna
      final response = await http.get(
        Uri.parse('$apiUrl/profile'), // Sesuaikan dengan endpoint backend
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);


print(data);  // Menampilkan respons API



        // Mengambil URL avatar dari data profile
        if (data['profile'] != null && data['profile']['avatar_url'] != null) {
            print(data['profile']['avatar_url']);  // Menampilkan URL avatar

          return data['profile']['avatar_url'];
        } else {
          throw Exception('Avatar karyawan tidak ditemukan dalam respons API.');
        }
      } else {
        throw Exception('Gagal mendapatkan data pengguna: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Gagal memuat avatar karyawan: $e');
    }

    
  }

  // Fungsi untuk mengonversi URL menjadi gambar
  static ImageProvider getAvatarImage(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    } else {
      return const AssetImage('assets/images/profile.png');
    }
  }
}
