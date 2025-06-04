import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps Flutter
import '../models/petInSaleModel.dart'; // Pastikan path ini benar
import 'pembayaranPage.dart'; // Import halaman PembayaranPage

// Ubah PetDetailPage menjadi StatefulWidget
class PetDetailPage extends StatefulWidget {
  final PetInSale pet;

  const PetDetailPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {}; // Untuk menyimpan marker lokasi hewan

  @override
  void initState() {
    super.initState();
    // Tambahkan marker saat inisialisasi jika lokasi tersedia
    if (widget.pet.locationLat != null && widget.pet.locationLong != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pet_location'),
          position: LatLng(widget.pet.locationLat!, widget.pet.locationLong!),
          infoWindow: InfoWindow(title: widget.pet.name ?? 'Lokasi Hewan'),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Fungsi untuk membangun item detail seperti sebelumnya
  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose(); // Penting untuk dispose controller peta
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan initial target untuk peta. Jika lokasi hewan tidak ada, gunakan default.
    final LatLng initialMapTarget = (widget.pet.locationLat != null && widget.pet.locationLong != null)
        ? LatLng(widget.pet.locationLat!, widget.pet.locationLong!)
        : const LatLng(-6.2088, 106.8456); // Default ke Jakarta jika lokasi tidak ada

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet.name ?? 'Detail Hewan Peliharaan'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: widget.pet.imgUrl != null && Uri.tryParse(widget.pet.imgUrl!)?.hasAbsolutePath == true
                    ? Image.network(
                        widget.pet.imgUrl!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                          alignment: Alignment.center,
                        ),
                      )
                    : Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                        alignment: Alignment.center,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.pet.name ?? 'Nama Tidak Tersedia',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.category, 'Kategori', widget.pet.category ?? 'N/A'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(Icons.attach_money, 'Harga', '\$${widget.pet.price?.toStringAsFixed(2) ?? '0.00'}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.cake, 'Usia', '${widget.pet.age ?? 'N/A'}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(Icons.favorite_border, 'Kesehatan', widget.pet.healthStatus ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Deskripsi:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.pet.description ?? 'Tidak ada deskripsi tersedia.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informasi Kontak & Lokasi:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailItem(Icons.email, 'Email Penjual', widget.pet.email ?? 'N/A'),
            const SizedBox(height: 8),
            _buildDetailItem(Icons.location_on, 'Koordinat Lokasi', 'Lat: ${widget.pet.locationLat ?? 'N/A'}, Long: ${widget.pet.locationLong ?? 'N/A'}'),

            // --- Google Map View untuk menampilkan lokasi hewan ---
            const SizedBox(height: 16),
            if (widget.pet.locationLat != null && widget.pet.locationLong != null) // Tampilkan peta hanya jika koordinat ada
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi di Peta:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250, // Tinggi peta, sesuaikan sesuai kebutuhan
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey, width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: initialMapTarget,
                          zoom: 15.0, // Zoom level yang sesuai untuk melihat lokasi spesifik
                        ),
                        markers: _markers, // Tampilkan marker hewan
                        scrollGesturesEnabled: true, // Aktifkan scroll peta
                        zoomGesturesEnabled: true, // Aktifkan zoom peta
                      ),
                    ),
                  ),
                ],
              ),
            // --- Akhir Google Map View ---

            const SizedBox(height: 24),
            _buildDetailItem(Icons.info_outline, 'Status', widget.pet.status ?? 'N/A'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PembayaranPage(pet: widget.pet),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text('Beli Sekarang', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}