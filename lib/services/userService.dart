import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/userModel.dart';

class UserService {
  static const String url = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> getUsers() async {
    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createUser(User user) async {
    final response = await http.post(
      Uri.parse("$url/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    final hasil = await http.delete(Uri.parse("$url/$id"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    final hasil = await http.get(Uri.parse("$url/users/$id"));
    return jsonDecode(hasil.body);
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$url/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Kamu bisa melempar exception atau return error map
      throw Exception("Login failed: ${response.body}");
    }
  }
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.delete(
      Uri.parse("$url/logout"),
      headers: {'Content-Type': 'application/json'},
    );
    // Asumsi backend merespons 200 OK untuk logout
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Logout failed: ${response.body}");
    }
  }
}

