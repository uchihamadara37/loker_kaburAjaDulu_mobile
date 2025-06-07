import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart'; // Untuk konversi dari Lowongan API

class LowonganDisimpanModel {
  final String id; // ID dari lowongan di backend
  final String userId;
  final String? namaPerusahaan;
  final String? deskripsiLowongan;
  final String? rentangGaji;
  final String? alamat;
  final double? latitude;
  final double? longitude;
  final String? jenisPenempatan;
  final String? contactEmail;
  final String? hrdYangPostId;
  final DateTime waktuSimpan;

  LowonganDisimpanModel({
    required this.id,
    required this.userId,
    this.namaPerusahaan,
    this.deskripsiLowongan,
    this.rentangGaji,
    this.alamat,
    this.latitude,
    this.longitude,
    this.jenisPenempatan,
    this.contactEmail,
    this.hrdYangPostId,
    required this.waktuSimpan,
  });

  // Konversi dari Lowongan (model API) ke LowonganDisimpanModel
  factory LowonganDisimpanModel.fromLowonganAPI(LowonganModel apiLowongan, String currentUserId) {
    return LowonganDisimpanModel(
      id: apiLowongan.id,
      userId: currentUserId,
      namaPerusahaan: apiLowongan.namaPerusahaan,
      deskripsiLowongan: apiLowongan.deskripsiLowongan,
      rentangGaji: apiLowongan.rentangGaji,
      alamat: apiLowongan.alamat,
      latitude: apiLowongan.latitude,
      longitude: apiLowongan.longitude,
      jenisPenempatan: apiLowongan.jenisPenempatan.name, // Simpan sebagai string
      contactEmail: apiLowongan.contactEmail,
      hrdYangPostId: apiLowongan.hrdYangPostId,
      waktuSimpan: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nama_perusahaan': namaPerusahaan,
      'deskripsi_lowongan': deskripsiLowongan,
      'rentang_gaji': rentangGaji,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'jenisPenempatan': jenisPenempatan,
      'contact_email': contactEmail,
      'hrd_yang_post_id': hrdYangPostId,
      'waktu_simpan': waktuSimpan.toIso8601String(),
    };
  }

  factory LowonganDisimpanModel.fromMap(Map<String, dynamic> map) {
    return LowonganDisimpanModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      namaPerusahaan: map['nama_perusahaan'] as String?,
      deskripsiLowongan: map['deskripsi_lowongan'] as String?,
      rentangGaji: map['rentang_gaji'] as String?,
      alamat: map['alamat'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      jenisPenempatan: map['jenisPenempatan'] as String?,
      contactEmail: map['contact_email'] as String?,
      hrdYangPostId: map['hrd_yang_post_id'] as String?,
      waktuSimpan: DateTime.parse(map['waktu_simpan'] as String),
    );
  }
}