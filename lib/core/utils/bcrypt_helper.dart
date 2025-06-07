import 'package:bcrypt/bcrypt.dart';

class BcryptHelper {
  // Fungsi ini melakukan hashing pada sebuah string menggunakan bcrypt.
  // Ini adalah operasi async untuk mencegah pemblokiran UI.
  static Future<String> hashPassword(String password) async {
    // Generate salt. Angka 10 adalah work factor (log_rounds).
    // Nilai antara 10-12 adalah standar yang baik untuk keamanan.
    final String salt = await BCrypt.gensalt(logRounds: 10);
    
    // Lakukan hashing pada password dengan salt yang sudah dibuat.
    final String hashedPassword = await BCrypt.hashpw(password, salt);

    return hashedPassword;
  }
  
  // Fungsi untuk memverifikasi (tidak akan kita gunakan di sini, tapi baik untuk diketahui)
  // static Future<bool> verifyPassword(String password, String hashedPassword) async {
  //   return await Bcrypt.checkpw(password, hashedPassword);
  // }
}