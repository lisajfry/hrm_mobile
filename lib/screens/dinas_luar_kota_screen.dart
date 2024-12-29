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
  late Future<List<DinasLuarKota>> futureDinasLuarKota;

  @override
  void initState() {
    super.initState();
    _refreshData(); 
    futureDinasLuarKota = _fetchDinasLuarKota();
  }

  Future<List<DinasLuarKota>> _fetchDinasLuarKota() async {
    try {
      return await DinasLuarKotaService().getDinasLuarKota();
    } catch (e, stacktrace) {
      print('Error saat memuat data dinas luar kota: $e');
      print('Stacktrace: $stacktrace');
      throw Exception('Gagal memuat data dinas luar kota: $e');
    }
  }

  Future<void> _deleteDinasLuarKota(int id) async {
    try {
      await DinasLuarKotaService().deleteDinasLuarKota(id);
      _refreshData();
    } catch (e, stacktrace) {
      print('Error saat menghapus data dinas luar kota: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _refreshData() {
    setState(() {
      futureDinasLuarKota = _fetchDinasLuarKota(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Dinas Luar Kota'),
        backgroundColor: Colors.blue[800],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<DinasLuarKota>>(
          future: futureDinasLuarKota,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print('Error FutureBuilder: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Tidak ada data dinas luar kota.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  final dinas = snapshot.data![index];
                  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                  final String formattedTglBerangkat = dateFormat.format(dinas.tglBerangkat);
                  final String formattedTglKembali = dateFormat.format(dinas.tglKembali);

                  final NumberFormat currencyFormat = NumberFormat('#,##0', 'id_ID');
                  final String formattedTotalBiaya = currencyFormat.format(dinas.totalBiaya);

                  Color statusColor;
                  switch (dinas.status.toLowerCase()) {
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
                    elevation: 4,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$formattedTglBerangkat - $formattedTglKembali',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => DinasLuarKotaForm(dinas: dinas)),
                                      ).then((_) {
                                        setState(() {
                                          futureDinasLuarKota = _fetchDinasLuarKota();
                                        });
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _deleteDinasLuarKota(dinas.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            dinas.kotaTujuan,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Keperluan: ${dinas.keperluan}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 5),
                          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Text(
        'Total Biaya: Rp $formattedTotalBiaya',
        style: TextStyle(fontSize: 14),
      ),
    ),
    Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dinas.status,
        style: TextStyle(
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
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DinasLuarKotaForm()),
          ).then((_) {
            setState(() {
              futureDinasLuarKota = _fetchDinasLuarKota();
            });
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Tambah Dinas Luar Kota',
      ),
    );
  }
}
