class Absensi {
  final int id;
  final int idKaryawan;
  final String tanggal;
  final String jamMasuk;
  final String? jamKeluar;
  final String? fotoMasuk;
  final String? fotoKeluar;
  final double? latitudeMasuk;
  final double? longitudeMasuk;
  final double? latitudeKeluar;
  final double? longitudeKeluar;
  final String status;

  Absensi({
    required this.id,
    required this.idKaryawan,
    required this.tanggal,
    required this.jamMasuk,
    this.jamKeluar,
    this.fotoMasuk,
    this.fotoKeluar,
    this.latitudeMasuk,
    this.longitudeMasuk,
    this.latitudeKeluar,
    this.longitudeKeluar,
    required this.status,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'],
      idKaryawan: json['id_karyawan'],
      tanggal: json['tanggal'],
      jamMasuk: json['jam_masuk'],
      jamKeluar: json['jam_keluar'],
      fotoMasuk: json['foto_masuk'],
      fotoKeluar: json['foto_keluar'],
      latitudeMasuk: json['latitude_masuk'] != null
          ? double.tryParse(json['latitude_masuk'].toString())
          : null,
      longitudeMasuk: json['longitude_masuk'] != null
          ? double.tryParse(json['longitude_masuk'].toString())
          : null,
      latitudeKeluar: json['latitude_keluar'] != null
          ? double.tryParse(json['latitude_keluar'].toString())
          : null,
      longitudeKeluar: json['longitude_keluar'] != null
          ? double.tryParse(json['longitude_keluar'].toString())
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_karyawan': idKaryawan,
      'tanggal': tanggal,
      'jam_masuk': jamMasuk,
      'jam_keluar': jamKeluar,
      'foto_masuk': fotoMasuk,
      'foto_keluar': fotoKeluar,
      'latitude_masuk': latitudeMasuk,
      'longitude_masuk': longitudeMasuk,
      'latitude_keluar': latitudeKeluar,
      'longitude_keluar': longitudeKeluar,
      'status': status,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id_karyawan': idKaryawan,
      'tanggal': tanggal,
      'jam_masuk': jamMasuk,
      'jam_keluar': jamKeluar,
      'foto_masuk': fotoMasuk,
      'foto_keluar': fotoKeluar,
      'latitude_masuk': latitudeMasuk,
      'longitude_masuk': longitudeMasuk,
      'latitude_keluar': latitudeKeluar,
      'longitude_keluar': longitudeKeluar,
      'status': status,
    };
  }
}
