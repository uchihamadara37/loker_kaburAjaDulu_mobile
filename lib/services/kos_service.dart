import 'dart:convert';
import 'dart:io'; // Untuk File jika nanti ada upload
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/api_constants.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';
// import 'package:loker_kabur_aja_dulu/services/token_service.dart'; // Untuk token jika diperlukan

class KosService {
  // final TokenService _tokenService = TokenService();

  Future<List<KosModel>> getAllKos() async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.kosEndpoint);
    try {
      final response = await http.get(url);
      print("getAllKos status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Hasil: ${response.body}");
        final List<dynamic> responseData = json.decode(response.body);
        print("lolos allKos dynamic");
        return responseData.map((json) => KosModel.fromJson(json)).toList();
      } else {
        print('Failed to load kos: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load kos (${response.statusCode})');
      }
    } catch (error) {
      print('Error fetching all kos: $error');
      throw Exception('Error fetching kos: $error');
    }
  }

  Future<KosModel> getKosById(String id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.kosEndpoint}/$id');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        return KosModel.fromJson(responseData);
      } else {
        print('Failed to load kos by ID $id: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load kos by ID (${response.statusCode})');
      }
    } catch (error) {
      print('Error fetching kos by ID $id: $error');
      throw Exception('Error fetching kos by ID: $error');
    }
  }

  // --- Metode untuk HRD (CRUD) akan ditambahkan di sini nanti ---
  Future<KosModel> createKos(Map<String, dynamic> dataKos, File? fotoKosFile, String token) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.kosEndpoint);
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan field teks
      dataKos.forEach((key, value) {
        if (value is List) { // Untuk fasilitas (array of strings)
          for (int i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      // Tambahkan file foto jika ada
      if (fotoKosFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_kos', // Nama field di backend
            fotoKosFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        return KosModel.fromJson(json.decode(response.body)['data']);
      } else {
        print('Failed to create kos: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create kos (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error creating kos: $error');
      throw Exception('Error creating kos: $error');
    }
  }
  
  Future<KosModel> updateKos(String id, Map<String, dynamic> dataKos, File? fotoKosFile, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.kosEndpoint}/$id');
     try {
      var request = http.MultipartRequest('PUT', url); // Method PUT untuk update
      request.headers['Authorization'] = 'Bearer $token';

      dataKos.forEach((key, value) {
         if (value is List) {
          for (int i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      if (fotoKosFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_kos', fotoKosFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return KosModel.fromJson(json.decode(response.body)['data']);
      } else {
        print('Failed to update kos: ${response.statusCode} ${response.body}');
        throw Exception('Failed to update kos (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error updating kos: $error');
      throw Exception('Error updating kos: $error');
    }
  }

  Future<void> deleteKos(String id, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.kosEndpoint}/$id');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        print('Failed to delete kos: ${response.statusCode} ${response.body}');
        throw Exception('Failed to delete kos (${response.statusCode}) - ${json.decode(response.body)['message']}');
      }
    } catch (error) {
      print('Error deleting kos: $error');
      throw Exception('Error deleting kos: $error');
    }
  }
}