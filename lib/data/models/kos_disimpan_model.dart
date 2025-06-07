import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart'; // Untuk konversi dari Kos API

class KosDisimpanModel {
  final String id; // ID dari Kos di backend
  final String userId;
  final String? namaKos;
  final String? alamat;
  final double? hargaPerbulan;
  final String? mataUangYangDipakai;
  final String? fotoKos; // URL foto utama
  final double? latitude;
  final double? longitude;
  final DateTime waktuSimpan;

  KosDisimpanModel({
    required this.id,
    required this.userId,
    this.namaKos,
    this.alamat,
    this.hargaPerbulan,
    this.mataUangYangDipakai,
    this.fotoKos,
    this.latitude,
    this.longitude,
    required this.waktuSimpan,
  });

  // Konversi dari Kos (model API) ke KosDisimpanModel
  factory KosDisimpanModel.fromKosAPI(KosModel apiKos, String currentUserId) {
    return KosDisimpanModel(
      id: apiKos.id,
      userId: currentUserId,
      namaKos: apiKos.namaKos,
      alamat: apiKos.alamat,
      hargaPerbulan: apiKos.hargaPerbulan,
      mataUangYangDipakai: apiKos.mataUangYangDipakai,
      fotoKos: apiKos.fotoKos, // Asumsi fotoKos di API adalah string tunggal (URL)
      latitude: apiKos.latitude,
      longitude: apiKos.longitude,
      waktuSimpan: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nama_kos': namaKos,
      'alamat': alamat,
      'harga_perbulan': hargaPerbulan,
      'mata_uang_yang_dipakai': mataUangYangDipakai,
      'foto_kos': fotoKos,
      'latitude': latitude,
      'longitude': longitude,
      'waktu_simpan': waktuSimpan.toIso8601String(),
    };
  }

  factory KosDisimpanModel.fromMap(Map<String, dynamic> map) {
    return KosDisimpanModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      namaKos: map['nama_kos'] as String?,
      alamat: map['alamat'] as String?,
      hargaPerbulan: map['harga_perbulan'] as double?,
      mataUangYangDipakai: map['mata_uang_yang_dipakai'] as String?,
      fotoKos: map['foto_kos'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      waktuSimpan: DateTime.parse(map['waktu_simpan'] as String),
    );
  }
}