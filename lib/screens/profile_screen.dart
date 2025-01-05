import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/api/api_service.dart'; // Pastikan jalur ini benar
import 'package:hrm/screens/signin_screen.dart';
import 'package:hrm/api/avatar_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? karyawanData;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _avatar;
  List<Map<String, dynamic>> jabatanList = [];
  String? _avatarUrl; // Menyimpan URL avatar
  AvatarService _avatarService = AvatarService(); // Instance AvatarService

  String getJabatanNama(int? jabatanId) {
    if (jabatanId == null || jabatanList.isEmpty) {
      return 'Jabatan tidak tersedia';
    }

    final jabatan = jabatanList.firstWhere(
      (j) => j['id'] == jabatanId,
      orElse: () => {'jabatan': 'Jabatan tidak tersedia'},
    );

    return jabatan['jabatan'];
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
    _fetchKaryawanData();
    _getAvatarFromService(); 
  }



 // Fungsi untuk mendapatkan avatar dari service
  Future<void> _getAvatarFromService() async {
    try {
      final avatarUrl = await _avatarService.getAvatarKaryawan();
      if (avatarUrl != null) {
        setState(() {
          _avatarUrl = avatarUrl;
        });
      }
    } catch (e) {
      // Tangani error jika tidak bisa mengambil avatar
      print("Error fetching avatar: $e");
      print("Avatar URL: $_avatarUrl");

    }
  }

  Future<void> _loadSavedAvatar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedAvatar = prefs.getString('avatar_path');

    if (savedAvatar != null) {
      setState(() {
        if (savedAvatar.startsWith('http')) {
          _avatar = null;
          karyawanData = {'avatar': savedAvatar};
        } else {
          _avatar = File(savedAvatar);
        }
      });
    }
  }

 Future<void> _uploadAvatar() async {
  // Mendapatkan token dari SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

  // Validasi apakah token tersedia
  if (token == null) {
    _showMessage('No token found', isError: true);
    return;
  }

  // Validasi apakah file avatar tersedia
  if (_avatar == null) {
    _showMessage('No image selected', isError: true);
    return;
  }

  try {
    // Mengirim request upload avatar
    final response = await ApiService.postMultipartRequest(
      'profile/avatar',
      _avatar!, // File avatar yang dipilih
      token,
    );

    // Mengonversi stream response ke bentuk respons biasa
    final responseBody = await http.Response.fromStream(response);

    

    // Memeriksa status kode respons
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(responseBody.body);

      // Validasi apakah server mengembalikan URL avatar yang valid
      if (responseData['avatar_url'] != null && responseData['avatar_url'] is String) {
        final String avatarUrl = responseData['avatar_url'];

        // Menyimpan URL avatar di SharedPreferences
        await prefs.setString('avatar_path', avatarUrl);

        // Menampilkan pesan sukses
        _showMessage('Avatar uploaded successfully');
        
        // Memuat ulang data karyawan terbaru
        _fetchKaryawanData();
      } else {
        _showMessage('Invalid avatar URL returned by server', isError: true);
      }
    } else {
      // Menampilkan pesan kesalahan dari server
      _showMessage('Failed to upload avatar: ${responseBody.body}', isError: true);
    }
  } catch (e) {
    // Menangani error umum
    _showMessage('Error uploading avatar: $e', isError: true);
  }
}

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('avatar_path', pickedFile.path);
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token == null) {
      _showMessage('No token found', isError: true);
      return;
    }

    try {
      final body = {'token': token};

      final response = await ApiService.postRequest('logout', {'Authorization': 'Bearer $token'}, body);

      if (response.statusCode == 200) {
        await prefs.remove('access_token'); 
        _showMessage('Logged out successfully');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          ),
        );
      } else {
        _showMessage('Failed to log out: ${response.body}', isError: true);
      }
    } catch (e) {
      _showMessage('Error logging out: $e', isError: true);
    }
  }

  Future<void> _fetchKaryawanData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token == null) {
      _showMessage('Token is missing', isError: true);
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await ApiService.getRequest('profile', headers);
      final jabatanResponse = await ApiService.getRequest('jabatan', headers);

      if (response.statusCode == 200 && jabatanResponse.statusCode == 200) {
        final profileData = json.decode(response.body)['profile'];
        final jabatanData = json.decode(jabatanResponse.body);

        setState(() {
          karyawanData = profileData;
          jabatanList = List<Map<String, dynamic>>.from(jabatanData);
          isLoading = false;
        });
      } else {
        _showMessage('Failed to fetch profile or jabatan data', isError: true);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error fetching data: $e', isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
  setState(() {
    isLoading = true;
  });
  await _fetchKaryawanData(); // Memuat ulang data karyawan
  await _getAvatarFromService(); // Memuat ulang URL avatar
  setState(() {
    isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showUpdateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : karyawanData != null
              ? RefreshIndicator(
                  onRefresh: _refreshProfile, // Tautkan dengan fungsi refresh
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                     Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Stack(
        clipBehavior: Clip.none, // Agar ikon kamera tidak terpotong
        alignment: Alignment.center,
        children: [
          // Avatar Circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4), // Bayangan di bawah
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!) // Menggunakan URL avatar dari API
                  
                  : (_avatar != null
                      ? FileImage(_avatar!) // Jika avatar lokal tersedia
                      : const AssetImage('assets/images/profile.png') 
                          as ImageProvider), // Default fallback image
            ),
          ),
          // Kamera Edit Icon
          Positioned(
            bottom: -15,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                await _pickImage(); // Buka galeri
                if (_avatar != null) {
                  await _uploadAvatar(); // Upload avatar ke server
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text(
        "Ketuk ikon kamera untuk mengubah avatar",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),

                        _buildContactInfo(), 
                      ],
                    ),
                  ),
                )
              : const Center(child: Text('Karyawan not found')),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.work, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                   
  'Jabatan: ${karyawanData?['nama_jabatan'] ?? 'Jabatan tidak tersedia'}',



                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.assignment_ind, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NIP: ${karyawanData?['nip'] ?? 'NIP tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.assignment_ind, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NIK: ${karyawanData?['nik'] ?? 'NIK tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Name: ${karyawanData?['nama_karyawan'] ?? 'Nama Karyawan tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email: ${karyawanData?['email'] ?? 'Email tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phone: ${karyawanData?['no_handphone'] ?? 'No telepon tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.home, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Address: ${karyawanData?['alamat'] ?? 'Alamat tidak tersedia'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _updateProfile(Map<String, String> updatedData) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');
  if (token == null) {
    _showMessage('Token is missing', isError: true);
    setState(() {
      isLoading = false;
    });
    return;
  }

  try {
    final response = await ApiService.putRequest('profile', updatedData, token);

    if (response.statusCode == 200) {
      _showMessage('Profile updated successfully');
      _fetchKaryawanData();
    } else {
      _showMessage('Failed to update profile', isError: true);
    }
  } catch (e) {
    _showMessage('Error updating profile: $e', isError: true);
  }
}

void _showUpdateDialog() {
  final nameController = TextEditingController(text: karyawanData?['nama_karyawan']);
  final emailController = TextEditingController(text: karyawanData?['email']);
  final phoneController = TextEditingController(text: karyawanData?['no_handphone']);
  final addressController = TextEditingController(text: karyawanData?['alamat']);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Update Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please update your information below:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final Map<String, String> updatedData = {
                'nama_karyawan': nameController.text,
                'email': emailController.text,
                'no_handphone': phoneController.text,
                'alamat': addressController.text,
              };
              _updateProfile(updatedData);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
