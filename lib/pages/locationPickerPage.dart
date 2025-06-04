import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  const LocationPickerPage({Key? key, this.initialLocation = const LatLng(-6.2088, 106.8456)}) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation; // Lokasi yang dipilih pengguna
  Marker? _marker; // Marker untuk lokasi yang dipilih

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _marker = Marker(
      markerId: const MarkerId('selected_location'),
      position: _selectedLocation!,
      infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
        infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi di Peta'),
        backgroundColor: Colors.teal, // Memberikan warna agar terlihat konsisten
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              if (_selectedLocation != null) {
                Navigator.pop(context, _selectedLocation); // Kirim kembali lokasi yang dipilih
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih lokasi terlebih dahulu di peta.')),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation,
          zoom: 12.0,
        ),
        onTap: _onTap, // Tangani tap pada peta untuk memilih lokasi
        markers: _marker != null ? {_marker!} : {}, // Tampilkan marker jika ada
        myLocationEnabled: true, // Aktifkan tombol lokasi saya
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_mapController != null && _selectedLocation != null) {
            // Animasi kamera ke lokasi yang dipilih saat ini
            await _mapController!.animateCamera(
              CameraUpdate.newLatLng(_selectedLocation!),
            );
          }
        },
        backgroundColor: Colors.blueAccent, // Warna FAB
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}