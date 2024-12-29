import 'package:flutter/material.dart';
import 'package:hrm/api/izin_service.dart';
import 'package:hrm/model/izin.dart';
import 'package:hrm/screens/Add_izin.dart'; // Pastikan ini adalah layar formulir izin

class IzinScreen extends StatefulWidget {
  const IzinScreen({Key? key}) : super(key: key);

  @override
  _IzinScreenState createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final IzinService _izinService = IzinService();
  late Future<List<Izin>> futureIzin;

  @override
  void initState() {
    super.initState();
    futureIzin = _fetchIzin(); // Memuat data saat inisialisasi
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData(); // Memuat ulang data setiap kali layar ditampilkan kembali
  }

  void _refreshData() {
    setState(() {
      futureIzin = _fetchIzin(); // Perbarui future untuk memuat data terbaru
    });
  }

  Future<List<Izin>> _fetchIzin() async {
    try {
      return await _izinService.getIzin(); // Panggil fungsi untuk mendapatkan data izin
    } catch (e) {
      throw Exception('Gagal memuat data izin: $e');
    }
  }

  Future<void> _deleteIzin(int izinId) async {
  // Menampilkan dialog konfirmasi sebelum menghapus izin
  bool? confirmDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus izin ini?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () {
              Navigator.of(context).pop(false); // Jika batal, return false
            },
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () {
              Navigator.of(context).pop(true); // Jika hapus, return true
            },
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
  try {
    await _izinService.deleteIzin(izinId); // Hapus izin berdasarkan ID
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Izin berhasil dihapus!',
          style: TextStyle(color: Colors.white), // Warna teks putih
        ),
        backgroundColor: Colors.green, // Warna hijau untuk keberhasilan
      ),
    );
    _refreshData(); // Refresh data setelah penghapusan
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gagal menghapus izin: $e',
          style: TextStyle(color: Colors.white), // Warna teks putih
        ),
        backgroundColor: Colors.red, // Warna merah untuk kegagalan
      ),
    );
  }
}    
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Izin'),
        backgroundColor: Colors.blue[800],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<Izin>>(
          future: futureIzin,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada data izin.'));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final izin = snapshot.data![index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  '${izin.durasi}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${izin.tgl_mulai} - ${izin.tgl_selesai}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Izin',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
  izin.status,
  style: TextStyle(
    color: izin.status.toLowerCase() == 'disetujui'
        ? Colors.green
        : (izin.status.toLowerCase() == 'ditolak'
            ? Colors.red
            : (izin.status.toLowerCase() == 'pending' ? Colors.yellow : Colors.grey)),
    fontWeight: FontWeight.bold,
  ),
),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => IzinForm(izin: izin),
                                      ),
                                    ).then((_) => _refreshData());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteIzin(izin.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Keterangan: ${izin.keterangan}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Alasan: ${izin.alasan}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IzinForm()),
          ).then((_) => _refreshData());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Izin',
      ),
    );
  }
}
