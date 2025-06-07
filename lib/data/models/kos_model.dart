// Sesuaikan dengan respons API Anda
import 'package:loker_kabur_aja_dulu/data/models/user_model.dart'; // Jika perlu data Pemilik

class KosModel {
  final String id;
  final String pemilikId;
  final User? pemilik; // Opsional
  final String namaKos;
  final double latitude;
  final double longitude;
  final String alamat;
  final double hargaPerbulan;
  final double? hargaDp;
  final String mataUangYangDipakai;
  final String fasilitas;
  final String? fotoKos; // Di backend sudah diubah jadi String tunggal opsional
  final String? kontak;
  final String? email;
  final String deskripsi;
  final int jumlahKamarTersedia;
  final DateTime waktuPost;
  final DateTime createdAt;
  final DateTime updatedAt;

  KosModel({
    required this.id,
    required this.pemilikId,
    this.pemilik,
    required this.namaKos,
    required this.latitude,
    required this.longitude,
    required this.alamat,
    required this.hargaPerbulan,
    this.hargaDp,
    required this.mataUangYangDipakai,
    required this.fasilitas,
    this.fotoKos,
    this.kontak,
    this.email,
    required this.deskripsi,
    required this.jumlahKamarTersedia,
    required this.waktuPost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KosModel.fromJson(Map<String, dynamic> json) {
    return KosModel(
      id: json['id'] as String,
      pemilikId: json['pemilik_id'] as String,
      pemilik: json['pemilik'] != null ? User.fromJson(json['pemilik'] as Map<String, dynamic>) : null,
      namaKos: json['nama_kos'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      alamat: json['alamat'] as String,
      hargaPerbulan: (json['harga_perbulan'] as num).toDouble(),
      hargaDp: (json['harga_dp'] as num?)?.toDouble(),
      mataUangYangDipakai: json['mata_uang_yang_dipakai'] as String,
      fasilitas: json['fasilitas'] as String,
      fotoKos: json['foto_kos'] as String?, // Sesuaikan dengan backend
      kontak: json['kontak'] as String?,
      email: json['email'] as String?,
      deskripsi: json['deskripsi'] as String,
      jumlahKamarTersedia: json['jumlah_kamar_tersedia'] as int,
      waktuPost: DateTime.parse(json['waktu_post'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pemilik_id': pemilikId,
      'nama_kos': namaKos,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
      'harga_perbulan': hargaPerbulan,
      'harga_dp': hargaDp,
      'mata_uang_yang_dipakai': mataUangYangDipakai,
      'fasilitas': fasilitas,
      // 'foto_kos': fotoKos, // Untuk kirim ke backend, nama fieldnya 'foto_kos' (bukan 'foto_kos_url')
      'kontak': kontak,
      'email': email,
      'deskripsi': deskripsi,
      'jumlah_kamar_tersedia': jumlahKamarTersedia,
    };
  }
}