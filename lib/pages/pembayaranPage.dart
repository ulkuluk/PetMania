// pages/pembayaranPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/petInSaleModel.dart';
import '../models/transactionModel.dart';
import '../services/petInSaleService.dart';
import '../services/transactionService.dart';

class PembayaranPage extends StatefulWidget {
  final PetInSale pet;

  const PembayaranPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  final _formKey = GlobalKey<FormState>(); // Key untuk validasi form
  final TextEditingController _shippingAddressController = TextEditingController();
  String? _buyerEmail;
  bool _isProcessing = false; // Mengubah nama dari _isLoading menjadi _isProcessing
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuyerEmail(); // Hanya memuat email saat init, tidak langsung memproses pembayaran
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi gagal
    }

    if (_buyerEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email pembeli tidak tersedia. Harap login ulang.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Perbarui status PetInSale menjadi "buyed"
      Map<String, dynamic> petUpdateResponse =
          await PetInSaleApi.updatePetInSaleStatus(widget.pet.id!, 'paid');

      if (petUpdateResponse['status'] != 'success') {
        throw Exception('Gagal memperbarui status hewan peliharaan: ${petUpdateResponse['msg']}');
      }

      // 2. Tambahkan data transaksi baru
      Transaction newTransaction = Transaction(
        buyerEmail: _buyerEmail,
        animalId: widget.pet.id,
        sellerEmail: widget.pet.email,
        status: 'paid',
        price: widget.pet.price?.toDouble(),
        shippingAddress: _shippingAddressController.text, // Mengambil dari input pengguna
      );

      Map<String, dynamic> transactionCreateResponse =
          await TransactionApi.createTransaction(newTransaction);

      if (transactionCreateResponse['status'] != 'success') {
        throw Exception('Gagal membuat transaksi: ${transactionCreateResponse['msg']}');
      }

      // Jika semua berhasil
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil dan transaksi dicatat!')),
      );

      // Navigasi ke halaman utama setelah pembayaran berhasil
      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      print('Error during payment process: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Terjadi kesalahan saat memproses pembayaran: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _shippingAddressController.dispose(); // Bersihkan controller saat widget dibuang
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView( // Tambahkan SingleChildScrollView agar keyboard tidak menutupi input
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Detail Pembelian:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama Hewan: ${widget.pet.name ?? 'N/A'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Harga: \$${widget.pet.price?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Penjual: ${widget.pet.email ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Alamat Pengiriman:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shippingAddressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat pengiriman lengkap Anda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat pengiriman tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(), // Jika tidak ada error, tidak tampilkan apa-apa

              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment, // Nonaktifkan tombol saat memproses
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Bayar Sekarang',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Batalkan',
                  style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}