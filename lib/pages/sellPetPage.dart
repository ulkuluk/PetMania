// pages/sellPetPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps Flutter
import '../models/petInSaleModel.dart';
import '../services/petInSaleService.dart';
import 'locationPickerPage.dart'; // Import halaman pemilihan lokasi

class SellPetPage extends StatefulWidget {
  const SellPetPage({Key? key}) : super(key: key);

  @override
  State<SellPetPage> createState() => _SellPetPageState();
}

class _SellPetPageState extends State<SellPetPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _healthStatusController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();
  
  // Tidak lagi menggunakan TextEditingController untuk lat/long,
  // melainkan langsung menyimpan LatLng
  LatLng? _selectedLocation;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('username');
    });
  }

  // Fungsi untuk membuka halaman pemilihan lokasi
  Future<void> _pickLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLocation: _selectedLocation ?? const LatLng(-6.2088, 106.8456), // Gunakan lokasi terpilih sebelumnya atau default
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        // Opsional: Anda bisa memperbarui TextFormField jika ingin menampilkan koordinat
        // _locationLatController.text = pickedLocation.latitude.toString();
        // _locationLongController.text = pickedLocation.longitude.toString();
      });
      _showSnackBar(
          'Lokasi dipilih: ${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}',
          Colors.blueAccent);
    }
  }

  Future<void> _submitPetForSale() async {
    if (_formKey.currentState!.validate()) {
      if (_userEmail == null) {
        _showSnackBar('Email pengguna tidak ditemukan. Harap login ulang.', Colors.redAccent);
        return;
      }
      if (_selectedLocation == null) {
        _showSnackBar('Harap pilih lokasi hewan di peta.', Colors.redAccent);
        return;
      }

      setState(() {
        // Tambahkan indikator loading jika diinginkan
      });

      try {
        final newPet = PetInSale(
          name: _nameController.text,
          category: _categoryController.text,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text),
          age: int.tryParse(_ageController.text),
          healthStatus: _healthStatusController.text,
          imgUrl: _imgUrlController.text,
          locationLat: _selectedLocation!.latitude, // Ambil dari _selectedLocation
          locationLong: _selectedLocation!.longitude, // Ambil dari _selectedLocation
          email: _userEmail,
          status: 'available',
        );

        final response = await PetInSaleApi.createPetInSale(newPet);

        if (response['status'] == 'success') {
          _showSnackBar('Hewan peliharaan berhasil ditambahkan!', Colors.green);
          _clearForm();
        } else {
          _showSnackBar('Gagal menambahkan hewan peliharaan: ${response['msg'] ?? 'Terjadi kesalahan'}', Colors.redAccent);
        }
      } catch (e) {
        _showSnackBar('Terjadi kesalahan saat mengirim data: $e', Colors.redAccent);
        print('Error submitting pet: $e');
      } finally {
        setState(() {
          // Hilangkan indikator loading di sini
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _ageController.clear();
    _healthStatusController.clear();
    _imgUrlController.clear();
    setState(() {
      _selectedLocation = null; // Bersihkan juga lokasi yang dipilih
    });
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
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _ageController.dispose();
    _healthStatusController.dispose();
    _imgUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jual Hewan Peliharaan'),
      ),
      body: _userEmail == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Hewan'),
                      validator: (value) => value!.isEmpty ? 'Nama hewan wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori (misal: Anjing, Kucing)'),
                      validator: (value) => value!.isEmpty ? 'Kategori wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Harga (contoh: 150.00)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Harga wajib diisi';
                        if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Usia (dalam bulan/tahun)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Usia wajib diisi';
                        if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _healthStatusController,
                      decoration: const InputDecoration(labelText: 'Status Kesehatan'),
                      validator: (value) => value!.isEmpty ? 'Status kesehatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imgUrlController,
                      decoration: const InputDecoration(labelText: 'URL Gambar'),
                      validator: (value) {
                        if (value!.isEmpty) return 'URL gambar wajib diisi';
                        if (!Uri.tryParse(value)!.isAbsolute) return 'Masukkan URL yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Tombol untuk memilih lokasi di peta
                    ElevatedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: Text(
                        _selectedLocation == null
                            ? 'Pilih Lokasi di Peta'
                            : 'Lokasi Terpilih: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_selectedLocation != null) const SizedBox(height: 12),
                    if (_selectedLocation != null)
                      Text(
                        'Koordinat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitPetForSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Jual Hewan Peliharaan',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}