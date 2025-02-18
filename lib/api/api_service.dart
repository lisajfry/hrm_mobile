import 'dart:convert';
import 'dart:io'; // For file handling
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  // Base URL of your API server
  static const String _baseUrl = 'http://192.168.200.40:8000/api/';

  static String get baseUrl => _baseUrl;

  // Fungsi POST request
  static Future<http.Response> postRequest(String endpoint, Map<String, String> headers, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(baseUrl + endpoint),
      headers: headers, // Pastikan header ini dalam bentuk Map<String, String>
      body: json.encode(body), // Body di-encode dalam JSON
    );
    return response;
  }

  // Fungsi GET request
  static Future<http.Response> getRequest(String endpoint, Map<String, String> headers) async {
    final response = await http.get(
      Uri.parse(baseUrl + endpoint),
      headers: headers, // Pastikan header ini juga dalam bentuk Map<String, String>
    );
    return response;
  }


  // PUT Request
  static Future<http.Response> putRequest(String endpoint, Map<String, dynamic> data, String token) async {
    final url = Uri.parse(_baseUrl + endpoint);
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data), // Pastikan data di-encode menjadi JSON
    );
    return response;
  }

static Future<http.StreamedResponse> postMultipartRequest(
      String endpoint, File file, String token) async {
    var url = Uri.parse(_baseUrl + endpoint);

    // Membuat multipart request
    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'; // Tambahkan header otorisasi

    // Melampirkan file ke request (field 'avatar' disesuaikan dengan API Anda)
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    

    // Mengirim request dan mengembalikan response
    return await request.send();


      
  }



  
  
  
  }