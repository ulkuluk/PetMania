import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transactionModel.dart';

class TransactionApi {
  static const url = "https://petmania-be-589948883802.us-central1.run.app"; 

  static Future<Map<String, dynamic>> getTransaction() async {
    final response = await http.get(Uri.parse("$url/transactions"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createTransaction(
    Transaction transaction,
  ) async {
    final response = await http.post(
      Uri.parse("$url/add-transaction"), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()), 
    );
    if (response.statusCode == 201 || response.statusCode == 200) { 
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create transaction: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> deleteTransaction(int id) async {
    final hasil = await http.delete(Uri.parse("$url/transactions/$id"));
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to delete transaction: ${hasil.statusCode} - ${hasil.body}');
    }
  }

  static Future<Map<String, dynamic>> getTransactionByBuyerEmail(String email) async { 
    final hasil = await http.get(Uri.parse("$url/transaction/$email")); 
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to get transactions by buyer email: ${hasil.statusCode} - ${hasil.body}');
    }
  }

  static Future<Map<String, dynamic>> updateTransactionById(
    Transaction transaction,
  ) async {
    final hasil = await http.put(
      Uri.parse("$url/transaction/${transaction.id}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()),
    );
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to update transaction: ${hasil.statusCode} - ${hasil.body}');
    }
  }
  static Future<Map<String, dynamic>> getTransactionByAnimalId(int animalId) async {
    final hasil = await http.get(Uri.parse("$url/transaction/animal/${animalId}"));
    
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to get transactions by animal ID: ${hasil.statusCode} - ${hasil.body}');
    }
  }

  
}