import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../services/petInSaleService.dart';
import '../models/petInSaleModel.dart';
import 'akunPage.dart'; 
import 'sellPetPage.dart'; 
import 'petDetailPage.dart'; 
import 'myPetPage.dart'; 
import 'transactionPage.dart'; 
import 'myFavoritePetPage.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedStatus;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  bool _isShaking = false;
  static const double _shakeThreshold = 15.0; 
  static const int _shakeCooldown = 2000; 

  final List<String> _categories = [
    'Semua',
    'cat',
    'dog',
    'bird',
    'fish',
    'reptile',
  ];

  final List<String> _statuses = [
    'Semua',
    'available',
    'paid',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _selectedStatus = _statuses.first;
    _searchController.addListener(_onSearchChanged);
    _initAccelerometer();
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _onAccelerometerEvent(event);
    });
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude > _shakeThreshold) {
      DateTime now = DateTime.now();

      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldown) {
        _lastShakeTime = now;
        _handleShakeRefresh();
      }
    }
  }

  void _handleShakeRefresh() {
    if (!_isShaking && _selectedIndex == 0) {
      setState(() {
        _isShaking = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Memuat ulang data...',
                style: TextStyle(fontFamily: 'Montserrat'), 
              ),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF6D9F71), 
        ),
      );

      _searchController.clear();
      _selectedCategory = _categories.first;
      _selectedStatus = _statuses.first;

      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isShaking = false;
          });
        }
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _selectedCategory = _categories.first;
      _selectedStatus = _statuses.first;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPetListingsPage(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isShaking)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6D9F71)), 
                  ),
                ),
              
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari hewan peliharaan...', 
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6D9F71)), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), 
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF0F4C3), 
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15), 
                  ),
                  onSubmitted: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    labelStyle: TextStyle(color: Color(0xFF6D9F71), fontFamily: 'Montserrat'), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), 
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF0F4C3), 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15), 
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category, style: TextStyle(fontFamily: 'Montserrat')), 
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                      _searchController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12), 
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Color(0xFF6D9F71), fontFamily: 'Montserrat'), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), 
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF0F4C3), 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15), 
                  ),
                  items: _statuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status == 'available' ? 'Tersedia' : (status == 'paid' ? 'Terjual' : status),
                        style: TextStyle(fontFamily: 'Montserrat'), 
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                      _searchController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PetInSale>>(
            key: ValueKey('${_selectedCategory}_${_selectedStatus}_${_searchController.text}_${_isShaking ? DateTime.now().millisecondsSinceEpoch : ''}'),
            future: _fetchPets(
              category: _selectedCategory == 'Semua' ? null : _selectedCategory,
              searchQuery: _searchController.text,
              status: _selectedStatus == 'Semua' ? null : _selectedStatus,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6D9F71))); 
              } else if (snapshot.hasError) {
                return Center(
                    child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.redAccent, fontFamily: 'Montserrat'),
                ));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                  'Tidak ada hewan peliharaan yang ditemukan.',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Montserrat'),
                ));
              }

              final pets = snapshot.data!;
              return ListView.builder(
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                    elevation: 4, // Sedikit bayangan
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16), 
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), 
                        child: pet.imgUrl != null && Uri.tryParse(pet.imgUrl!)?.hasAbsolutePath == true
                            ? Image.network(
                                pet.imgUrl!,
                                width: 80, 
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.pets, size: 80, color: Color(0xFFA5D6A7)), 
                              )
                            : Icon(Icons.pets, size: 80, color: Color(0xFFA5D6A7)), 
                      ),
                      title: Text(
                        pet.name ?? 'Nama Tidak Diketahui',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF333333), 
                          fontFamily: 'Montserrat', 
                        ),
                      ),
                      subtitle: Text(
                        '${pet.category ?? ''} - IDR ${pet.price?.toStringAsFixed(2) ?? '0.00'} - Status: ${pet.status == 'available' ? 'Tersedia' : (pet.status == 'paid' ? 'Terjual' : 'N/A')}',
                        style: TextStyle(
                          color: Color(0xFF555555), 
                          fontSize: 14,
                          fontFamily: 'Montserrat', 
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF6D9F71)), 
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailPage(pet: pet),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<List<PetInSale>> _fetchPets({
    String? category,
    String? searchQuery,
    String? status,
  }) async {
    final response = await PetInSaleApi.getPetInSale();
    final model = PetInSaleModel.fromJson(response);
    List<PetInSale> filteredPets = model.data ?? [];

    if (category != null && category != 'Semua') {
      filteredPets = filteredPets
          .where((pet) =>
              pet.category != null &&
              pet.category!.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredPets = filteredPets
          .where((pet) =>
              pet.name != null &&
              pet.name!.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (status != null && status != 'Semua') {
      filteredPets = filteredPets
          .where((pet) =>
              pet.status != null &&
              pet.status!.toLowerCase() == status.toLowerCase())
          .toList();
    }

    return filteredPets;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _buildPetListingsPage(context),
      const SellPetPage(),
      const MyPetPage(),
      const TransactionPage(),
      const AkunPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PetMania', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico', 
            fontSize: 24, 
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D9F71), Color(0xFFA5D6A7)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyFavoritePetPage()),
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF6D9F71), 
        unselectedItemColor: Colors.grey[600], 
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFFFFFFFF), 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28), 
            label: 'Beranda', 
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file, size: 28), 
            label: 'Jual Hewan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, size: 28), 
            label: 'My Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 28), 
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, size: 28), 
            label: 'Profil', 
          ),
        ],
      ),
    );
  }
}