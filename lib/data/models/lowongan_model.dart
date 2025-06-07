// Sesuaikan dengan respons API Anda
import 'package:loker_kabur_aja_dulu/data/models/user_model.dart'; // Jika perlu data HRD

// Enum untuk JenisPenempatan, harus sinkron dengan backend
enum JenisPenempatan { WFA, WFH, WFO, HYBRID, UNKNOWN }

class LowonganModel {
  final String id;
  final String hrdYangPostId;
  final User? hrd; // Opsional, tergantung apakah backend mengirim detail HRD
  final String namaPerusahaan;
  final double latitude;
  final double longitude;
  final String alamat;
  final String deskripsiLowongan;
  final String rentangGaji;
  final JenisPenempatan jenisPenempatan;
  final String jumlahJamKerja;
  final DateTime waktuPosting;
  final String contactEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  LowonganModel({
    required this.id,
    required this.hrdYangPostId,
    this.hrd,
    required this.namaPerusahaan,
    required this.latitude,
    required this.longitude,
    required this.alamat,
    required this.deskripsiLowongan,
    required this.rentangGaji,
    required this.jenisPenempatan,
    required this.jumlahJamKerja,
    required this.waktuPosting,
    required this.contactEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LowonganModel.fromJson(Map<String, dynamic> json) {
    JenisPenempatan parseJenisPenempatan(String? type) {
      if (type == null) return JenisPenempatan.UNKNOWN;
      try {
        return JenisPenempatan.values.firstWhere((e) => e.name.toUpperCase() == type.toUpperCase());
      } catch (e) {
        return JenisPenempatan.UNKNOWN; // Default jika tidak ada yang cocok
      }
    }
    
    return LowonganModel(
      id: json['id'] as String,
      hrdYangPostId: json['hrd_yang_post_id'] as String,
      hrd: json['hrd'] != null ? User.fromJson(json['hrd'] as Map<String, dynamic>) : null,
      // hrd: null,
      namaPerusahaan: json['nama_perusahaan'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      alamat: json['alamat'] as String,
      deskripsiLowongan: json['deskripsi_lowongan'] as String,
      rentangGaji: json['rentang_gaji'] as String,
      jenisPenempatan: parseJenisPenempatan(json['jenisPenempatan'] as String?),
      jumlahJamKerja: json['jumlah_jam_kerja'] as String,
      waktuPosting: DateTime.parse(json['waktu_posting'] as String),
      contactEmail: json['contact_email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hrd_yang_post_id': hrdYangPostId,
      // 'hrd': hrd?.toJson(), // Hanya jika mengirim balik ke server
      'nama_perusahaan': namaPerusahaan,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
      'deskripsi_lowongan': deskripsiLowongan,
      'rentang_gaji': rentangGaji,
      'jenisPenempatan': jenisPenempatan.name, // Konversi enum ke string
      'jumlah_jam_kerja': jumlahJamKerja,
      'contact_email': contactEmail,
      // 'waktu_posting': waktuPosting.toIso8601String(), // Biasanya di-handle backend
      // 'createdAt': createdAt.toIso8601String(),
      // 'updatedAt': updatedAt.toIso8601String(),
    };
  }
}