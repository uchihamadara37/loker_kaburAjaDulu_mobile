import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/datasources/local/database_helper.dart';
import 'package:loker_kabur_aja_dulu/data/models/saldo_user_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_dipesan_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart'; // Untuk data Kos API

class AccountProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  SaldoUserModel? _currentUserSaldo;
  List<KosDipesanModel> _bookedKosList = [];
  bool _isLoadingSaldo = false;
  bool _isLoadingBookedKos = false;
  bool _isProcessingBooking = false; // State untuk proses booking
  bool _isProcessingTopUp = false;
  String? _errorMessage;

  SaldoUserModel? get currentUserSaldo => _currentUserSaldo;
  List<KosDipesanModel> get bookedKosList => _bookedKosList;
  bool get isLoadingSaldo => _isLoadingSaldo;
  bool get isLoadingBookedKos => _isLoadingBookedKos;
  bool get isProcessingBooking => _isProcessingBooking;
  bool get isProcessingTopUp => _isProcessingTopUp;
  String? get errorMessage => _errorMessage;

  void _setError(String? message) {
    _errorMessage = message;
    // notifyListeners(); // Panggil jika ada UI yang langsung menampilkan error ini
  }

  Future<void> fetchCurrentUserSaldo(String userId) async {
    if (userId.isEmpty) {
      _currentUserSaldo = null; // Atau SaldoUserModel(userId: '', saldo: 0) jika perlu placeholder
      notifyListeners();
      return;
    }
    _isLoadingSaldo = true;
    _setError(null);
    notifyListeners();
    try {
      _currentUserSaldo = await _dbHelper.getSaldoUser(userId);
      // Jika null (user baru), _dbHelper.getSaldoUser akan membuat entry baru dengan saldo 0
      _currentUserSaldo ??= SaldoUserModel(userId: userId, saldo: 0);
    } catch (e) {
      _setError("Gagal memuat saldo: ${e.toString()}");
      _currentUserSaldo = SaldoUserModel(userId: userId, saldo: 0); // Default jika error
    }
    _isLoadingSaldo = false;
    notifyListeners();
  }

  Future<void> fetchBookedKos(String userId) async {
     if (userId.isEmpty) {
      _bookedKosList = [];
      notifyListeners();
      return;
    }
    _isLoadingBookedKos = true;
    _setError(null);
    notifyListeners();
    try {
      _bookedKosList = await _dbHelper.getKosDipesan(userId);
    } catch (e) {
      _setError("Gagal memuat daftar kos dipesan: ${e.toString()}");
      _bookedKosList = [];
    }
    _isLoadingBookedKos = false;
    notifyListeners();
  }

  // Simulasi Top Up Saldo
  Future<bool> topUpSaldo(String userId, double amount) async {
    if (userId.isEmpty || amount <= 0) {
      _setError("Jumlah top up tidak valid.");
      notifyListeners();
      return false;
    }
    _isProcessingTopUp = true;
    _setLoading(true); // Menggunakan _isLoading umum atau buat _isProcessingTopUp
    _setError(null);
    try {
      await _dbHelper.updateSaldoUser(userId, amount); // Menambah saldo
      await fetchCurrentUserSaldo(userId); // Refresh saldo
      _isProcessingTopUp = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal melakukan top up: ${e.toString()}");
      _isProcessingTopUp = true;
      _setLoading(false);
      return false;
    }
  }

  // Proses Booking dan Pembayaran DP (Simulasi)
  Future<Map<String, dynamic>> processBookingAndPayDp(
      String userId, KosModel kosItem, double finalAmountInIDR) async {
    if (userId.isEmpty) return {'success': false, 'message': 'User tidak valid.'};
    if (finalAmountInIDR <= 0) return {'success': false, 'message': 'Jumlah pembayaran tidak valid.'};

    _isProcessingBooking = true;
    _setError(null);
    notifyListeners();

    try {
      final SaldoUserModel? saldoSaatIni = await _dbHelper.getSaldoUser(userId);
      _currentUserSaldo = saldoSaatIni ?? SaldoUserModel(userId: userId, saldo: 0);
      
      if (_currentUserSaldo!.saldo < finalAmountInIDR) {
        _isProcessingBooking = false;
        notifyListeners();
        return {'success': false, 'message': 'Saldo tidak mencukupi. Saldo Anda: Rp ${_currentUserSaldo!.saldo.toStringAsFixed(0)}, dibutuhkan: Rp ${finalAmountInIDR.toStringAsFixed(0)}.'};
      }

      // Langsung kurangi saldo dengan jumlah IDR yang sudah dikonversi
      await _dbHelper.updateSaldoUser(userId, -finalAmountInIDR);

      // Catat Kos Dipesan. hargaDpDibayar sekarang adalah nilai dalam IDR.
      // Anda mungkin ingin menyimpan juga mata uang asli dan jumlah aslinya di sini.
      // Untuk itu, Anda perlu memodifikasi model KosDipesanModel dan tabelnya.
      // Untuk sekarang, kita simpan nilai IDR-nya.
      final pesanan = KosDipesanModel.fromKosAPI(kosItem, userId, finalAmountInIDR);
      await _dbHelper.pesanKos(pesanan);
      
      await fetchCurrentUserSaldo(userId);
      await fetchBookedKos(userId);
      
      _isProcessingBooking = false;
      notifyListeners();
      return {'success': true, 'message': 'Pemesanan dan pembayaran DP berhasil!'};

    } catch (e) {
      _setError("Gagal memproses pemesanan: ${e.toString()}");
      _isProcessingBooking = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }
  
  // Helper untuk loading umum jika diperlukan
  void _setLoading(bool loading) {
    _isLoadingSaldo = loading; // Atau flag loading yang lebih general
    notifyListeners();
  }
}