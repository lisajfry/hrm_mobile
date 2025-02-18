import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/model/task.dart';

class TaskService {
  final String apiUrl = 'http://192.168.200.40:8000/api';

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get Dinas Luar Kota with optional filters for month and year
  Future<List<Task>> getTask({int? bulan, int? tahun}) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    // Bangun URL dengan query parameter
  String url = '$apiUrl/tasks';
  if (bulan != null && tahun != null) {
    url = '$url?bulan=$bulan&tahun=$tahun';
  }

  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $token'},
  );

    print('Status Code: ${response.statusCode}');
    print('Respons Body: ${response.body}');

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Task.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat data dinas luar kota');
    }
  }

  Future<void> addTask(Task task) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'judul_proyek': task.judulProyek,
        'kegiatan': task.kegiatan,
        'tgl_mulai': task.tglMulai,
        'tgl_selesai': task.tglSelesai,
        'batas_penyelesaian': task.batasPenyelesaian,
        'status': task.status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add task: ${json.decode(response.body)['message'] ?? response.body}');
    }
  }

  Future<void> updateTask(Task task) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    final response = await http.put(
      Uri.parse('$apiUrl/tasks/${task.idTugas}'), // Mengganti id menjadi idTugas
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'judul_proyek': task.judulProyek,
        'kegiatan': task.kegiatan,
        'tgl_mulai': task.tglMulai,
        'tgl_selesai': task.tglSelesai,
        'batas_penyelesaian': task.batasPenyelesaian,
        'status': task.status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${json.decode(response.body)['message'] ?? response.body}');
    }
  }

  Future<void> deleteTask(int idTugas) async {  // Mengganti id menjadi idTugas
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Pastikan Anda sudah login.');
    }

    final response = await http.delete(
      Uri.parse('$apiUrl/tasks/$idTugas'),  // Mengganti id menjadi idTugas
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }
}
