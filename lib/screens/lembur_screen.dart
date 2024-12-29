import 'package:flutter/material.dart';
import '../api/lembur_service.dart';
import '../model/lembur.dart';
import 'home_screen.dart'; // Import halaman HomeScreen
import 'add_lembur.dart';

class LemburScreen extends StatefulWidget {
  @override
  _LemburScreenState createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  final LemburService _lemburService = LemburService();
  List<Lembur> _lemburList = [];
  bool _isLoading = true;
  int? _selectedMonth;
  int? _selectedYear;

  final List<int> months = List.generate(12, (index) => index + 1);
  final List<int> years = List.generate(10, (index) => 2020 + index);

  @override
  void initState() {
    super.initState();
    _loadLembur();
  }

  Future<void> _loadLembur() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lembur = await _lemburService.fetchLembur(
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
      setState(() {
        _lemburList = lembur;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data lembur')),
      );
    }
  }

  Future<void> _navigateToHomeScreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToHomeScreen();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lembur'),
          backgroundColor: Colors.blueAccent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _navigateToHomeScreen();
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<int>(
                    hint: Text('Pilih Bulan'),
                    value: _selectedMonth,
                    items: months
                        .map((month) => DropdownMenuItem<int>(
                              value: month,
                              child: Text('Bulan $month'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                        _loadLembur();
                      });
                    },
                  ),
                  DropdownButton<int>(
                    hint: Text('Pilih Tahun'),
                    value: _selectedYear,
                    items: years
                        .map((year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        _loadLembur();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _lemburList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data lembur.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: _lemburList.length,
                          itemBuilder: (context, index) {
                            final lembur = _lemburList[index];
                            Color statusColor;
                            switch (lembur.status ?? 'Tidak diketahui') {
                              case 'disetujui':
                                statusColor = Colors.green;
                                break;
                              case 'ditolak':
                                statusColor = Colors.red;
                                break;
                              case 'pending':
                              default:
                                statusColor = Colors.yellow;
                                break;
                            }
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  'Tanggal: ${lembur.tanggalLembur}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Durasi: ${lembur.durasiLembur} jam'),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Text(
                                              lembur.status ?? 'Tidak diketahui',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text('Alasan: ${lembur.alasanLembur ?? "Tidak ada"}'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LemburForm()),
          ).then((_) => _loadLembur());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Izin',
      ),
      ),
    );
  }
}
