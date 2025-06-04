import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homePage.dart';
import '../services/userService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await UserService.loginUser(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      // Periksa 'status' dan 'msg' dari respons backend
      if (response['status'] == 'success' &&
          response['msg'] == 'Login berhasil') {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', _usernameController.text);
        if (response['data'] != null && response['data']['id'] != null) {
          await prefs.setInt('userId', response['data']['id']);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Ini akan menangani kasus di mana status bukan 'success' atau msg tidak sesuai
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg'] ?? 'Login gagal. Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Tangani exception yang dilempar dari UserService (misalnya, status code bukan 200)
      String errorMessage = 'Login gagal. Silakan coba lagi.';
      if (e.toString().contains("Login failed:")) {
        // Coba parsing body respons error dari exception
        try {
          final errorBody = e.toString().split("Login failed: ")[1];
          final decodedError = jsonDecode(errorBody);
          if (decodedError['msg'] != null) {
            errorMessage = decodedError['msg'];
          }
        } catch (_) {
          // Jika parsing gagal, gunakan pesan default
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan login untuk melanjutkan',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator:
                          (value) => value!.isEmpty ? 'Masukkan email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Masukkan password' : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
