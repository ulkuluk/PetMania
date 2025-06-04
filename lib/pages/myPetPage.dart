// pages/myPetPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/petInSaleService.dart';
import '../models/petInSaleModel.dart';
import 'prosesPembelianPage.dart'; // Import halaman baru Anda

class MyPetPage extends StatefulWidget {
  const MyPetPage({Key? key}) : super(key: key);

  @override
  State<MyPetPage> createState() => _MyPetPageState();
}

class _MyPetPageState extends State<MyPetPage> {
  String? _userEmail;
  Future<List<PetInSale>>? _myPetsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchPets();
  }

  Future<void> _loadUserAndFetchPets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('username');
      if (_userEmail != null) {
        _myPetsFuture = _fetchMyPets(_userEmail!);
      } else {
        // Handle case where user email is not found
        _myPetsFuture = Future.error('Email pengguna tidak ditemukan. Harap login kembali.');
      }
    });
  }

  Future<List<PetInSale>> _fetchMyPets(String email) async {
    try {
      final response = await PetInSaleApi.getPetInSaleByEmail(email);
      if (response['status'] == 'success' && response['data'] != null) {
        final model = PetInSaleModel.fromJson(response);
        return model.data ?? [];
      } else {
        print('Failed to load my pets: ${response['msg']}');
        return [];
      }
    } catch (e) {
      print('Error fetching my pets: $e');
      throw Exception('Failed to load my pets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hewan Peliharaan Saya'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<PetInSale>>(
        future: _myPetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadUserAndFetchPets, // Coba lagi
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'Anda belum menjual hewan peliharaan apa pun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tambahkan hewan peliharaan untuk mulai menjual!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final myPets = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: myPets.length,
            itemBuilder: (context, index) {
              final pet = myPets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: pet.imgUrl != null && Uri.tryParse(pet.imgUrl!)?.hasAbsolutePath == true
                        ? Image.network(
                            pet.imgUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                              alignment: Alignment.center,
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                            alignment: Alignment.center,
                          ),
                  ),
                  title: Text(
                    pet.name ?? 'Nama Tidak Tersedia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Kategori: ${pet.category ?? 'N/A'}'),
                      Text('Harga: \$${pet.price?.toStringAsFixed(2) ?? '0.00'}'),
                      Text('Status: ${pet.status ?? 'N/A'}', style: TextStyle(color: _getStatusColor(pet.status))),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigasi ke ProsesPembelianPage saat card diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProsesPembelianPage(pet: pet),
                      ),
                    ).then((_) {
                      // Refresh data ketika kembali dari ProsesPembelianPage
                      _loadUserAndFetchPets();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Helper function untuk memberikan warna status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'buyed':
        return Colors.blue; // Status 'buyed' ketika ada transaksi
      default:
        return Colors.grey;
    }
  }
}