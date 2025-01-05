import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/api/api_service.dart';
import 'package:hrm/api/absensi_service.dart';
import 'package:hrm/model/absen.dart';
import 'package:hrm/widgets/widgets.dart';

class RekapAbsensiScreen extends StatefulWidget {
  const RekapAbsensiScreen({Key? key}) : super(key: key);

  @override
  _RekapAbsensiScreenState createState() => _RekapAbsensiScreenState();
}

class _RekapAbsensiScreenState extends State<RekapAbsensiScreen> {
  List<Absensi> riwayatAbsensi = [];
  final AbsensiService absensiService = AbsensiService();
  bool isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Absensi> absensi = await absensiService.getAbsensiFilter(
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
      setState(() {
        riwayatAbsensi = absensi;
      });
    } catch (e) {
      _showMessage('Error fetching attendance data: $e', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _updateDateSelection(bool isMonthIncrement) {
    setState(() {
      if (isMonthIncrement) {
        if (_selectedMonth < 12) {
          _selectedMonth++;
        } else {
          _selectedMonth = 1;
          _selectedYear++;
        }
      } else {
        if (_selectedMonth > 1) {
          _selectedMonth--;
        } else {
          _selectedMonth = 12;
          _selectedYear--;
        }
      }
    });
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFilterControls(),
                    const SizedBox(height: 20),
                    Expanded(child: _buildRiwayatAbsensiList()),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Filter Bulan
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth > 1) {
                        _selectedMonth--;
                      } else {
                        _selectedMonth = 12;
                        _selectedYear--;
                      }
                    });
                    _refreshData();
                  },
                ),
                Expanded(
                  child: TextField(
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Bulan',
                      labelStyle: const TextStyle(
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _selectedMonth.toString(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth < 12) {
                        _selectedMonth++;
                      } else {
                        _selectedMonth = 1;
                        _selectedYear++;
                      }
                    });
                    _refreshData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Filter Tahun
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                    _refreshData();
                  },
                ),
                Expanded(
                  child: TextField(
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      labelStyle: const TextStyle(
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _selectedYear.toString(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      _selectedYear++;
                    });
                    _refreshData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatAbsensiList() {
    if (riwayatAbsensi.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data absensi.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: riwayatAbsensi.length,
      itemBuilder: (context, index) {
        final absensi = riwayatAbsensi[index];
        Uint8List? imageBytesMasuk = _decodeBase64(absensi.fotoMasuk);
        Uint8List? imageBytesKeluar = _decodeBase64(absensi.fotoKeluar);
        return GestureDetector(
          onTap: () => _showAbsensiDetail(context, absensi, imageBytesMasuk, imageBytesKeluar),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildImageWidget(imageBytesMasuk, 'Foto'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absensi.tanggal ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Masuk: ${absensi.jamMasuk ?? '-'}'),
                        Text('Keluar: ${absensi.jamKeluar ?? '-'}'),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAbsensiDetail(BuildContext context, Absensi absensi, Uint8List? imageMasuk, Uint8List? imageKeluar) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Detail Absensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(thickness: 1.0),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              if (imageMasuk != null || imageKeluar != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (imageMasuk != null) _buildImageThumbnail(imageMasuk, 'Foto Masuk'),
                    if (imageKeluar != null) _buildImageThumbnail(imageKeluar, 'Foto Keluar'),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  
  
  Widget _buildDetailItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value),
      ],
    );
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

  Widget _buildImageThumbnail(Uint8List image, String title) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        Image.memory(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ],
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
}
