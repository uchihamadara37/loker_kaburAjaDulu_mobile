import 'dart:convert';
import 'dart:io'; // Untuk MultipartFile
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/api_constants.dart';
import 'package:loker_kabur_aja_dulu/data/models/user_model.dart'; // Akan kita buat
import 'package:loker_kabur_aja_dulu/services/token_service.dart';

class AuthService {
  final TokenService _tokenService = TokenService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    print("aksi login service dijalankan");
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final token = responseData['token'] as String;
        final userMap = responseData['data'] as Map<String, dynamic>;
        print("User login map ${userMap}");
        final user = User.fromJson(userMap); // Asumsi User model punya fromJson

        await _tokenService.saveToken(token);
        await _tokenService.saveUserRole(user.role);
        await _tokenService.saveUserId(user.id);
        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Login failed'};
      }
    } catch (error) {
      print('Login error: $error');
      return {'success': false, 'message': 'An error occurred: ${error.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    String? linkLinkedIn,
    String? role, // 'HRD' atau 'USER_BIASA'
    File? fotoProfile, // File gambar untuk foto profil
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.registerEndpoint);
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['nama'] = nama;
      request.fields['email'] = email;
      request.fields['password'] = password;
      if (linkLinkedIn != null) request.fields['linkLinkedIn'] = linkLinkedIn;
      if (role != null) request.fields['role'] = role;

      if (fotoProfile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_profile', // Sesuai dengan nama field di backend (upload.middleware.js)
            fotoProfile.path,
          ),
        );
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Registrasi berhasil, mungkin tidak mengembalikan token, user perlu login
        return {'success': true, 'message': responseData['message'] ?? 'Registration successful'};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registration failed'};
      }
    } catch (error) {
      print('Register error: $error');
      return {'success': false, 'message': 'An error occurred: ${error.toString()}'};
    }
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
  }

  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  Future<String?> getUserRole() async {
    return await _tokenService.getUserRole();
  }
   Future<String?> getUserId() async {
    return await _tokenService.getUserId();
  }

  // Mendapatkan detail user yang sedang login
  Future<User?> getMe() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.profileEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return User.fromJson(responseData);
      } else {
        print('GetMe failed: ${response.body}');
        return null;
      }
    } catch (error) {
      print('GetMe error: $error');
      return null;
    }
  }
}