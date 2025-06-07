import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/google_constants.dart'; // Mengambil API Key dari sini

class CurrencyService {
  final String _baseUrl = 'https://api.freecurrencyapi.com/v1/latest';

  // Mendapatkan nilai tukar dari satu mata uang dasar ke beberapa mata uang target
  // Contoh: baseCurrency = 'USD', targetCurrencies = ['IDR', 'JPY']
  // Akan mengembalikan Map seperti {'IDR': 16000.0, 'JPY': 150.0}
  Future<Map<String, dynamic>> getConversionRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    if (freeCurrencyApiKey.isEmpty) {
      throw Exception('FreeCurrencyAPI Key belum diatur.');
    }

    final url = Uri.parse('$_baseUrl?apikey=$freeCurrencyApiKey&base_currency=$baseCurrency&currencies=${targetCurrencies.join(',')}');
    
    print("Fetching currency rates: $url");

    try {
      final response = await http.get(url);
      print("");
      if (response.statusCode == 200) {
          print("okokok");
        final Map<String, dynamic> data = json.decode(response.body);
          print("okokok2 ${data}");
        if (data.containsKey('data')) {
          // API mengembalikan data dalam format Map<String, dynamic>, kita konversi ke Map<String, double>
          print("okokok3");
          final rates = Map<String, dynamic>.from(data['data']);
          return rates;
        } else {
          throw Exception('Format respons API tidak valid: ${data['message']}');
        }
      } else {
        throw Exception('Gagal memuat kurs mata uang: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error di CurrencyService: $e');
      // Lemparkan kembali error agar bisa ditangani di UI
      rethrow;
    }
  }
}