import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/api/api_service.dart';
import 'package:intl/intl.dart';
import 'package:hrm/screens/face_recognition_screen.dart'; // Import yang benar
import 'package:hrm/api/absensi_service.dart'; // Import yang benar
import 'package:hrm/model/absen.dart'; // Import yang benar
import 'package:hrm/widgets/widgets.dart';
import 'dart:typed_data';

class RekapAbsensiScreen extends StatefulWidget {
  const RekapAbsensiScreen({Key? key}) : super(key: key); // Tambahkan parameter `key`

  @override
  _RekapAbsensiScreenState createState() => _RekapAbsensiScreenState();
}

class _RekapAbsensiScreenState  extends State<RekapAbsensiScreen> {
  Map<String, dynamic>? karyawanData;
  bool isLoading = true;
  late DateTime currentDateTime;
  List<Absensi> riwayatAbsensi = [];
  final AbsensiService absensiService = AbsensiService();


  @override
  void initState() {
    super.initState();
    currentDateTime = DateTime.now();
    fetchRiwayatAbsensi(); // Panggil fungsi untuk mengambil riwayat absensi
  }

  Future<void> fetchRiwayatAbsensi() async {
  setState(() {
    isLoading = true;
  });

  try {
    List<Absensi> absensi = await absensiService.getAbsensi();
    setState(() {
      riwayatAbsensi = absensi;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    _showMessage('Error fetching attendance history: $e', isError: true);
  }
}


  // Menampilkan pesan menggunakan snackbar
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Expanded(child: buildRiwayatAbsensiList()),
                  ],
                ),
              ),
            ),
    );
  }

// Fungsi untuk memuat ulang data absensi dan karyawan
Future<void> _refreshData() async {
  setState(() {
    isLoading = true;
  });

  await Future.wait([
    fetchRiwayatAbsensi(), // Memuat ulang riwayat absensi
  ]);

  setState(() {
    isLoading = false;
  });
}


    
  Widget buildRiwayatAbsensiList() {
  if (riwayatAbsensi.isEmpty) {
    return Center(
      child: Text(
        'Tidak ada data absensi.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  return ListView.builder(
    itemCount: riwayatAbsensi.length,
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    itemBuilder: (context, index) {
      final absensi = riwayatAbsensi.reversed.toList()[index];  // Membalikkan urutan data
      Uint8List? imageBytesMasuk = _decodeBase64(absensi.fotoMasuk);
      Uint8List? imageBytesKeluar = _decodeBase64(absensi.fotoKeluar);

      return GestureDetector(
        onTap: () => _showAbsensiDetail(context, absensi, imageBytesMasuk, imageBytesKeluar),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildImageWidget(imageBytesMasuk, 'Foto'),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absensi.tanggal ?? '-',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Text('Masuk: ${absensi.jamMasuk ?? '-'}',
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 16, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Text('Keluar: ${absensi.jamKeluar ?? '-'}',
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    },
  );
}


Widget _buildDetailItem(String title, String value) {
  return Align(
    alignment: Alignment.center, // Pusatkan widget secara keseluruhan
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey, // Warna abu-abu untuk title
          ),
        ),
        Text(value),
      ],
    ),
  );
}


    void _showAbsensiDetail(
  BuildContext context,
  Absensi absensi,
  Uint8List? imageMasuk,
  Uint8List? imageKeluar,
) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title of the modal
              Text(
                'Detail Absensi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              Divider(thickness: 1.0),
              const SizedBox(height: 16.0),

              // Grid displaying Absensi details
              GridView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 3,
                ),
                children: [
                  _buildDetailItem('Tanggal', absensi.tanggal ?? '-'),
                  _buildDetailItem('Jam Masuk', absensi.jamMasuk ?? '-'),
                  _buildDetailItem('Jam Keluar', absensi.jamKeluar ?? '-'),
                  _buildDetailItem('Status', absensi.status ?? '-'),
                  
                ],
              ),
              const SizedBox(height: 16.0),

              // Jika gambar tersedia, tampilkan thumbnail
if (imageMasuk != null || imageKeluar != null)
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      if (imageMasuk != null)
        GestureDetector(
          onTap: () {
            _showFullImage(context, imageMasuk, 'Foto Masuk');
          },
          child: _buildImageThumbnail(imageMasuk, 'Foto Masuk'), // Menampilkan title saja
        ),
      if (imageKeluar != null)
        GestureDetector(
          onTap: () {
            _showFullImage(context, imageKeluar, 'Foto Keluar');
          },
          child: _buildImageThumbnail(imageKeluar, 'Foto Keluar'), // Menampilkan title saja
        ),
    ],
  ),

            ],
          ),
        ),
      );
    },
  );
}




Widget _buildImageThumbnail(Uint8List image, String title) {
  return Column(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey, // Warna abu-abu untuk title
        ),
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          // Gambar Thumbnail
          Image.memory(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          // Ikon Zoom untuk memberi tanda bahwa gambar bisa diperbesar
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ],
  );
}


void _showFullImage(BuildContext context, Uint8List image, String title) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Image.memory(image, fit: BoxFit.contain),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup'),
          ),
        ],
      );
    },
  );
}

Uint8List? _decodeBase64(String? base64String) {
  if (base64String != null && base64String.isNotEmpty) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }
  return null;
}

    

Widget _buildImageWidget(Uint8List? imageBytes, String altText) {
  return imageBytes != null
      ? ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            imageBytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        )
      : Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              altText,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
        );
}

}