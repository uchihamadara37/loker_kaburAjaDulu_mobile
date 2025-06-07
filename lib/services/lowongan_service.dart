import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/api_constants.dart';
import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart';
import 'package:loker_kabur_aja_dulu/services/token_service.dart'; // Untuk mengambil token jika diperlukan

class LowonganService {
  final TokenService _tokenService = TokenService();

  Future<List<LowonganModel>> getAllLowongan() async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.lowonganEndpoint);
    print("URL ${url}");
    try {
      final response = await http.get(url);
      print("status code : ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        print("Lowongan yang terambil : ${responseData.first}");
        return responseData.map((json) => LowonganModel.fromJson(json)).toList();
      } else {
        // Handle error, misalnya dengan melempar exception atau mengembalikan list kosong
        print('Failed to load lowongan: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load lowongan (${response.statusCode})');
      }
    } catch (error) {
      print('Error fetching all lowongan: $error');
      throw Exception('Error fetching lowongan: $error');
    }
  }

  Future<LowonganModel> getLowonganById(String id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.lowonganEndpoint}/$id');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        return LowonganModel.fromJson(responseData);
      } else {
        print('Failed to load lowongan by ID $id: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load lowongan by ID (${response.statusCode})');
      }
    } catch (error) {
      print('Error fetching lowongan by ID $id: $error');
      throw Exception('Error fetching lowongan by ID: $error');
    }
  }

  // --- Metode untuk HRD (CRUD) akan ditambahkan di sini nanti ---
  // Contoh: createLowongan, updateLowongan, deleteLowongan
  // Metode ini akan memerlukan token otentikasi
  Future<LowonganModel> createLowongan(Map<String, dynamic> dataLowongan, String token) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.lowonganEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dataLowongan),
      );
      print("add loker status code: ${response.statusCode}");

      if (response.statusCode == 201) {
        return LowonganModel.fromJson(json.decode(response.body)['data']);
      } else {
        print('Failed to create lowongan: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create lowongan (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error creating lowongan: $error');
      throw Exception('Error creating lowongan: $error');
    }
  }
  
  Future<LowonganModel> updateLowongan(String id, Map<String, dynamic> dataLowongan, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.lowonganEndpoint}/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dataLowongan),
      );

      print("update loker status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        return LowonganModel.fromJson(json.decode(response.body)['data']);
      } else {
         print('Failed to update lowongan: ${response.statusCode} ${response.body}');
        throw Exception('Failed to update lowongan (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error updating lowongan: $error');
      throw Exception('Error updating lowongan: $error');
    }
  }

  Future<void> deleteLowongan(String id, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.lowonganEndpoint}/$id');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) { // 204 No Content juga bisa jadi sukses
         print('Failed to delete lowongan: ${response.statusCode} ${response.body}');
        throw Exception('Failed to delete lowongan (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error deleting lowongan: $error');
      throw Exception('Error deleting lowongan: $error');
    }
  }
}