import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/petInSaleModel.dart';
import '../services/petInSaleService.dart';
import 'locationPickerPage.dart';

class SellPetPage extends StatefulWidget {
  const SellPetPage({Key? key}) : super(key: key);

  @override
  State<SellPetPage> createState() => _SellPetPageState();
}

class _SellPetPageState extends State<SellPetPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();

  String? _selectedCategory;
  String? _selectedHealthStatus;

  LatLng? _selectedLocation;
  String? _userEmail;
  bool _isSubmitting = false;

  final List<String> _categories = ['cat', 'dog', 'bird', 'fish', 'reptile'];
  final List<String> _healthStatuses = ['healthy', 'sick', 'injured'];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { 
      setState(() {
        _userEmail = prefs.getString('username');
      });
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLocation: _selectedLocation ?? const LatLng(-6.2088, 106.8456), 
        ),
      ),
    );

    if (pickedLocation != null) {
      if (mounted) { 
        setState(() {
          _selectedLocation = pickedLocation;
        });
        _showSnackBar(
            'Lokasi dipilih: ${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}',
            Colors.lightGreen.shade700); 
      }
    }
  }

  Future<void> _submitPetForSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userEmail == null) {
      _showSnackBar('Email pengguna tidak ditemukan. Harap login ulang.', Colors.redAccent);
      return;
    }
    if (_selectedLocation == null) {
      _showSnackBar('Harap pilih lokasi hewan di peta.', Colors.redAccent);
      return;
    }
    if (_selectedCategory == null) {
      _showSnackBar('Harap pilih kategori hewan.', Colors.redAccent);
      return;
    }
    if (_selectedHealthStatus == null) {
      _showSnackBar('Harap pilih status kesehatan hewan.', Colors.redAccent);
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true; 
      });
    }
    try {
      final newPet = PetInSale(
        name: _nameController.text,
        category: _selectedCategory,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text),
        age: int.tryParse(_ageController.text),
        healthStatus: _selectedHealthStatus,
        imgUrl: _imgUrlController.text,
        locationLat: _selectedLocation!.latitude,
        locationLong: _selectedLocation!.longitude,
        email: _userEmail,
        status: 'available',
      );

      final response = await PetInSaleApi.createPetInSale(newPet);

      if (mounted) {
        if (response['status'] == 'success') {
          _showSnackBar('Hewan peliharaan berhasil ditambahkan!', Colors.green);
          _clearForm();
        } else {
          _showSnackBar('Gagal menambahkan hewan peliharaan: ${response['msg'] ?? 'Terjadi kesalahan'}', Colors.redAccent);
        }
      }
    } catch (e) {
      print('Error submitting pet: $e');
      if (mounted) {
        _showSnackBar('Terjadi kesalahan saat mengirim data: ${e.toString()}', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false; 
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _ageController.clear();
    _imgUrlController.clear();
    if (mounted) {
      setState(() {
        _selectedLocation = null;
        _selectedCategory = null;
        _selectedHealthStatus = null;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating, 
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _ageController.dispose();
    _imgUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jual Hewan Peliharaan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700, 
        elevation: 0,
        centerTitle: true,
      ),
      body: _userEmail == null
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), 
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    _buildTextFormField(
                      controller: _nameController,
                      labelText: 'Nama Hewan',
                      icon: Icons.pets,
                      validator: (value) {
                        if (value!.isEmpty) return 'Nama hewan wajib diisi';
                        if (value.length > 255) return 'Nama tidak boleh lebih dari 255 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownFormField(
                      value: _selectedCategory,
                      labelText: 'Kategori',
                      icon: Icons.category,
                      items: _categories,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Kategori wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _descriptionController,
                      labelText: 'Deskripsi',
                      icon: Icons.description,
                      maxLines: 4,
                      validator: (value) => value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _priceController,
                      labelText: 'Harga (contoh: 150000)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Harga wajib diisi';
                        final price = double.tryParse(value);
                        if (price == null) return 'Masukkan angka yang valid';
                        if (price > 1000000000000) return 'Harga tidak boleh lebih dari 1 triliun';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _ageController,
                      labelText: 'Usia (dalam bulan)',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Usia wajib diisi';
                        final age = int.tryParse(value);
                        if (age == null) return 'Masukkan angka yang valid';
                        if (age > 10000) return 'Usia tidak boleh lebih dari 10000 bulan'; 
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownFormField(
                      value: _selectedHealthStatus,
                      labelText: 'Status Kesehatan',
                      icon: Icons.healing,
                      items: _healthStatuses,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedHealthStatus = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Status kesehatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _imgUrlController,
                      labelText: 'URL Gambar',
                      icon: Icons.image,
                      validator: (value) {
                        if (value!.isEmpty) return 'URL gambar wajib diisi';
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildLocationPickerButton(),
                    if (_selectedLocation != null) const SizedBox(height: 12),
                    if (_selectedLocation != null)
                      _buildLocationCoordinatesText(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
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
      maxLines: maxLines,
      validator: validator,
    );
  }
  Widget _buildDropdownFormField<T>({
    required T? value,
    required String labelText,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), 
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString().replaceFirst(item.toString()[0], item.toString()[0].toUpperCase())), 
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildLocationPickerButton() {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _pickLocation,
      icon: const Icon(Icons.location_on, color: Colors.white, size: 28),
      label: Text(
        _selectedLocation == null
            ? 'Pilih Lokasi Hewan di Peta'
            : 'Lokasi Terpilih: ${ _selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700, 
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Colors.orange.shade300,
      ),
    );
  }

  Widget _buildLocationCoordinatesText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'Koordinat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitPetForSale,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade800, 
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 7, 
        shadowColor: Colors.green.shade400,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Jual Hewan Peliharaan',
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }
}