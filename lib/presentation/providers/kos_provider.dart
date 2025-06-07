import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_disimpan_model.dart';
import 'package:loker_kabur_aja_dulu/services/kos_service.dart';
import 'package:loker_kabur_aja_dulu/data/datasources/local/database_helper.dart';
import 'dart:io'; // Untuk File

class KosProvider with ChangeNotifier {
  final KosService _kosService = KosService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<KosModel> _allKos = [];
  List<KosModel> _filteredKos = [];
  KosModel? _selectedKos;
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  Map<String, bool> _favoriteStatus = {}; // Map<kosId, isFavorite>

  List<KosModel> get allKos => _allKos;
  List<KosModel> get filteredKos => _filteredKos;
  KosModel? get selectedKos => _selectedKos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // --- UNTUK HALAMAN FAVORIT ---
  List<KosDisimpanModel> _savedKosList = [];
  List<KosDisimpanModel> get savedKosList => _savedKosList;

  
  void _setLoading(bool loading) {
    if (_isLoading == loading && !_isLoading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  Future<void> fetchAllKos({String? userIdForFavorites}) async {
    print("provider getAllKos jalan");
    _setLoading(true);
    _setError(null);
    try {
      _allKos = await _kosService.getAllKos();
      _filteredKos = List.from(_allKos);
      if (userIdForFavorites != null && userIdForFavorites.isNotEmpty) {
        await _loadFavoriteStatusForAll(userIdForFavorites);
      } else {
        _favoriteStatus.clear();
      }
    } catch (e) {
      _setError(e.toString());
      _allKos = [];
      _filteredKos = [];
      _favoriteStatus.clear();
    }
    _setLoading(false);
  }

  Future<void> fetchKosById(String id, {String? userIdForFavorites}) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedKos = await _kosService.getKosById(id);
      if (userIdForFavorites != null && userIdForFavorites.isNotEmpty && _selectedKos != null) {
        final isFav = await _dbHelper.isKosDisimpan(_selectedKos!.id, userIdForFavorites);
        _favoriteStatus[_selectedKos!.id] = isFav;
      }
    } catch (e) {
      _setError(e.toString());
      _selectedKos = null;
    }
    _setLoading(false);
  }
  
  void searchKos(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredKos = List.from(_allKos);
    } else {
      _filteredKos = _allKos.where((kos) {
        final nameMatch = kos.namaKos.toLowerCase().contains(query.toLowerCase());
        final addressMatch = kos.alamat.toLowerCase().contains(query.toLowerCase());
        final descMatch = kos.deskripsi.toLowerCase().contains(query.toLowerCase());
        return nameMatch || addressMatch || descMatch;
      }).toList();
    }
    notifyListeners();
  }

  // --- Manajemen Favorit Kos ---
  Future<void> _loadFavoriteStatusForAll(String userId) async {
    for (var kos in _allKos) {
      final isFav = await _dbHelper.isKosDisimpan(kos.id, userId);
      _favoriteStatus[kos.id] = isFav;
    }
  }

  bool isKosFavorite(String kosId) {
    return _favoriteStatus[kosId] ?? false;
  }

  Future<void> toggleKosFavorite(KosModel kos, String userId) async {
    if (userId.isEmpty) {
      _setError("Anda harus login untuk menyimpan favorit.");
      notifyListeners();
      return;
    }
    final kosId = kos.id;
    final currentStatus = isKosFavorite(kosId);
    try {
      if (currentStatus) {
        await _dbHelper.hapusKosDisimpan(kosId, userId);
        _favoriteStatus[kosId] = false;
      } else {
        final kosToSave = KosDisimpanModel.fromKosAPI(kos, userId);
        await _dbHelper.simpanKos(kosToSave);
        _favoriteStatus[kosId] = true;
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling Kos favorite for ID $kosId: $e");
      _setError("Gagal mengubah status favorit Kos: ${e.toString()}");
      notifyListeners();
    }
  }

  Future<void> fetchSavedKos(String userId) async {
    if (userId.isEmpty) {
      _savedKosList = [];
      notifyListeners();
      return;
    }
    _setLoading(true); // Mungkin perlu state loading terpisah
    _setError(null);
    try {
      _savedKosList = await _dbHelper.getKosDisimpan(userId);
    } catch (e) {
      _setError("Gagal memuat kos disimpan: ${e.toString()}");
      _savedKosList = [];
    }
    _setLoading(false); // Atau state loading terpisah
  }

  Future<void> unfavoriteKosById(String kosId, String userId, Function onDone) async {
    if (userId.isEmpty) return;
    try {
      await _dbHelper.hapusKosDisimpan(kosId, userId);
      _favoriteStatus[kosId] = false; // Update status di provider utama
      await fetchSavedKos(userId); // Refresh daftar saved di sini
      notifyListeners(); // Notify semua listener
      onDone(); // Callback untuk UI di FavoritesScreen
    } catch (e) {
      print("Error unfavoriting kos by ID $kosId: $e");
      _setError("Gagal menghapus favorit: ${e.toString()}");
      notifyListeners();
    }
  }
  
  // --- Metode CRUD Kos untuk HRD ---
  Future<bool> createKos(Map<String, dynamic> data, File? fotoKosFile, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _kosService.createKos(data, fotoKosFile, token);
      await fetchAllKos(userIdForFavorites: userIdForFavorites);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateKos(String id, Map<String, dynamic> data, File? fotoKosFile, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _kosService.updateKos(id, data, fotoKosFile, token);
      await fetchAllKos(userIdForFavorites: userIdForFavorites);
      if (_selectedKos?.id == id) {
        await fetchKosById(id, userIdForFavorites: userIdForFavorites);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteKos(String id, String token, String userIdForFavorites) async {
    _setLoading(true);
    _setError(null);
    try {
      await _kosService.deleteKos(id, token);
      await fetchAllKos(userIdForFavorites: userIdForFavorites);
      _selectedKos = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}