import 'package:flutter/material.dart';
import 'package:hrm/api/payroll_service.dart';
import 'package:hrm/api/slip_gaji_service.dart'; // Import SlipGajiService
import 'home_screen.dart'; // Import halaman HomeScreen
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class PayrollScreen extends StatefulWidget {
  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  Map<String, dynamic>? payrollData;
  bool isLoading = true;
  SlipGajiService slipGajiService = SlipGajiService();
  bool isDownloading = false;  // Menambahkan variabel untuk status loading
  String? namaKaryawan;
  String? bulan;
  String? selectedBulan;
  String? selectedTahun;

  @override
  void initState() {
    super.initState();
    fetchPayrollData();
    getNamaKaryawan();
  }

  void fetchPayrollData({int? bulan, int? tahun}) async {
  setState(() {
    isLoading = true;
    payrollData = null; // Reset payroll data ketika filter diubah
  });
  try {
    // Panggil service dengan parameter bulan dan tahun
    final data = await PayrollService().fetchPayrollSummary(bulan: bulan, tahun: tahun);
    setState(() {
      payrollData = data; // Menyimpan data yang baru
    });
  } catch (e) {
    print('Error saat memuat data payroll: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  void getNamaKaryawan() async {
    try {
      String? nama = await slipGajiService.getNamaKaryawan();
      if (nama != null) {
        setState(() {
          namaKaryawan = nama;
        });
      } else {
        print('Nama karyawan tidak ditemukan.');
      }
    } catch (e) {
      print('Gagal mendapatkan nama karyawan: $e');
    }
  }
void downloadSlipGaji() async {
  if (namaKaryawan == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nama karyawan tidak ditemukan')),
    );
    return;
  }

  setState(() {
    isDownloading = true; // Status download dimulai
  });

  try {
    // Pastikan bulan dan tahun dipilih
    if (selectedBulan == null || selectedTahun == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih bulan dan tahun terlebih dahulu')),
      );
      return;
    }

    // Ambil bulan dan tahun yang dipilih
    int bulan = int.tryParse(selectedBulan!) ?? DateTime.now().month; // Default ke bulan sekarang jika null
    int tahun = int.tryParse(selectedTahun!) ?? DateTime.now().year; // Default ke tahun sekarang jika null

    // Nama file slip gaji
    String bulanNama = _getNamaBulan(bulan); // Nama bulan
    String filename = 'slip_gaji_${namaKaryawan}_$bulanNama$tahun.pdf';

    // Panggil service untuk mendownload slip gaji dan dapatkan path lokasi file yang sudah terubah
    String filePath = await slipGajiService.downloadSlipGaji(filename, bulan, tahun);

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Slip gaji berhasil didownload: $filePath\nLokasi: $filePath',
      style: TextStyle(color: Colors.white), // Teks putih
    ),
    backgroundColor: Colors.green, // Background hijau
  ),
);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gagal mendownload slip gaji: $e',
          style: TextStyle(color: Colors.white), // Teks putih
          ),backgroundColor: Colors.red, // Background merah
          ),
    );
  } finally {
    setState(() {
      isDownloading = false; // Status download selesai
    });
  }
}

  // Fungsi untuk mendapatkan nama bulan
  String _getNamaBulan(int bulan) {
    List<String> namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return namaBulan[bulan - 1];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          title: Text('Payroll Summary'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: isLoading
    ? Center(child: CircularProgressIndicator())
    : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Payroll Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: selectedBulan,
                          hint: Text('Pilih Bulan'),
                          items: List.generate(12, (index) {
                            String bulan = _getNamaBulan(index + 1);
                            return DropdownMenuItem(
                              value: (index + 1).toString(),
                              child: Text(bulan),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              selectedBulan = value;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: selectedTahun,
                          hint: Text('Pilih Tahun'),
                          items: List.generate(5, (index) {
                            String tahun = (DateTime.now().year - index).toString();
                            return DropdownMenuItem(
                              value: tahun,
                              child: Text(tahun),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              selectedTahun = value;
                            });
                          },
                        ),
                        Expanded(
  child: ElevatedButton(
    onPressed: () {
      // Pastikan kita hanya mengirim bulan dan tahun yang valid
      if (selectedBulan != null && selectedTahun != null) {
        fetchPayrollData(
          bulan: int.tryParse(selectedBulan!),
          tahun: int.tryParse(selectedTahun!),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silakan pilih bulan dan tahun')),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size(100, 40),
    ),
    child: Text(
      'Filter',
      style: TextStyle(fontSize: 14),
    ),
  ),
)
                    ],
                    ),
                  ),
                  DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
                    ),
                    dataRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Jumlah',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                    rows: payrollData != null
                        ? [
                            DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  Icon(Icons.event, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Izin'),
                                ],
                              )),
                              DataCell(Text(
                                payrollData != null &&
                                        payrollData!['izin_count'] != null
                                    ? payrollData!['izin_count'].toString()
                                    : '0', // Menampilkan 0 jika tidak ada data
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                            ]),
                            DataRow(
                              cells: [
                                DataCell(Row(
                                  children: [
                                    Icon(Icons.location_city, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Dinas Luar Kota'),
                                  ],
                                )),
                                DataCell(Text(
                                  payrollData != null &&
                                          payrollData!['dinas_luar_kota_count'] != null
                                      ? payrollData!['dinas_luar_kota_count'].toString()
                                      : '0',  
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                            DataRow(
                              cells: [
                                DataCell(Row(
                                  children: [
                                    Icon(Icons.beach_access, color: Colors.purple),
                                    SizedBox(width: 8),
                                    Text('Cuti'),
                                  ],
                                )),
                                DataCell(Text(
                                  payrollData!['cuti_count']?.toString() ?? '0',
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                            DataRow(
                              cells: [
                                DataCell(Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Kehadiran'),
                                  ],
                                )),
                                DataCell(Text(
                                  payrollData!['kehadiran_count']?.toString() ?? '0',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                            DataRow(
                              cells: [
                                DataCell(Row(
                                  children: [
                                    Icon(Icons.timer, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text('Lembur (jam)'),
                                  ],
                                )),
                                DataCell(Text(
                                  payrollData!['lembur_count']?.toString() ?? '0',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                          ]
                        : [],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: isDownloading ? null : downloadSlipGaji,
                    icon: isDownloading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Icon(Icons.download),
                    label: Text(isDownloading ? 'Mengunduh...' : 'Download Slip Gaji'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Pindahkan "Tidak ada data" di bawah DataTable
                  payrollData == null || payrollData!.isEmpty
                      ? Center(child: Text('Tidak ada data'))
                      : SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ),
),

    );
  }
}
