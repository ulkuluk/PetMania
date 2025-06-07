import 'package:flutter/material.dart';
import '../models/userModel.dart'; 
import '../services/userService.dart'; 
import '../pages/loginPage.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; 
  String? _errorMessage; 
  bool _obscurePassword = true; 

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null; 
      });

      try {
        final User newUser = User(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final Map<String, dynamic> response =
            await UserService.createUser(newUser);

        if (!mounted) return; 

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green.shade700, 
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          setState(() {
            _errorMessage = response['msg'] ?? 'Registrasi gagal.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
        print('Error during registration: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Akun Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0), 
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'PetMania',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800, 
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Buat akun untuk memulai petualanganmu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap Anda',
                icon: Icons.person_outline, 
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (value.length > 254) {
                    return 'Nama tidak boleh lebih dari 254 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email',
                hintText: 'contoh@domain.com',
                icon: Icons.email_outlined, 
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (value.length > 254) {
                    return 'Email tidak boleh lebih dari 254 karakter';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Masukkan format email yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                labelText: 'Nomor Telepon',
                hintText: 'contoh: 081234567890',
                icon: Icons.phone_outlined, 
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                   if (value.length > 254) {
                    return 'Nomor telepon tidak boleh lebih dari 254 karakter';
                  }
                  if (!RegExp(r'^[0-9+ ]+$').hasMatch(value)) {
                    return 'Masukkan angka, +, atau spasi yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Minimal 6 karakter',
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
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  if (value.length > 254) {
                    return 'Password tidak boleh lebih dari 254 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildRegisterButton(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: Text(
                  'Sudah punya akun? Login di sini',
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
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerUser, 
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
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Daftar Sekarang',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}