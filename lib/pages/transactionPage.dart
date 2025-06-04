// pages/transactionPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transactionModel.dart'; // Import model transaksi Anda
import '../services/transactionService.dart'; // Import service transaksi Anda

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String? _buyerEmail;
  Future<List<Transaction>>? _transactionsFuture; // Future untuk menampung hasil API call

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    _buyerEmail = prefs.getString('username'); // Asumsi 'username' menyimpan email pengguna

    if (_buyerEmail != null) {
      setState(() {
        _transactionsFuture = _fetchTransactions(_buyerEmail!);
      });
    } else {
      // Jika email tidak ditemukan, kita bisa menampilkan pesan error atau mengarahkan ke login
      setState(() {
        _transactionsFuture = Future.error('Email pengguna tidak ditemukan. Harap login kembali.');
      });
    }
  }

  Future<List<Transaction>> _fetchTransactions(String email) async {
    try {
      final Map<String, dynamic> response =
          await TransactionApi.getTransactionByBuyerEmail(email);

      if (response['status'] == 'success' && response['data'] != null) {
        // Mapping data JSON ke dalam list Transaction
        return (response['data'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception(response['msg'] ?? 'Gagal memuat transaksi.');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Gagal memuat riwayat transaksi: $e');
    }
  }

  // Helper widget untuk menampilkan detail transaksi
  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID Transaksi: ${transaction.id ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nama Hewan (ID): ${transaction.animalId ?? 'N/A'}', // Anda mungkin perlu mengambil nama hewan dari PetInSale jika diperlukan
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Penjual: ${transaction.sellerEmail ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Pembeli: ${transaction.buyerEmail ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Harga: \$${(transaction.price ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              'Status: ${transaction.status ?? 'N/A'}',
              style: TextStyle(
                fontSize: 16,
                color: transaction.status == 'completed' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Alamat Pengiriman: ${transaction.shippingAddress ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Tanggal: ${transaction.createdAt != null ? DateTime.parse(transaction.createdAt!).toLocal().toString().split(' ')[0] : 'N/A'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Saya'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _buyerEmail == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'Anda belum login atau email tidak ditemukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Silakan login untuk melihat riwayat transaksi Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                          const SizedBox(height: 20),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.red),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadTransactions, // Coba lagi
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Tidak ada transaksi yang ditemukan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Mulai jelajahi hewan peliharaan kami untuk melakukan pembelian pertama Anda!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Data berhasil dimuat
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final transaction = snapshot.data![index];
                      return _buildTransactionItem(transaction);
                    },
                  );
                }
              },
            ),
    );
  }
}