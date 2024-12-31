import 'package:flutter/material.dart';
import 'package:hrm/api/izin_service.dart';
import 'package:hrm/model/izin.dart';
import 'package:hrm/screens/Add_izin.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({Key? key}) : super(key: key);

  @override
  _IzinScreenState createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final IzinService _izinService = IzinService();
  late Future<List<Izin>> futureIzin;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<int> months = List.generate(12, (index) => index + 1);
  final List<int> years = List.generate(10, (index) => 2020 + index);

  @override
  void initState() {
    super.initState();
    futureIzin = _fetchIzin();
  }

  void _refreshData() {
    setState(() {
      futureIzin = _fetchIzin();
    });
  }

  Future<List<Izin>> _fetchIzin() async {
    try {
      return await _izinService.getIzin(
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
    } catch (e) {
      throw Exception('Gagal memuat data izin: $e');
    }
  }

  Future<void> _deleteIzin(int izinId) async {
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
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _izinService.deleteIzin(izinId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus izin: $e'),
            backgroundColor: Colors.red,
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
      body: Column(
        children: [
          Padding(
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
              color: Colors.blue, // Warna tombol kiri
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
                  color: Colors.blue, // Warna teks
                ),
                decoration: InputDecoration(
                  labelText: 'Bulan',
                  labelStyle: const TextStyle(
                    color: Colors.blue, // Warna label
                  ),
                  filled: true,
                  fillColor: Colors.blue[50], // Background TextField
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
              color: Colors.blue, // Warna tombol kanan
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
              color: Colors.blue, // Warna tombol kiri
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
                  color: Colors.blue, // Warna teks
                ),
                decoration: InputDecoration(
                  labelText: 'Tahun',
                  labelStyle: const TextStyle(
                    color: Colors.blue, // Warna label
                  ),
                  filled: true,
                  fillColor: Colors.blue[50], // Background TextField
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
              color: Colors.blue, // Warna tombol kanan
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
)
,
          Expanded(
            child: RefreshIndicator(
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final izin = snapshot.data![index];
                        return _buildIzinCard(izin);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
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

  Widget _buildIzinCard(Izin izin) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
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
                   Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        izin.tgl_mulai,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        izin.tgl_selesai,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                  const SizedBox(height: 4),
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
                                  : (izin.status.toLowerCase() == 'pending'
                                      ? Colors.orange
                                      : Colors.grey)),
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
}
}