import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/lowongan_disimpan_model.dart';
import 'package:loker_kabur_aja_dulu/services/lowongan_service.dart';
import 'package:loker_kabur_aja_dulu/data/datasources/local/database_helper.dart';

class LowonganProvider with ChangeNotifier {
  final LowonganService _lowonganService = LowonganService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<LowonganModel> _allLowongan = [];
  List<LowonganModel> _filteredLowongan = [];
  LowonganModel? _selectedLowongan;
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Untuk status favorit
  Map<String, bool> _favoriteStatus = {}; // Map<lowonganId, isFavorite>

  List<LowonganModel> get allLowongan => _allLowongan;
  List<LowonganModel> get filteredLowongan => _filteredLowongan;
  LowonganModel? get selectedLowongan => _selectedLowongan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  Map<String, bool> get favoriteStatus => _favoriteStatus;

  // --- UNTUK HALAMAN FAVORIT ---
  List<LowonganDisimpanModel> _savedLowonganList = [];
  List<LowonganDisimpanModel> get savedLowonganList => _savedLowonganList;

  LowonganProvider() {
    // Mungkin tidak perlu fetch langsung di constructor jika halaman Lowongan tidak langsung aktif
    // fetchAllLowongan(); // Atau panggil dari UI saat halaman Lowongan pertama kali dimuat
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchAllLowongan({String? userIdForFavorites}) async {
    _setLoading(true);
    _setError(null);
    try {
      _allLowongan = await _lowonganService.getAllLowongan();
      _filteredLowongan = List.from(_allLowongan); // Salin ke list yang difilter
      if (userIdForFavorites != null) {
        await _loadFavoriteStatus(userIdForFavorites);
      }
    } catch (e) {
      _setError(e.toString());
      _allLowongan = [];
      _filteredLowongan = [];
    }
    _setLoading(false); // Pastikan ini dipanggil setelah semua operasi
  }

  Future<void> fetchLowonganById(String id, {String? userIdForFavorites}) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedLowongan = await _lowonganService.getLowonganById(id);
      if (userIdForFavorites != null && _selectedLowongan != null) {
        final isFav = await _dbHelper.isLowonganDisimpan(_selectedLowongan!.id, userIdForFavorites);
        _favoriteStatus[_selectedLowongan!.id] = isFav;
      }
    } catch (e) {
      _setError(e.toString());
      _selectedLowongan = null;
    }
    _setLoading(false);
  }
  
  void searchLowongan(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredLowongan = List.from(_allLowongan);
    } else {
      _filteredLowongan = _allLowongan.where((lowongan) {
        final titleMatch = lowongan.namaPerusahaan.toLowerCase().contains(query.toLowerCase());
        final descMatch = lowongan.deskripsiLowongan.toLowerCase().contains(query.toLowerCase());
        final addressMatch = lowongan.alamat.toLowerCase().contains(query.toLowerCase());
        return titleMatch || descMatch || addressMatch;
      }).toList();
    }
    notifyListeners();
  }

  // --- Manajemen Favorit ---
  Future<void> _loadFavoriteStatus(String userId) async {
    _favoriteStatus.clear();
    for (var lowongan in _allLowongan) {
      final isFav = await _dbHelper.isLowonganDisimpan(lowongan.id, userId);
      _favoriteStatus[lowongan.id] = isFav;
    }
    // Tidak perlu notifyListeners() di sini jika fetchAllLowongan akan memanggilnya di akhir
  }

  bool isFavorite(String lowonganId) {
    return _favoriteStatus[lowonganId] ?? false;
  }

  Future<void> toggleFavorite(LowonganModel lowongan, String userId) async {
    if (userId.isEmpty) {
      // Handle kasus jika user ID tidak ada (misal, user belum login)
      // Mungkin tampilkan pesan untuk login terlebih dahulu
      print("User ID kosong, tidak bisa menyimpan favorit.");
      _setError("Anda harus login untuk menyimpan favorit.");
      notifyListeners();
      return;
    }

    print("Berhasil jalan toogle favorites");
    final lowonganId = lowongan.id;
    final currentStatus = isFavorite(lowonganId);
    
    try {
      if (currentStatus) {
        await _dbHelper.hapusLowonganDisimpan(lowonganId, userId);
        _favoriteStatus[lowonganId] = false;
      } else {
        final lowonganToSave = LowonganDisimpanModel.fromLowonganAPI(lowongan, userId);
        await _dbHelper.simpanLowongan(lowonganToSave);
        _favoriteStatus[lowonganId] = true;
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling favorite: $e");
      print("Error toggling favorite untuk lowongan ID $lowonganId: $e");
      _setError("Gagal mengubah status favorit: ${e.toString()}");
      // Kembalikan status ke semula jika gagal, atau biarkan UI menunggu update berikutnya
      // _favoriteStatus[lowonganId] = currentStatus; 
      notifyListeners();
      // Mungkin perlu handle error di UI
    }
  }

  Future<void> fetchSavedLowongan(String userId) async {
    if (userId.isEmpty) {
      _savedLowonganList = [];
      notifyListeners();
      return;
    }
    _setLoading(true); // Mungkin perlu state loading terpisah untuk halaman favorit
    _setError(null);
    try {
      _savedLowonganList = await _dbHelper.getLowonganDisimpan(userId);
    } catch (e) {
      _setError("Gagal memuat lowongan disimpan: ${e.toString()}");
      _savedLowonganList = [];
    }
    _setLoading(false); // Atau state loading terpisah
  }

   Future<void> unfavoriteLowonganById(String lowonganId, String userId, Function onDone) async {
    if (userId.isEmpty) return;
    try {
      await _dbHelper.hapusLowonganDisimpan(lowonganId, userId);
      _favoriteStatus[lowonganId] = false; // Update status di provider utama
      await fetchSavedLowongan(userId); // Refresh daftar saved di sini
      notifyListeners(); // Notify semua listener termasuk yang di LowonganScreen/DetailScreen
      onDone(); // Callback untuk UI di FavoritesScreen
    } catch (e) {
      print("Error unfavoriting lowongan by ID $lowonganId: $e");
      _setError("Gagal menghapus favorit: ${e.toString()}");
      notifyListeners();
    }
  }

  // --- Metode CRUD untuk HRD (akan diisi nanti) ---
  Future<bool> createLowongan(Map<String, dynamic> data, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _lowonganService.createLowongan(data, token);
      await fetchAllLowongan(userIdForFavorites: userIdForFavorites); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateLowongan(String id, Map<String, dynamic> data, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _lowonganService.updateLowongan(id, data, token);
      await fetchAllLowongan(userIdForFavorites: userIdForFavorites); // Refresh list
      if (_selectedLowongan?.id == id) { // Jika yang diupdate adalah yang sedang dilihat detailnya
        await fetchLowonganById(id, userIdForFavorites: userIdForFavorites);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteLowongan(String id, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _lowonganService.deleteLowongan(id, token);
      await fetchAllLowongan(userIdForFavorites: userIdForFavorites); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}