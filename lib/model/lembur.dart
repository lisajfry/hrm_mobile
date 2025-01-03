class Lembur {
  final int? id;
  final int idKaryawan;
  final String tanggalLembur;
  final String jamMulai;
  final String jamSelesai;
  final double durasiLembur;
  final String? alasanLembur;
  final String? status;

  Lembur({
    this.id,
    required this.idKaryawan,
    required this.tanggalLembur,
    required this.jamMulai,
    required this.jamSelesai,
    required this.durasiLembur,
    this.alasanLembur,
    this.status,
  });

  // From JSON
  factory Lembur.fromJson(Map<String, dynamic> json) {
    return Lembur(
      id: json['id'],
      idKaryawan: json['id_karyawan'],
      tanggalLembur: json['tanggal_lembur'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
      durasiLembur: json['durasi_lembur']?.toDouble() ?? 0.0,
      alasanLembur: json['alasan_lembur'],
      status: json['status'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id_karyawan': idKaryawan,
      'tanggal_lembur': tanggalLembur,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'durasi_lembur': durasiLembur,
      'alasan_lembur': alasanLembur,
      'status': status,
    };
  }
}
