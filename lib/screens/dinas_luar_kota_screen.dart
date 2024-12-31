import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrm/api/dinasluarkota_service.dart';
import 'package:hrm/model/dinasluarkota.dart';
import 'package:hrm/screens/add_dinas_luar_kota_screen.dart';

class DinasLuarKotaScreen extends StatefulWidget {
  const DinasLuarKotaScreen({Key? key}) : super(key: key);

  @override
  _DinasLuarKotaScreenState createState() => _DinasLuarKotaScreenState();
}

class _DinasLuarKotaScreenState extends State<DinasLuarKotaScreen> {
  final DinasLuarKotaService _dinasluarkotaService = DinasLuarKotaService();
  late Future<List<DinasLuarKota>> futureDinasLuarKota;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _monthController.text = _selectedMonth.toString();
    _yearController.text = _selectedYear.toString();
    _refreshData();
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<List<DinasLuarKota>> _fetchDinasLuarKota() async {
    try {
      return await _dinasluarkotaService.getDinasLuarKota(
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
    } catch (e) {
      throw Exception('Gagal memuat data dinas luar kota: $e');
    }
  }

  

   Future<void> _deleteDinasLuarKota(int Id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus jadwal dinas luar kota ini?'),
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
        await _dinasluarkotaService.deleteDinasLuarKota(Id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dinas luar kota berhasil dihapus!'),
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


  void _refreshData() {
    setState(() {
      futureDinasLuarKota = _fetchDinasLuarKota();
    });
  }

  void _changeMonth(bool isIncrement) {
    setState(() {
      if (isIncrement) {
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
      _monthController.text = _selectedMonth.toString();
      _yearController.text = _selectedYear.toString();
      _refreshData();
    });
  }

  void _changeYear(bool isIncrement) {
    setState(() {
      _selectedYear += isIncrement ? 1 : -1;
      _yearController.text = _selectedYear.toString();
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Dinas Luar Kota'),
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
                        color: Colors.blue,
                        onPressed: () => _changeMonth(false),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _monthController,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Bulan',
                            labelStyle: const TextStyle(color: Colors.blue),
                            filled: true,
                            fillColor: Colors.blue[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.blue,
                        onPressed: () => _changeMonth(true),
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
                        onPressed: () => _changeYear(false),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tahun',
                            labelStyle: const TextStyle(color: Colors.blue),
                            filled: true,
                            fillColor: Colors.blue[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.blue,
                        onPressed: () => _changeYear(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: FutureBuilder<List<DinasLuarKota>>(
                future: futureDinasLuarKota,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada data dinas luar kota.'));
                  } else {
                    return ListView.separated(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        final dinas = snapshot.data![index];
                        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                        final NumberFormat currencyFormat = NumberFormat('#,##0', 'id_ID');

                       return Card(
  elevation: 2, // Kurangi elevation untuk tampilan lebih minimalis
  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Kurangi margin
  child: Padding(
    padding: const EdgeInsets.all(8), // Kurangi padding
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${dateFormat.format(dinas.tglBerangkat)} - ${dateFormat.format(dinas.tglKembali)}',
              style: const TextStyle(fontSize: 12), // Kurangi font size
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 18), // Kurangi ukuran ikon
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DinasLuarKotaForm(dinas: dinas)),
                    ).then((_) {
                      _refreshData();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18), // Kurangi ukuran ikon
                  onPressed: () async {
                    await _deleteDinasLuarKota(dinas.id);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4), // Kurangi jarak antar elemen
        Text(
          dinas.kotaTujuan,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Kurangi font size
        ),
        const SizedBox(height: 4), // Kurangi jarak antar elemen
        Text(
          'Keperluan: ${dinas.keperluan}',
          style: const TextStyle(fontSize: 12), // Kurangi font size
        ),
        const SizedBox(height: 4), // Kurangi jarak antar elemen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Biaya: Rp ${currencyFormat.format(dinas.totalBiaya)}',
              style: const TextStyle(fontSize: 12), // Kurangi font size
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Kurangi padding badge
              decoration: BoxDecoration(
                color: _getStatusColor(dinas.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dinas.status,
                style: const TextStyle(
                  fontSize: 12, // Kurangi font size
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
                     },
                      separatorBuilder: (BuildContext context, int index) => const Divider(),
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
            MaterialPageRoute(builder: (context) => DinasLuarKotaForm()),
          ).then((_) {
            _refreshData();
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Dinas Luar Kota',
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'pending':
      default:
        return Colors.yellow;
    }
  }
}
