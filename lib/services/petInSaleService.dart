import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/petInSaleModel.dart';

class PetInSaleApi {
  static const url = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> getPetInSale() async {
    final response = await http.get(Uri.parse("$url/petinsales"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPetInSale(
    PetInSale petinsale,
  ) async {
    final response = await http.post(
      Uri.parse("$url/add-petinsale"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(petinsale),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deletePetInSale(int id) async {
    final hasil = await http.delete(Uri.parse("$url/$id"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> getPetInSaleByEmail(String email) async {
    final hasil = await http.get(Uri.parse("$url/petinsale/$email"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> updatePetInSaleStatus(
    int id,
    String status, // Hanya mengirim ID dan status yang ingin diupdate
  ) async {
    final hasil = await http.put(
      Uri.parse("$url/petinsale/buyed/$id"), // Mengarah ke endpoint baru
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "status": status, // Hanya mengirim status
      }),
    );

    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception(
        'Failed to update pet status: ${hasil.statusCode} - ${hasil.body}',
      );
    }
  }

  
}
