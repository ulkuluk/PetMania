import 'package:flutter/material.dart';
import '../models/petInSaleModel.dart';
import '../models/transactionModel.dart';
import '../services/transactionService.dart';

class ProsesPembelianPage extends StatefulWidget {
  final PetInSale pet;

  const ProsesPembelianPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<ProsesPembelianPage> createState() => _ProsesPembelianPageState();
}

class _ProsesPembelianPageState extends State<ProsesPembelianPage> {
  Future<List<Transaction>>? _transactionsFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactionsForPet();
  }

  Future<void> _fetchTransactionsForPet() async {
    setState(() {
      _transactionsFuture = _getTransactionsByAnimalId(widget.pet.id!);
    });
  }

  Future<List<Transaction>> _getTransactionsByAnimalId(int animalId) async {
    try {
      final Map<String, dynamic> response =
          await TransactionApi.getTransactionByAnimalId(animalId);
      if (response['status'] == 'success' && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception(
          response['msg'] ?? 'Gagal memuat transaksi untuk hewan ini.',
        );
      }
    } catch (e) {
      print('Error fetching transactions by animal ID: $e');
      throw Exception('Gagal memuat transaksi: $e');
    }
  }

  Future<void> _updateTransactionStatus(
    Transaction transaction,
    String newStatus,
  ) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      Transaction updatedTransaction = Transaction(
        id: transaction.id,
        buyerEmail: transaction.buyerEmail,
        animalId: transaction.animalId,
        sellerEmail: transaction.sellerEmail,
        status: newStatus,
        price: transaction.price,
        shippingAddress: transaction.shippingAddress,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );

      final Map<String, dynamic> response =
          await TransactionApi.updateTransactionById(updatedTransaction);

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status transaksi berhasil diperbarui menjadi "$newStatus"!',
            ),
          ),
        );
        _fetchTransactionsForPet();
      } else {
        throw Exception(
          response['msg'] ?? 'Gagal memperbarui status transaksi.',
        );
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proses Pembelian: ${widget.pet.name}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Transaction>>(
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
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchTransactionsForPet,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inbox_rounded,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada transaksi untuk ${widget.pet.name ?? 'hewan ini'}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          } else {
            final transactions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID Transaksi: ${transaction.id ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pembeli: ${transaction.buyerEmail ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Harga: \IDR${(transaction.price ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Alamat Pengiriman: ${transaction.shippingAddress ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Status Saat Ini: ${transaction.status ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(transaction.status),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (transaction.status == 'paid' ||
                                transaction.status == 'completed')
                              ElevatedButton(
                                onPressed:
                                    _isUpdatingStatus
                                        ? null
                                        : () => _updateTransactionStatus(
                                          transaction,
                                          'shipping',
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child:
                                    _isUpdatingStatus
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Proses Pengiriman',
                                          style: TextStyle(color: Colors.white),
                                        ),
                              ),
                            if (transaction.status == 'shipping')
                              ElevatedButton(
                                onPressed:
                                    _isUpdatingStatus
                                        ? null
                                        : () => _updateTransactionStatus(
                                          transaction,
                                          'delivered',
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child:
                                    _isUpdatingStatus
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Tandai Terkirim',
                                          style: TextStyle(color: Colors.white),
                                        ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.blue;
      case 'paid': 
        return Colors.blueGrey;
      case 'shipping':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
