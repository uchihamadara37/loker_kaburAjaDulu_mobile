import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart'; // Untuk konversi dari Kos API

class KosDipesanModel {
  final int? idPemesanan; // ID lokal, auto-increment
  final String kosId;
  final String userId;
  final String? namaKos;
  final String? alamat;
  final double? hargaPerbulan;
  final double? hargaDpDibayar;
  final String? mataUangYangDipakai;
  final String? fotoKos; // URL foto utama
  final double? latitude;
  final double? longitude;
  final DateTime tanggalPesan;
  final String? kontakPemilikKos;
  final String? emailPemilikKos;


  KosDipesanModel({
    this.idPemesanan,
    required this.kosId,
    required this.userId,
    this.namaKos,
    this.alamat,
    this.hargaPerbulan,
    this.hargaDpDibayar,
    this.mataUangYangDipakai,
    this.fotoKos,
    this.latitude,
    this.longitude,
    required this.tanggalPesan,
    this.kontakPemilikKos,
    this.emailPemilikKos,
  });

  // Konversi dari Kos (model API) ke KosDipesanModel
  // Perlu dpAmount yang dibayar dan userId saat pemesanan
  factory KosDipesanModel.fromKosAPI(KosModel apiKos, String currentUserId, double dpAmount) {
    return KosDipesanModel(
      kosId: apiKos.id,
      userId: currentUserId,
      namaKos: apiKos.namaKos,
      alamat: apiKos.alamat,
      hargaPerbulan: apiKos.hargaPerbulan,
      hargaDpDibayar: dpAmount, // DP yang dibayar
      mataUangYangDipakai: apiKos.mataUangYangDipakai,
      fotoKos: apiKos.fotoKos,
      latitude: apiKos.latitude,
      longitude: apiKos.longitude,
      tanggalPesan: DateTime.now(),
      kontakPemilikKos: apiKos.kontak,
      emailPemilikKos: apiKos.email,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id_pemesanan': idPemesanan, // Akan di-handle oleh auto-increment jika null saat insert
      'kosId': kosId,
      'userId': userId,
      'nama_kos': namaKos,
      'alamat': alamat,
      'harga_perbulan': hargaPerbulan,
      'harga_dp_dibayar': hargaDpDibayar,
      'mata_uang_yang_dipakai': mataUangYangDipakai,
      'foto_kos': fotoKos,
      'latitude': latitude,
      'longitude': longitude,
      'tanggal_pesan': tanggalPesan.toIso8601String(),
      'kontak_pemilik_kos': kontakPemilikKos,
      'email_pemilik_kos': emailPemilikKos,
    };
  }

  factory KosDipesanModel.fromMap(Map<String, dynamic> map) {
    return KosDipesanModel(
      idPemesanan: map['id_pemesanan'] as int?,
      kosId: map['kosId'] as String,
      userId: map['userId'] as String,
      namaKos: map['nama_kos'] as String?,
      alamat: map['alamat'] as String?,
      hargaPerbulan: map['harga_perbulan'] as double?,
      hargaDpDibayar: map['harga_dp_dibayar'] as double?,
      mataUangYangDipakai: map['mata_uang_yang_dipakai'] as String?,
      fotoKos: map['foto_kos'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      tanggalPesan: DateTime.parse(map['tanggal_pesan'] as String),
      kontakPemilikKos: map['kontak_pemilik_kos'] as String?,
      emailPemilikKos: map['email_pemilik_kos'] as String?,
    );
  }
}