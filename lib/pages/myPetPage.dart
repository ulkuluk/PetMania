import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/petInSaleService.dart';
import '../models/petInSaleModel.dart';
import 'prosesPembelianPage.dart';
import 'editPetPage.dart'; 

class MyPetPage extends StatefulWidget {
  const MyPetPage({Key? key}) : super(key: key);

  @override
  State<MyPetPage> createState() => _MyPetPageState();
}

class _MyPetPageState extends State<MyPetPage> {
  String? _userEmail;
  Future<List<PetInSale>>? _myPetsFuture;
  String? _selectedStatus = 'all';

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
        _myPetsFuture = _fetchMyPets(_userEmail!, _selectedStatus);
      } else {
        _myPetsFuture = Future.error(
          'Email pengguna tidak ditemukan. Harap login kembali.',
        );
      }
    });
  }

  Future<List<PetInSale>> _fetchMyPets(
    String email,
    String? statusFilter,
  ) async {
    try {
      final response = await PetInSaleApi.getPetInSaleByEmail(email);
      if (response['status'] == 'success' && response['data'] != null) {
        final model = PetInSaleModel.fromJson(response);
        List<PetInSale> pets = model.data ?? [];

        if (statusFilter != null &&
            statusFilter != 'all' &&
            statusFilter.isNotEmpty) {
          pets = pets.where((pet) => pet.status == statusFilter).toList();
        }
        return pets;
      } else {
        print('Failed to load my pets: ${response['msg']}');
        return [];
      }
    } catch (e) {
      print('Error fetching my pets: $e');
      throw Exception('Failed to load my pets: $e');
    }
  }

  void _changeStatusFilter(String newStatus) {
    setState(() {
      _selectedStatus = newStatus;
      if (_userEmail != null) {
        _myPetsFuture = _fetchMyPets(_userEmail!, _selectedStatus);
      }
    });
  }

  Future<void> _deletePet(int petId) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Konfirmasi Hapus',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus hewan peliharaan ini? Aksi ini tidak bisa dibatalkan.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(fontFamily: 'Montserrat')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Hapus', style: TextStyle(fontFamily: 'Montserrat')),
              onPressed: () async {
                try {
                  await PetInSaleApi.deletePetInSale(petId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Hewan peliharaan berhasil dihapus!',
                        style: TextStyle(fontFamily: 'Montserrat'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  _loadUserAndFetchPets();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus hewan peliharaan: $e',
                        style: TextStyle(fontFamily: 'Montserrat'),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'all',
                  label: Text('Semua', style: TextStyle(fontFamily: 'Montserrat')),
                  icon: Icon(Icons.pets),
                ),
                ButtonSegment<String>(
                  value: 'available',
                  label: Text('Tersedia', style: TextStyle(fontFamily: 'Montserrat')),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment<String>(
                  value: 'paid',
                  label: Text('Terjual', style: TextStyle(fontFamily: 'Montserrat')),
                  icon: Icon(Icons.shopping_cart),
                ),
              ],
              selected: <String>{_selectedStatus!},
              onSelectionChanged: (Set<String> newSelection) {
                if (newSelection.isNotEmpty) {
                  _changeStatusFilter(newSelection.first);
                }
              },
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: const Color(0xFF6D9F71), 
                foregroundColor: const Color(0xFF6D9F71), 
                side: const BorderSide(
                  color: Color(0xFF6D9F71), 
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), 
                ),
                textStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PetInSale>>(
              future: _myPetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6D9F71)));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sentiment_dissatisfied, 
                            size: 80,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Oops! Terjadi kesalahan: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadUserAndFetchPets,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Coba Lagi',
                              style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA5D6A7), 
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bubble_chart,
                            size: 80,
                            color: Color(0xFFA5D6A7), 
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _selectedStatus == 'all'
                                ? 'Anda belum memiliki hewan peliharaan yang terdaftar.'
                                : 'Tidak ada hewan peliharaan berstatus "${_selectedStatus!.toLowerCase()}" saat ini.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF555555),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ayo, tambahkan hewan peliharaan Anda untuk dijual!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Color(0xFF777777), fontFamily: 'Montserrat'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final myPets = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: myPets.length,
                  itemBuilder: (context, index) {
                    final pet = myPets[index];
                    return Card(
                      elevation: 4, 
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), 
                      ),
                      color: Colors.white, 
                      child: InkWell( 
                        onTap: () {
                         
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProsesPembelianPage(pet: pet),
                            ),
                          ).then((_) {
                            _loadUserAndFetchPets();
                          });
                        },
                        borderRadius: BorderRadius.circular(15.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), 
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: const Color(0xFFA5D6A7), width: 2), 
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0), 
                                  child: pet.imgUrl != null &&
                                          Uri.tryParse(pet.imgUrl!)?.hasAbsolutePath == true
                                      ? Image.network(
                                          pet.imgUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.grass, 
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                alignment: Alignment.center,
                                              ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.grass, 
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          alignment: Alignment.center,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16), 
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet.name ?? 'Nama Tidak Tersedia',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20, 
                                        fontFamily: 'Montserrat',
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kategori: ${pet.category ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF777777),
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    Text(
                                      'Harga: IDR ${pet.price?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF777777),
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Status: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF555555),
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            pet.status ?? 'N/A',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(pet.status),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (pet.status == 'available') ...[
                                      const SizedBox(height: 12), 
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditPetPage(pet: pet),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadUserAndFetchPets();
                                              }
                                            },
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                            label: const Text('Edit', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[700],
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 3,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: () => _deletePet(pet.id!),
                                            icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                            label: const Text('Hapus', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'available':
        return const Color(0xFF6D9F71); 
      case 'pending':
        return Colors.orangeAccent; 
      case 'paid':
        return const Color(0xFF42A5F5); 
      default:
        return Colors.grey;
    }
  }
}