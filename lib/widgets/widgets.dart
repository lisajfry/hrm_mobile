import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrm/screens/face_recognition_screen.dart'; 
import 'package:hrm/utils/utils.dart'; 
import 'dart:io'; 
import 'package:hrm/screens/lembur_screen.dart'; 
import 'package:hrm/model/TotalLembur.dart'; 
import 'package:provider/provider.dart';


// Fungsi untuk membangun bagian profil
Widget buildProfileSection(Map<String, dynamic> karyawanData, DateTime currentDateTime) {
  return Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundImage: karyawanData['avatar'] != null && karyawanData['avatar'].isNotEmpty
            ? NetworkImage(karyawanData['avatar'])
            : AssetImage('assets/profile.jpg') as ImageProvider,
      ),
      SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(karyawanData['nama_karyawan'] ?? 'Nama tidak tersedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(getFormattedDateTime(currentDateTime)),
          ],
        ),
      ),
    ],
  );
}

// Fungsi untuk membangun segmentasi absensi
Widget buildAttendanceSegment() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Expanded(
        child: Column(
          children: [
            Text('Absen Masuk'),
          ],
        ),
      ),
      Expanded(
        child: Column(
          children: [
            Text('Absen Keluar'),
          ],
        ),
      ),
    ],
  );
}



// Fungsi untuk membangun kartu informasi
Widget _buildInfoCard(String title, String count, IconData icon, Color iconColor, BuildContext context) {
  return GestureDetector(
    onTap: () {
      if (title == 'Total Lembur') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LemburScreen()), // Navigasi ke LemburScreen
        );
      }
    },
    child: Column(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
