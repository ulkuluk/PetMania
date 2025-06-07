import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import '../models/petInSaleModel.dart';
import '../models/transactionModel.dart';
import '../services/petInSaleService.dart';
import '../services/transactionService.dart';
import 'locationPickerPage.dart';

class PembayaranPage extends StatefulWidget {
  final PetInSale pet;

  const PembayaranPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shippingAddressController =
      TextEditingController();
  LatLng? _selectedShippingLocation;
  String? _buyerEmail;
  bool _isProcessing = false;
  String? _errorMessage;

  String _selectedCurrency = 'IDR';
  Map<String, double> _exchangeRates = {}; 
  double? _convertedPrice;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String _baseCurrency =
      'IDR'; 
  final String _apiKey =
      'cba6a9a86ab6208ee6969598'; 

  @override
  void initState() {
    super.initState();
    _loadBuyerEmail();
    _fetchExchangeRates(); 
    _initializeNotifications();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isProcessing = true; 
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://v6.exchangerate-api.com/v6/$_apiKey/latest/$_baseCurrency',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            _exchangeRates = Map<String, double>.from(
              data['conversion_rates'].map(
                (key, value) => MapEntry(key, value.toDouble()),
              ),
            );
            if (!_exchangeRates.containsKey(_baseCurrency)) {
              _exchangeRates[_baseCurrency] = 1.0;
            }

            _calculateConvertedPrice(); 
          });
        } else {
          _errorMessage = 'Gagal mengambil nilai tukar: ${data['error-type']}';
          print('API Error: ${data['error-type']}');
        }
      } else {
        _errorMessage =
            'Gagal terhubung ke API nilai tukar: ${response.statusCode}';
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      print('Network Error: $e');
    } finally {
      setState(() {
        _isProcessing = false; // Selesai fetching rates
      });
      if (_errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
        }
      }
    }
  }

  void _calculateConvertedPrice() {
    if (widget.pet.price != null && _exchangeRates.isNotEmpty) {
      setState(() {
        double? rate = _exchangeRates[_selectedCurrency];
        if (rate != null) {
          _convertedPrice = widget.pet.price! * rate;
        } else {
          _convertedPrice =
              widget.pet.price; 
        }
      });
    } else if (widget.pet.price != null && _selectedCurrency == _baseCurrency) {
      setState(() {
        _convertedPrice = widget.pet.price;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showPaymentSuccessNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'payment_channel',
          'Payment Notifications',
          channelDescription: 'Notifikasi untuk pembayaran dan transaksi',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Pembayaran Berhasil!',
      'Silahkan cek status transaksi Anda',
      notificationDetails,
      payload: 'payment_success',
    );
  }

  Future<void> _loadBuyerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _buyerEmail = prefs.getString('username');
      if (_buyerEmail == null) {
        _errorMessage = 'Email pembeli tidak ditemukan. Harap login kembali.';
      }
    });
  }

  Future<void> _pickShippingLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerPage(
              initialLocation:
                  _selectedShippingLocation ?? const LatLng(-6.2088, 106.8456),
            ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedShippingLocation = pickedLocation;
      });
      await _reverseGeocodeAndFillAddress(pickedLocation);
    }
  }

  Future<void> _reverseGeocodeAndFillAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        _shippingAddressController.text = address;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alamat terisi otomatis: $address')),
          );
        }
      } else {
        _shippingAddressController.text =
            'Alamat tidak ditemukan untuk koordinat ini.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alamat tidak dapat ditemukan untuk lokasi ini.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during reverse geocoding: $e');
      _shippingAddressController.text = 'Gagal mengambil alamat: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil alamat: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_buyerEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email pembeli tidak tersedia. Harap login ulang.'),
          ),
        );
      }
      return;
    }

    if (_selectedShippingLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih lokasi pengiriman terlebih dahulu.'),
          ),
        );
      } // <--- Tanda kurung penutup tambahan telah dihapus di sini
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> petUpdateResponse =
          await PetInSaleApi.updatePetInSaleStatus(widget.pet.id!, 'paid');

      if (petUpdateResponse['status'] != 'success') {
        throw Exception(
          'Gagal memperbarui status hewan peliharaan: ${petUpdateResponse['msg']}',
        );
      }

      Transaction newTransaction = Transaction(
        buyerEmail: _buyerEmail,
        animalId: widget.pet.id,
        sellerEmail: widget.pet.email,
        status: 'paid',
        price: widget.pet.price?.toDouble(),
        shippingAddress: _shippingAddressController.text,
      );

      Map<String, dynamic> transactionCreateResponse =
          await TransactionApi.createTransaction(newTransaction);

      if (transactionCreateResponse['status'] != 'success') {
        throw Exception(
          'Gagal membuat transaksi: ${transactionCreateResponse['msg']}',
        );
      }

      setState(() {
        _isProcessing = false;
      });

      await _showPaymentSuccessNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dan transaksi dicatat!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error during payment process: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Terjadi kesalahan saat memproses pembayaran: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran Adopsi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _buyerEmail == null && _errorMessage == null
              ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Detail Adopsi Hewan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildPetDetailCard(),
                      const SizedBox(height: 30),
                      Text(
                        'Informasi Pengiriman',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildShippingLocationButton(),
                      const SizedBox(height: 15),
                      _buildAddressFormField(),
                      const SizedBox(height: 30),
                      _errorMessage != null
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : const SizedBox.shrink(),
                      _buildPaymentButton(),
                      const SizedBox(height: 16),
                      _buildCancelButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPetDetailCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Hewan: ${widget.pet.name ?? 'N/A'}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kategori: ${widget.pet.category ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            // Solusi 1: Menggunakan Column untuk menghindari overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris untuk harga dengan Flexible/Expanded
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Harga: $_selectedCurrency ${_convertedPrice != null ? _convertedPrice!.toStringAsFixed(2) : '0.00'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        overflow:
                            TextOverflow
                                .ellipsis, // Tambahkan ellipsis jika masih terlalu panjang
                        maxLines: 2, // Izinkan maksimal 2 baris
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Dropdown di baris terpisah
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      onChanged:
                          _isProcessing
                              ? null
                              : (String? newValue) {
                                setState(() {
                                  _selectedCurrency = newValue!;
                                  _calculateConvertedPrice();
                                });
                              },
                      items:
                          _exchangeRates.keys.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Colors.teal.shade700),
                              ),
                            );
                          }).toList(),
                      underline: Container(
                        height: 0,
                        color: Colors.transparent,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.teal.shade700,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Dijual oleh: ${widget.pet.email ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingLocationButton() {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _pickShippingLocation,
      icon: const Icon(Icons.map, color: Colors.white, size: 28),
      label: Text(
        _selectedShippingLocation == null
            ? 'Pilih Lokasi Pengiriman di Peta'
            : 'Lokasi Terpilih',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightGreen.shade700,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
    );
  }

  Widget _buildAddressFormField() {
    return TextFormField(
      controller: _shippingAddressController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText:
            'Alamat pengiriman akan terisi otomatis dari peta, atau Anda bisa edit di sini.',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
        prefixIcon: Icon(Icons.home_outlined, color: Colors.teal.shade700),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Alamat pengiriman tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.orange.shade300,
      ),
      child:
          _isProcessing
              ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
              : const Text(
                'Bayar Sekarang',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: _isProcessing ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.blueGrey.shade400, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        'Batalkan',
        style: TextStyle(
          fontSize: 18,
          color: Colors.blueGrey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
