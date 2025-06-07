import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/petInSaleModel.dart';
import '../models/favoritePetModel.dart';
import 'pembayaranPage.dart';

class PetDetailPage extends StatefulWidget {
  final PetInSale pet;

  const PetDetailPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isFavorite = false;
  late Box<FavoritePet> _favoritePetsBox;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _initHiveAndUser();
    _loadPetLocationMarker();
  }

  Future<void> _initHiveAndUser() async {
    _favoritePetsBox = Hive.box<FavoritePet>('favoritePetsBox');
    
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString('username');

    _checkFavoriteStatus();
  }

  void _loadPetLocationMarker() {
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

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6D9F71)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat', 
                color: Color(0xFF555555), 
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28.0), 
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Montserrat', 
              color: Color(0xFF333333), 
            ),
          ),
        ),
      ],
    );
  }

  void _checkFavoriteStatus() {
    if (widget.pet.id != null && _currentUserEmail != null) {
      _isFavorite = _favoritePetsBox.values.any(
        (favPet) => favPet.petId == widget.pet.id.toString() && favPet.userEmail == _currentUserEmail,
      );
    } else {
      _isFavorite = false;
    }
    setState(() {});
  }

  Future<void> _toggleFavorite() async {
    if (widget.pet.id == null || _currentUserEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat memfavoritkan. Pastikan ID hewan dan email pengguna tersedia.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String petIdAsString = widget.pet.id.toString();
    final String hiveKey = '${petIdAsString}_${_currentUserEmail!}';

    if (_isFavorite) {
      await _favoritePetsBox.delete(hiveKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.pet.name} dihapus dari favorit.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      final favoritePet = FavoritePet(
        petId: petIdAsString,
        userEmail: _currentUserEmail!,
      );
      await _favoritePetsBox.put(hiveKey, favoritePet);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.pet.name} ditambahkan ke favorit!',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: const Color(0xFF6D9F71), 
        ),
      );
    }
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialMapTarget = (widget.pet.locationLat != null && widget.pet.locationLong != null)
        ? LatLng(widget.pet.locationLat!, widget.pet.locationLong!)
        : const LatLng(-6.2088, 106.8456); 

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: Text(
          widget.pet.name ?? 'Detail Hewan Peliharaan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : const Color(0xFF6D9F71), 
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFA5D6A7), width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.0), 
                  child: widget.pet.imgUrl != null && Uri.tryParse(widget.pet.imgUrl!)?.hasAbsolutePath == true
                      ? Image.network(
                          widget.pet.imgUrl!,
                          height: 280, 
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 280,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Icon(Icons.grass, size: 100, color: Colors.grey), 
                            alignment: Alignment.center,
                          ),
                        )
                      : Container(
                          height: 280,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.grass, size: 100, color: Colors.grey), 
                          alignment: Alignment.center,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.pet.name ?? 'Nama Tidak Tersedia',
              style: const TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: Color(0xFF333333), 
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFA5D6A7), 
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Harga: IDR ${widget.pet.price?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.white, 
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Detail Hewan'),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailItem(Icons.category, 'Kategori', widget.pet.category ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.cake, 'Usia', '${widget.pet.age ?? 'N/A'} Bulan'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.favorite_border, 'Kesehatan', widget.pet.healthStatus ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.info_outline, 'Status', widget.pet.status ?? 'N/A'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            _buildSectionTitle('Deskripsi'),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.pet.description ?? 'Tidak ada deskripsi tersedia.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    color: Color(0xFF555555),
                  ),
                  textAlign: TextAlign.justify, 
                ),
              ),
            ),

            const SizedBox(height: 30),
            _buildSectionTitle('Kontak & Lokasi'),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailItem(Icons.email, 'Email Penjual', widget.pet.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.location_on, 'Koordinat Lokasi', 'Lat: ${widget.pet.locationLat ?? 'N/A'}, Long: ${widget.pet.locationLong ?? 'N/A'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            if (widget.pet.locationLat != null && widget.pet.locationLong != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lokasi di Peta'),
                  const SizedBox(height: 10),
                  Container(
                    height: 280, 
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 2.0), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.0),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: initialMapTarget,
                          zoom: 15.0,
                        ),
                        markers: _markers,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
            if (widget.pet.status != 'paid')
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
                  label: const Text(
                    'Adopsi Sekarang!', 
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D9F71), 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), 
                    ),
                    elevation: 5, 
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
        color: Color(0xFF444444), 
      ),
    );
  }
}