// services/transactionService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transactionModel.dart';

class TransactionApi {
  static const url = "http://10.0.2.2:5000"; // Pastikan ini alamat BE Anda

  static Future<Map<String, dynamic>> getTransaction() async {
    final response = await http.get(Uri.parse("$url/transactions"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createTransaction(
    Transaction transaction,
  ) async {
    final response = await http.post(
      Uri.parse("$url/add-transaction"), // Pastikan endpoint ini benar di BE
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()), // Menggunakan .toJson() dari model
    );
    if (response.statusCode == 201 || response.statusCode == 200) { // Cek status 201 Created atau 200 OK
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create transaction: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> deleteTransaction(int id) async {
    // Sesuaikan URL ini jika endpoint delete Anda berbeda (misal: /transactions/:id)
    final hasil = await http.delete(Uri.parse("$url/transactions/$id"));
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to delete transaction: ${hasil.statusCode} - ${hasil.body}');
    }
  }

  static Future<Map<String, dynamic>> getTransactionByBuyerEmail(String email) async { // Ubah id menjadi email
    // Sesuaikan URL ini jika endpoint get by email Anda berbeda
    final hasil = await http.get(Uri.parse("$url/transaction/$email")); // Contoh: /transactions/buyer/:email
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
      // Sesuaikan URL ini jika endpoint update Anda berbeda (misal: /transactions/:id)
      Uri.parse("$url/transaction/${transaction.id}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()), // Menggunakan .toJson() dari model
    );
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to update transaction: ${hasil.statusCode} - ${hasil.body}');
    }
  }
  static Future<Map<String, dynamic>> getTransactionByAnimalId(int animalId) async {
    // Sesuaikan URL ini dengan endpoint di backend Anda
    final hasil = await http.get(Uri.parse("$url/transaction/animal/${animalId}"));
    
    if (hasil.statusCode == 200) {
      return jsonDecode(hasil.body);
    } else {
      throw Exception('Failed to get transactions by animal ID: ${hasil.statusCode} - ${hasil.body}');
    }
  }

  
}