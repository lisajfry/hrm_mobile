import 'package:flutter/material.dart';
import '../api/lembur_service.dart';
import '../model/lembur.dart';

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

  int idKaryawan = 1;
  String status = 'pending';

  @override
  void dispose() {
    _tglLemburController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final lembur = Lembur(
          idKaryawan: idKaryawan,
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
              _buildTextField(
                controller: _tglLemburController,
                label: 'Tanggal Lembur',
                hint: 'YYYY-MM-DD',
                validator: _validateDate,
              ),
              _buildTextField(
                controller: _jamMulaiController,
                label: 'Jam Mulai',
                hint: 'HH:mm:ss',
                validator: _validateTime,
              ),
              _buildTextField(
                controller: _jamSelesaiController,
                label: 'Jam Selesai',
                hint: 'HH:mm:ss',
                validator: _validateTime,
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
    try {
      DateTime.parse('2024-12-28 $value');
    } catch (_) {
      return 'Format waktu tidak valid';
    }
    return null;
  }
}
