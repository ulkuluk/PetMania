import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/petInSaleModel.dart';

class PetInSaleApi {
  static const url = "https://petmania-be-589948883802.us-central1.run.app";

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
    final hasil = await http.delete(Uri.parse("$url/petinsale/delete/$id"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> getPetInSaleByEmail(String email) async {
    final hasil = await http.get(Uri.parse("$url/petinsale/$email"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> updatePetInSaleStatus(
    int id,
    String status, 
  ) async {
    final hasil = await http.put(
      Uri.parse("$url/petinsale/buyed/$id"), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "status": status, 
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

  static Future<Map<String, dynamic>> getPetInSaleById(int petId) async {
    try {
      final response = await http.get(Uri.parse('$url/petinsale/id/$petId')); 

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);
        if (fullResponse['status'] == 'success' && fullResponse['data'] != null) {
          if (fullResponse['data'] is Map<String, dynamic>) {
            return fullResponse['data']; 
          } else {
            print('Warning: Backend returned non-Map for pet detail data: ${fullResponse['data'].runtimeType}');
            throw Exception('Data hewan tidak dalam format yang diharapkan (bukan objek).');
          }
        } else {
          return {'error': fullResponse['msg'] ?? 'Gagal mengambil detail hewan.'};
        }
      } else {
        return {'error': 'Failed to load pet detail. Status code: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Error fetching pet detail: $e'};
    }
  }
  static Future<Map<String, dynamic>> updateFullPetInSale(
    PetInSale pet,
  ) async {
    if (pet.id == null) {
      throw Exception('Pet ID cannot be null for update operation.');
    }

    final response = await http.put(
      Uri.parse("$url/petinsale/update/${pet.id}"), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pet.toJson()), 
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Failed to update pet: ${response.statusCode} - ${errorBody['msg'] ?? 'Unknown error'}',
      );
    }
  }
}