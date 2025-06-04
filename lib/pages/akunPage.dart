import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userService.dart'; // Pastikan path ini benar
import '../models/userModel.dart'; // Jika Anda punya model User, pastikan path ini benar
import 'loginPage.dart'; // Import LoginPage untuk navigasi logout

class AkunPage extends StatefulWidget {
  const AkunPage({Key? key}) : super(key: key);

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  User? _user; // Variabel untuk menyimpan data user
  bool _isLoading = true; // Untuk menunjukkan status loading

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Panggil fungsi untuk memuat data user
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Mulai loading
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userEmail = prefs.getString('username'); // Mengambil email yang disimpan saat login

      if (userEmail != null) {
        
        final int? userId = prefs.getInt('userId'); // Asumsi userId disimpan saat login
        if (userId != null) {
          final response = await UserService.getUserById(userId);
          if (response['status'] == 'success' && response['data'] != null) {
            _user = User.fromJson(response['data']); // Sesuaikan jika struktur User model berbeda
          } else {
            _showSnackBar('Gagal memuat data user: ${response['msg'] ?? 'Tidak diketahui'}', Colors.redAccent);
          }
        } else {
          _showSnackBar('User ID tidak ditemukan. Harap login ulang.', Colors.orangeAccent);
        }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat memuat data: $e', Colors.redAccent);
      print('Error loading user data: $e'); // Untuk debugging
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Set status login menjadi false
    await prefs.remove('username'); // Hapus username
    await prefs.remove('userId'); // Hapus userId jika disimpan
    // await prefs.remove('userData'); // Hapus data user jika disimpan

    // Panggil logout dari backend (jika ada)
    try {
      await UserService.logout(); // Panggil fungsi logout di UserService
    } catch (e) {
      print('Error saat logout dari backend: $e');
      // Anda bisa menampilkan SnackBar di sini jika perlu
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil( // Kembali ke LoginPage dan hapus semua rute sebelumnya
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator()) // Tampilkan loading indicator
        : _user == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Gagal memuat data user atau user tidak ditemukan.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nama: ${_user!.name ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${_user!.email ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Telepon: ${_user!.phone ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent, // Warna merah untuk tombol logout
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
  }
}