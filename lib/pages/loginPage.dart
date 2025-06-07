import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homePage.dart';
import '../services/userService.dart';
import 'registerPage.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false; 
  bool _obscurePassword = true; 

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    if (!mounted) return; 

    setState(() {
      _isLoading = true; 
    });

    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await UserService.loginUser(
        email: _usernameController.text.trim(), 
        password: _passwordController.text.trim(), 
      );

      if (!mounted) return; 

      if (response['status'] == 'success' && response['msg'] == 'Login berhasil') {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', _usernameController.text.trim()); 
        if (response['data'] != null && response['data']['id'] != null) {
          await prefs.setInt('userId', response['data']['id']);
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg'] ?? 'Login gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Login gagal. Terjadi kesalahan jaringan atau server.';
      if (e.toString().contains("Login failed:")) {
        try {
          final errorBody = e.toString().split("Login failed: ")[1];
          final decodedError = jsonDecode(errorBody);
          if (decodedError['msg'] != null) {
            errorMessage = decodedError['msg'];
          }
        } catch (_) {
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700, 
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), 
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 20), 
                    Text(
                      'Selamat Datang Kembali!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.green.shade800, 
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Silakan masuk untuk menjelajahi dunia fauna',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700), 
                    ),
                    const SizedBox(height: 36),
                    _buildTextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      labelText: 'Email',
                      hintText: 'Masukkan email Anda',
                      icon: Icons.alternate_email_outlined, 
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 20), 
                    _buildTextFormField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Masukkan password Anda',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, 
                      child: _buildLoginButton(),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Belum punya akun? Daftar di sini',
                        style: TextStyle(
                          color: Colors.green.shade700, 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.green.shade50, 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700, 
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), 
        ),
        elevation: 7, 
        shadowColor: Colors.orange.shade300,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 120,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Masuk',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}