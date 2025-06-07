import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import '../models/petInSaleModel.dart';
import '../services/petInSaleService.dart';
import 'locationPickerPage.dart'; 

class EditPetPage extends StatefulWidget {
  final PetInSale pet; 

  const EditPetPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _ageController;
  late TextEditingController _imgUrlController;

  String? _selectedCategory;
  String? _selectedHealthStatus;
  LatLng? _selectedLocation; 

  final List<String> _categories = ['cat', 'dog', 'bird', 'fish', 'reptile'];
  final List<String> _healthStatuses = ['healthy', 'sick', 'injured'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _descriptionController = TextEditingController(text: widget.pet.description);
    _priceController =
        TextEditingController(text: widget.pet.price?.toStringAsFixed(2));
    _ageController = TextEditingController(text: widget.pet.age?.toString());
    _imgUrlController = TextEditingController(text: widget.pet.imgUrl);

    _selectedCategory = widget.pet.category;
    _selectedHealthStatus = widget.pet.healthStatus;
    if (widget.pet.locationLat != null && widget.pet.locationLong != null) {
      _selectedLocation = LatLng(widget.pet.locationLat!, widget.pet.locationLong!);
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
      setState(() {
        _selectedLocation = pickedLocation;
      });
      _showSnackBar(
          'Lokasi dipilih: ${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}',
          Colors.blueAccent);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final updatedPet = PetInSale(
          id: widget.pet.id, 
          name: _nameController.text,
          category: _selectedCategory,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text),
          age: int.tryParse(_ageController.text),
          healthStatus: _selectedHealthStatus,
          imgUrl: _imgUrlController.text,
          locationLat: _selectedLocation!.latitude,
          locationLong: _selectedLocation!.longitude,
          email: widget.pet.email, 
          status: widget.pet.status, 
        );

        final response = await PetInSaleApi.updateFullPetInSale(updatedPet);

        Navigator.of(context).pop();

        if (response['status'] == 'success') {
          _showSnackBar('Hewan peliharaan berhasil diupdate!', Colors.green);
          Navigator.pop(context, true); 
        } else {
          _showSnackBar(
              'Gagal mengupdate hewan peliharaan: ${response['msg'] ?? 'Terjadi kesalahan'}',
              Colors.redAccent);
        }
      } catch (e) {
        Navigator.of(context).pop(); 
        _showSnackBar('Terjadi kesalahan saat menyimpan perubahan: $e', Colors.redAccent);
        print('Error updating pet: $e');
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.pet.name ?? "Hewan Peliharaan"}'),
        backgroundColor: Colors.amber, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Hewan'),
                validator: (value) {
                  if (value!.isEmpty) return 'Nama hewan wajib diisi';
                  if (value.length > 255) return 'Nama tidak boleh lebih dari 255 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Kategori wajib diisi' : null,
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
                decoration: const InputDecoration(labelText: 'Harga (contoh: 150000)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Harga wajib diisi';
                  final price = double.tryParse(value);
                  if (price == null) return 'Masukkan angka yang valid';
                  if (price > 1000000000000) return 'Harga tidak boleh lebih dari 1 triliun';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Usia (dalam bulan)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Usia wajib diisi';
                  final age = int.tryParse(value);
                  if (age == null) return 'Masukkan angka yang valid';
                  if (age > 10000) return 'Usia tidak boleh lebih dari 10000';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Dropdown untuk Status Kesehatan
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status Kesehatan'),
                value: _selectedHealthStatus,
                items: _healthStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHealthStatus = newValue;
                  });
                },
                validator: (value) => value == null ? 'Status kesehatan wajib diisi' : null,
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
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Simpan Perubahan',
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