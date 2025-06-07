import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'package:path_provider/path_provider.dart'; // Import path_provider
import '../pages/homePage.dart';
import '../pages/loginPage.dart';
import '../models/favoritePetModel.dart'; // Import model favorit Anda

void main() async { // Ubah menjadi async
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding diinisialisasi

  // Inisialisasi Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  // Daftarkan adapter untuk model FavoritePet Anda
  // Pastikan Anda sudah menjalankan 'dart run build_runner build'
  // agar file favoritePetModel.g.dart terbuat
  Hive.registerAdapter(FavoritePetAdapter());

  // Buka box untuk favorit. Ini akan membuat box jika belum ada.
  await Hive.openBox<FavoritePet>('favoritePetsBox');
  // --- Tambahkan baris ini untuk membuka box userBox ---
  await Hive.openBox('userBox'); // Box untuk menyimpan data user, termasuk path gambar profil

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data == true) {
              return const HomePage();
            } else {
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}