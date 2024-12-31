import 'package:flutter/material.dart';
import 'package:hrm/api/izin_service.dart';
import 'package:hrm/model/izin.dart';

class IzinForm extends StatefulWidget {
  final Izin? izin;

  IzinForm({this.izin});

  @override
  _IzinFormState createState() => _IzinFormState();
}

class _IzinFormState extends State<IzinForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tglMulaiController;
  late TextEditingController _tglSelesaiController;
  late TextEditingController _keteranganController;
  String? alasan; // Variabel untuk menyimpan alasan
  late int idKaryawan;

  @override
  void initState() {
    super.initState();
    _tglMulaiController = TextEditingController(text: widget.izin?.tgl_mulai ?? '');
    _tglSelesaiController = TextEditingController(text: widget.izin?.tgl_selesai ?? '');
    _keteranganController = TextEditingController(text: widget.izin?.keterangan ?? '');
    alasan = widget.izin?.alasan;
    idKaryawan = widget.izin?.idKaryawan ?? 1;
  }

  @override
  void dispose() {
    _tglMulaiController.dispose();
    _tglSelesaiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        if (isStartDate) {
          _tglMulaiController.text = formattedDate;
        } else {
          _tglSelesaiController.text = formattedDate;
        }
      });
    }
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      final izin = Izin(
        id: widget.izin?.id ?? 0,
        idKaryawan: idKaryawan,
        tgl_mulai: _tglMulaiController.text,
        tgl_selesai: _tglSelesaiController.text,
        keterangan: _keteranganController.text,
        alasan: alasan!,
        durasi: (_tglSelesaiController.text.isNotEmpty && _tglMulaiController.text.isNotEmpty)
            ? (DateTime.parse(_tglSelesaiController.text).difference(DateTime.parse(_tglMulaiController.text)).inDays + 1)
            : 0,
        status: 'Diajukan',
      );

      try {
        if (widget.izin == null) {
          await IzinService().addIzin(izin);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Izin berhasil ditambahkan!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await IzinService().updateIzin(izin);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Izin berhasil diperbarui!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                e.toString().contains('Pengajuan izin pada tanggal ini sudah ada')
                    ? 'Pengajuan izin pada tanggal ini sudah ada.'
                    : 'Terjadi kesalahan saat memproses pengajuan izin.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.izin == null ? 'Tambah Izin' : 'Edit Izin'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal Mulai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _tglMulaiController,
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal mulai',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal mulai tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Text('Tanggal Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _tglSelesaiController,
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal selesai',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal selesai tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Alasan',
                    border: OutlineInputBorder(),
                  ),
                  value: alasan,
                  items: ['izin', 'cuti'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      alasan = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Alasan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _keteranganController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Keterangan tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: submitForm,
                    icon: Icon(Icons.save),
                    label: Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
