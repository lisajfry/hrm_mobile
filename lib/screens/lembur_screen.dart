import 'package:flutter/material.dart';
import '../api/lembur_service.dart';
import '../model/lembur.dart';
import 'home_screen.dart';
import 'add_lembur.dart';

class LemburScreen extends StatefulWidget {
  @override
  _LemburScreenState createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  final LemburService _lemburService = LemburService();
  List<Lembur> _lemburList = [];
  bool _isLoading = true;
   int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<int> months = List.generate(12, (index) => index + 1);
  final List<int> years = List.generate(21, (index) => 2020 + index); // Tahun 2020 hingga 2040

  @override
  void initState() {
    super.initState();
    _loadLembur();
  }

  void _refreshData() {
    setState(() {
      _loadLembur();
    });
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
            onPressed: _navigateToHomeScreen,
          ),
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
),

            Divider(color: Colors.grey.shade300),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLembur,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _lemburList.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada data lembur.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            itemCount: _lemburList.length,
                            itemBuilder: (context, index) {
                              final lembur = _lemburList[index];
                              Color statusColor;
                              switch (lembur.status ?? 'Tidak diketahui') {
                                case 'disetujui':
                                  statusColor = Colors.green.shade300;
                                  break;
                                case 'ditolak':
                                  statusColor = Colors.red.shade300;
                                  break;
                                case 'pending':
                                default:
                                  statusColor = Colors.amber.shade300;
                                  break;
                              }
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanggal: ${lembur.tanggalLembur}',
                                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Durasi: ${lembur.durasiLembur} jam',
                                              style: TextStyle(fontSize: 13)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: Text(
                                              lembur.status ?? 'Tidak diketahui',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Alasan: ${lembur.alasanLembur ?? "Tidak ada"}',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
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
              MaterialPageRoute(builder: (context) => LemburForm()),
            ).then((_) => _loadLembur());
          },
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
