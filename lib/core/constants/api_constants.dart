class ApiConstants {
  // Ganti dengan IP address lokal Anda jika menjalankan backend di mesin yang sama
  // dan menguji di emulator Android. Untuk iOS simulator dan device fisik,
  // gunakan IP address mesin di jaringan lokal.
  // Jika backend di-deploy, gunakan URL deployment.
  static const String baseUrl = 'https://loker-backend-948060519163.asia-southeast2.run.app/api'; // Default untuk Android Emulator ke localhost mesin
  // static const String baseUrl = 'http://localhost:3000/api'; // Jika tes di web atau iOS simulator
  // static const String baseUrl = 'http://YOUR_LOCAL_IP:3000/api'; // Jika tes di device fisik

  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String profileEndpoint = '/auth/me';
  static const String updateUserProfileEndpoint = '/users/profile';

  static const String lowonganEndpoint = '/lowongan';
  static const String kosEndpoint = '/kos';
}