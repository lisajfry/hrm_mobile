import 'package:flutter/material.dart';
import '../api/lembur_service.dart';
import '../model/lembur.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LemburForm extends StatefulWidget {
  @override
  _LemburFormState createState() => _LemburFormState();
}

class _LemburFormState extends State<LemburForm> {
  final _formKey = GlobalKey<FormState>();
  final _tglLemburController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();
  final _alasanController = TextEditingController();

  int? idKaryawan;
  String status = 'pending';

  @override
  void dispose() {
    _tglLemburController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

 @override
void initState() {
  super.initState();
  _fetchIdKaryawan(); // Ambil ID karyawan
  // Inisialisasi controller lainnya
}

Future<void> _fetchIdKaryawan() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    idKaryawan = prefs.getInt('id_karyawan') ?? 0; // Default ke 0 jika tidak ditemukan
  });
}


  Future<void> _submitForm() async {
    if (idKaryawan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID Karyawan tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final lembur = Lembur(
          idKaryawan: idKaryawan!,
          tanggalLembur: _tglLemburController.text,
          jamMulai: _jamMulaiController.text,
          jamSelesai: _jamSelesaiController.text,
          durasiLembur: _calculateDuration(),
          alasanLembur: _alasanController.text.isEmpty ? null : _alasanController.text,
          status: status,
        );

        await LemburService().submitLembur(lembur);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lembur berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan lembur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double _calculateDuration() {
    final start = DateTime.parse('2024-12-28 ${_jamMulaiController.text}');
    final end = DateTime.parse('2024-12-28 ${_jamSelesaiController.text}');
    return end.difference(start).inMinutes / 60.0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _tglLemburController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final String formattedTime = picked.format(context);
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Lembur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _tglLemburController,
                    label: 'Tanggal Lembur',
                    hint: 'Pilih tanggal',
                    validator: _validateDate,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(context, _jamMulaiController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _jamMulaiController,
                    label: 'Jam Mulai',
                    hint: 'Pilih jam mulai',
                    validator: _validateTime,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(context, _jamSelesaiController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _jamSelesaiController,
                    label: 'Jam Selesai',
                    hint: 'Pilih jam selesai',
                    validator: _validateTime,
                  ),
                ),
              ),
              _buildTextField(
                controller: _alasanController,
                label: 'Alasan Lembur',
                hint: 'Opsional',
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) return 'Tanggal tidak boleh kosong';
    try {
      DateTime.parse(value);
    } catch (_) {
      return 'Format tanggal tidak valid';
    }
    return null;
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) return 'Waktu tidak boleh kosong';
    return null;
  }
}
