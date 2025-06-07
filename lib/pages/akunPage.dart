import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../services/userService.dart';
import '../models/userModel.dart';
import 'loginPage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({Key? key}) : super(key: key);

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  User? _user;
  bool _isLoading = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userEmail = prefs.getString('username');

      if (userEmail != null) {
        final int? userId = prefs.getInt('userId');
        if (userId != null) {
          final response = await UserService.getUserById(userId);
          if (response['status'] == 'success' && response['data'] != null) {
            _user = User.fromJson(response['data']);
          } else {
            _showSnackBar('Gagal memuat data user: ${response['msg'] ?? 'Tidak diketahui'}', Colors.redAccent);
          }
        } else {
          _showSnackBar('User ID tidak ditemukan. Harap login ulang.', Colors.orangeAccent);
        }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat memuat data: $e', Colors.redAccent);
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final userBox = Hive.box('userBox');
    final String? imagePath = userBox.get('profileImagePath');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final File localImage = await File(image.path).copy('${appDir.path}/$fileName');

      final userBox = Hive.box('userBox');
      await userBox.put('profileImagePath', localImage.path);

      setState(() {
        _profileImage = localImage;
      });
      _showSnackBar('Gambar profil berhasil diupload!', Color(0xFF6D9F71)); 
    } else {
      _showSnackBar('Tidak ada gambar yang dipilih.', Colors.orangeAccent);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('userId');

    final userBox = Hive.box('userBox');
    final String? imagePath = userBox.get('profileImagePath');
    if (imagePath != null && File(imagePath).existsSync()) {
      try {
        await File(imagePath).delete();
        print('Gambar profil lokal berhasil dihapus.');
      } catch (e) {
        print('Gagal menghapus gambar profil lokal: $e');
      }
    }
    await userBox.delete('profileImagePath');

    try {
      await UserService.logout();
    } catch (e) {
      print('Error saat logout dari backend: $e');
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSaranKesanInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xFFF0F4C3),
          title: const Text(
            'Saran & Kesan Mata Kuliah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: Color(0xFF333333), 
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kesan: Mata kuliah Teknologi dan Pemrograman Mobile sangat menarik dan relevan dengan perkembangan teknologi saat ini. Materi yang disampaikan mudah dipahami dan praktikumnya membantu dalam mengaplikasikan teori. Saya sangat menikmati setiap sesi perkuliahan.\n\n',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: Color(0xFF555555)),
                ),
                Text(
                  'Saran: Akan lebih baik jika ada lebih banyak contoh studi kasus atau proyek mini yang dapat dikerjakan secara berkelompok untuk meningkatkan kolaborasi dan pengalaman riil dalam pengembangan aplikasi mobile.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6D9F71), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              child: const Text('Tutup', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6D9F71)))
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Gagal memuat data user atau user tidak ditemukan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontFamily: 'Montserrat', color: Color(0xFF555555)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadUserData,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFA5D6A7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA5D6A7).withOpacity(0.3),
                            border: Border.all(
                              color: Color(0xFF6D9F71), 
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58, 
                            backgroundColor: Colors.transparent, 
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(Icons.pets, size: 70, color: Color(0xFF6D9F71)) 
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), 
                      Text(
                        _user!.name ?? 'Pengguna',
                        style: const TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        _user!.email ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.grey[700],
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 32), 

                      Card(
                        elevation: 6, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), 
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.email, 'Email', _user!.email ?? 'N/A'),
                              const Divider(height: 30, thickness: 1.5, color: Color(0xFFE0E0E0)),
                              _buildInfoRow(Icons.phone, 'Telepon', _user!.phone ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), 

                      ListTile(
                        leading: const Icon(Icons.feedback, color: Color(0xFF6D9F71), size: 28), 
                        title: const Text('Saran & Kesan Mata Kuliah', style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', color: Color(0xFF333333))),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF6D9F71)), 
                        onTap: _showSaranKesanInfoDialog,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), 
                          side: BorderSide(color: Color(0xFFA5D6A7), width: 1.5),
                        ),
                        tileColor: Color(0xFFF9FBE7), 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
                      ),
                      const SizedBox(height: 32), 

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white, size: 24), 
                          label: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15), 
                            ),
                            elevation: 8, 
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF6D9F71), size: 28),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}