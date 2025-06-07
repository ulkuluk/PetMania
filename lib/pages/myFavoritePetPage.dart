import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:petmania/services/petInSaleService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favoritePetModel.dart';
import '../models/petInSaleModel.dart';
import 'petDetailPage.dart';

class MyFavoritePetPage extends StatefulWidget {
  const MyFavoritePetPage({super.key});

  @override
  State<MyFavoritePetPage> createState() => _MyFavoritePetPageState();
}

class _MyFavoritePetPageState extends State<MyFavoritePetPage> {
  late Box<FavoritePet> _favoritePetsBox;
  String? _currentUserEmail;
  List<PetInSale> _favoritePetsData = [];
  bool _isLoading = true;

  Future<List<PetInSale>> _fetchAllPetsFromAPI() async {
    try {
      final response = await PetInSaleApi.getPetInSale();
      final model = PetInSaleModel.fromJson(response);
      return model.data ?? [];
    } catch (e) {
      print('Error fetching all pets: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _initAndLoadFavorites();
  }

  Future<void> _initAndLoadFavorites() async {
    _favoritePetsBox = Hive.box<FavoritePet>('favoritePetsBox');
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString('username');
    _favoritePetsBox.listenable().addListener(_loadFavorites);
    _loadFavorites();
  }

  void _loadFavorites() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    if (_currentUserEmail == null) {
      if (mounted) {
        setState(() {
          _favoritePetsData = [];
          _isLoading = false;
        });
      }
      return;
    }

    final List<String> favoritePetIdsForCurrentUser =
        _favoritePetsBox.values
            .where((favPet) => favPet.userEmail == _currentUserEmail)
            .map((favPet) => favPet.petId)
            .toList();

    final List<PetInSale> allAvailablePets = await _fetchAllPetsFromAPI();

    if (mounted) {
      setState(() {
        _favoritePetsData =
            allAvailablePets
                .where(
                  (pet) =>
                      pet.id != null &&
                      favoritePetIdsForCurrentUser.contains(pet.id.toString()),
                )
                .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(PetInSale pet) async {
    if (pet.id == null || _currentUserEmail == null) return;

    final String petIdAsString = pet.id.toString();
    final String hiveKey = '${petIdAsString}_${_currentUserEmail!}';

    await _favoritePetsBox.delete(hiveKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pet.name} telah dihapus dari favorit Anda.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _favoritePetsBox.listenable().removeListener(_loadFavorites);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hewan Favoritku',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
              : _favoritePetsData.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada hewan favorit yang ditambahkan.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _favoritePetsData.length,
                itemBuilder: (context, index) {
                  final pet = _favoritePetsData[index];
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: const AlwaysStoppedAnimation(1),
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.teal.withOpacity(0.3),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailPage(pet: pet),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child:
                                    pet.imgUrl != null &&
                                            Uri.tryParse(
                                                  pet.imgUrl!,
                                                )?.hasAbsolutePath ==
                                                true
                                        ? Image.network(
                                          pet.imgUrl!,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 90,
                                                    height: 90,
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        )
                                        : Container(
                                          width: 90,
                                          height: 90,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.pets,
                                            size: 50,
                                            color: Colors.grey,
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kategori: ${pet.category ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.blueGrey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Harga: IDR ${pet.price?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                onPressed: () => _removeFavorite(pet),
                                tooltip: 'Hapus dari favorit',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
