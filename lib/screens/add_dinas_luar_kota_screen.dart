import 'package:flutter/material.dart';
import 'package:hrm/model/dinasluarkota.dart';
import 'package:hrm/api/dinasluarkota_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class DinasLuarKotaForm extends StatefulWidget {
  final DinasLuarKota? dinas;

  DinasLuarKotaForm({this.dinas});

  @override
  _DinasLuarKotaFormState createState() => _DinasLuarKotaFormState();
}

class _DinasLuarKotaFormState extends State<DinasLuarKotaForm> {
  final _formKey = GlobalKey<FormState>();

  late int idKaryawan;
  late DateTime tglBerangkat;
  late DateTime tglKembali;
  late String kotaTujuan;
  late String keperluan;
  late double biayaTransport;
  late double biayaPenginapan;
  late double uangHarian;

  String _formatRupiah(double amount) {
    final numberFormat = NumberFormat("#,##0", "id_ID");
    return numberFormat.format(amount);
  }

  double _parseRupiah(String value) {
    return double.parse(value.replaceAll(RegExp(r'[^\d]'), ''));
  }

  TextInputFormatter _rupiahFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      String formattedText = _formatRupiah(double.parse(text));
      return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.dinas != null) {
      idKaryawan = widget.dinas!.idKaryawan;
      tglBerangkat = widget.dinas!.tglBerangkat;
      tglKembali = widget.dinas!.tglKembali;
      kotaTujuan = widget.dinas!.kotaTujuan;
      keperluan = widget.dinas!.keperluan;
      biayaTransport = widget.dinas!.biayaTransport;
      biayaPenginapan = widget.dinas!.biayaPenginapan;
      uangHarian = widget.dinas!.uangHarian;
    } else {
      idKaryawan = 0;
      tglBerangkat = DateTime.now();
      tglKembali = DateTime.now();
      kotaTujuan = '';
      keperluan = '';
      biayaTransport = 0.0;
      biayaPenginapan = 0.0;
      uangHarian = 0.0;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isDeparture ? tglBerangkat : tglKembali,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isDeparture) {
          tglBerangkat = pickedDate;
        } else {
          tglKembali = pickedDate;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      DinasLuarKota dinas = DinasLuarKota(
        id: widget.dinas?.id ?? 0,
        idKaryawan: idKaryawan,
        tglBerangkat: tglBerangkat,
        tglKembali: tglKembali,
        kotaTujuan: kotaTujuan,
        keperluan: keperluan,
        biayaTransport: biayaTransport,
        biayaPenginapan: biayaPenginapan,
        uangHarian: uangHarian,
        totalBiaya: biayaTransport + biayaPenginapan + uangHarian,
        status: 'Menunggu',
      );

      try {
        if (widget.dinas == null) {
  await DinasLuarKotaService().addDinasLuarKota(dinas);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Dinas berhasil ditambahkan.'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ),
  );
} else {
  await DinasLuarKotaService().updateDinasLuarKota(dinas);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Dinas berhasil diperbarui.'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ),
  );
}

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required String labelText,
    required String initialValue,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blue),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dinas == null ? 'Tambah Dinas Luar Kota' : 'Edit Dinas Luar Kota'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      labelText: 'Tanggal Berangkat',
                      initialValue: DateFormat('yyyy-MM-dd').format(tglBerangkat),
                      onSaved: (_) {},
                      validator: (value) => value!.isEmpty ? 'Tanggal berangkat wajib diisi' : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      labelText: 'Tanggal Kembali',
                      initialValue: DateFormat('yyyy-MM-dd').format(tglKembali),
                      onSaved: (_) {},
                      validator: (value) => value!.isEmpty ? 'Tanggal kembali wajib diisi' : null,
                    ),
                  ),
                ),
                _buildTextField(
                  labelText: 'Kota Tujuan',
                  initialValue: widget.dinas?.kotaTujuan ?? '',
                  onSaved: (value) => kotaTujuan = value!,
                  validator: (value) => value!.isEmpty ? 'Kota tujuan wajib diisi' : null,
                ),
                _buildTextField(
                  labelText: 'Keperluan',
                  initialValue: widget.dinas?.keperluan ?? '',
                  onSaved: (value) => keperluan = value!,
                  validator: (value) => value!.isEmpty ? 'Keperluan wajib diisi' : null,
                ),
                _buildTextField(
                  labelText: 'Biaya Transport',
                  initialValue: widget.dinas?.biayaTransport != null ? _formatRupiah(widget.dinas!.biayaTransport) : '',
                  keyboardType: TextInputType.number,
                  onSaved: (value) => biayaTransport = _parseRupiah(value!),
                  validator: (value) => value!.isEmpty ? 'Biaya transport wajib diisi' : null,
                  inputFormatters: [_rupiahFormatter()],
                ),
                _buildTextField(
                  labelText: 'Biaya Penginapan',
                  initialValue: widget.dinas?.biayaPenginapan != null ? _formatRupiah(widget.dinas!.biayaPenginapan) : '',
                  keyboardType: TextInputType.number,
                  onSaved: (value) => biayaPenginapan = _parseRupiah(value!),
                  validator: (value) => value!.isEmpty ? 'Biaya penginapan wajib diisi' : null,
                  inputFormatters: [_rupiahFormatter()],
                ),
                _buildTextField(
                  labelText: 'Uang Harian',
                  initialValue: widget.dinas?.uangHarian != null ? _formatRupiah(widget.dinas!.uangHarian) : '',
                  keyboardType: TextInputType.number,
                  onSaved: (value) => uangHarian = _parseRupiah(value!),
                  validator: (value) => value!.isEmpty ? 'Uang harian wajib diisi' : null,
                  inputFormatters: [_rupiahFormatter()],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(widget.dinas == null ? 'Tambah' : 'Update', style: TextStyle(fontSize: 16.0)),
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
