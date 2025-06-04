import 'package:flutter/material.dart';
import '../services/petInSaleService.dart';
import '../models/petInSaleModel.dart';
import 'akunPage.dart'; // Import halaman Akun
import 'sellPetPage.dart'; // Import halaman SellPetPage
import 'petDetailPage.dart'; // Import halaman PetDetailPage
import 'myPetPage.dart'; // Import halaman MyPetPage yang baru
import 'transactionPage.dart'; // Import halaman TransactionPage yang baru

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Helper method untuk halaman daftar hewan peliharaan
  Widget _buildPetListingsPage(BuildContext context) {
    return FutureBuilder<List<PetInSale>>(
      future: _fetchPets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pets found.'));
        }

        final pets = snapshot.data!;
        return ListView.builder(
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: pet.imgUrl != null
                    ? Image.network(
                        pet.imgUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.pets, size: 60),
                      )
                    : const Icon(Icons.pets, size: 60),
                title: Text(pet.name ?? 'No name'),
                subtitle: Text(
                  '${pet.category ?? ''} - \$${pet.price?.toStringAsFixed(2) ?? '0.00'}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigasi ke PetDetailPage saat card diklik
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
    );
  }

  // Fetch Pets (dijadikan static agar bisa dipanggil dari _buildPetListingsPage)
  static Future<List<PetInSale>> _fetchPets() async {
    final response = await PetInSaleApi.getPetInSale();
    final model = PetInSaleModel.fromJson(response);
    return model.data ?? [];
  }

  // Fungsi saat bottom nav di-tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Daftar halaman yang akan ditampilkan (termasuk halaman yang memerlukan context)
    // Sekarang kita akan menempatkan semua widget di sini atau menggunakan fungsi
    // untuk menghasilkan widget yang memerlukan context.
    final List<Widget> pages = <Widget>[
      _buildPetListingsPage(context), // Index 0: Halaman daftar hewan peliharaan
      const SellPetPage(),           // Index 1: Halaman jual hewan peliharaan
      const MyPetPage(),             // Index 2: Halaman My Pets
      const TransactionPage(),       // Index 3: Halaman Transaksi
      const AkunPage(),              // Index 4: Halaman Akun
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pet App')),
      body: pages[_selectedIndex], // Menampilkan halaman sesuai indeks yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Penting jika item lebih dari 3
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Sell Pet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets), // Ikon untuk My Pets (bisa diganti)
            label: 'My Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt), // Ikon untuk Transactions (bisa diganti)
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}