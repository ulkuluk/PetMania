import 'package:flutter/material.dart';
import '../models/petInSaleModel.dart';
import '../models/transactionModel.dart';
import '../services/transactionService.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang dan tanggal

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
            backgroundColor: Colors.green.shade600, // Warna sukses
            behavior: SnackBarBehavior.floating,
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
        SnackBar(
          content: Text('Gagal memperbarui status: ${e.toString()}'),
          backgroundColor: Colors.red.shade700, // Warna error
          behavior: SnackBarBehavior.floating,
        ),
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
      backgroundColor: Colors.green.shade50, // Latar belakang yang lembut dan sesuai tema
      appBar: AppBar(
        title: Text(
          'Transaksi ${widget.pet.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.lightGreen.shade700, // Warna hijau gelap yang ramah
        iconTheme: const IconThemeData(color: Colors.white), // Warna ikon kembali
        elevation: 0, // Tanpa bayangan
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied_rounded, // Ikon lebih ekspresif
                      size: 100,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Oops! Terjadi kesalahan saat memuat data: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchTransactionsForPet,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700, // Tombol refresh dengan warna oranye
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_rounded, // Ikon hewan yang lucu
                      size: 100,
                      color: Colors.lightGreen.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada transaksi untuk ${widget.pet.name ?? 'hewan ini'}. Yuk, jual peliharaanmu!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
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
                  elevation: 6, // Elevasi lebih tinggi
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // Sudut lebih membulat
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0), // Padding lebih besar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Transaksi #${transaction.id ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(transaction.status), // Gunakan chip status
                          ],
                        ),
                        const Divider(height: 24, thickness: 1, color: Colors.grey), // Pembatas
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Pembeli',
                          value: transaction.buyerEmail ?? 'N/A',
                        ),
                        _buildInfoRow(
                          icon: Icons.attach_money,
                          label: 'Harga',
                          value:
                              'IDR ${NumberFormat.currency(locale: 'id', symbol: '').format(transaction.price ?? 0)}',
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Alamat',
                          value: transaction.shippingAddress ?? 'N/A',
                        ),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal',
                          value: transaction.createdAt != null
                              ? DateFormat('dd MMMM yyyy, HH:mm').format(
                                  DateTime.tryParse(transaction.createdAt!) ??
                                      DateTime.now())
                              : 'N/A',
                        ),
                        const SizedBox(height: 20),
                        _buildActionButtonRow(transaction),
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

  // Helper function untuk menampilkan baris informasi
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function untuk menampilkan chip status
  Widget _buildStatusChip(String? status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case 'completed':
        text = 'Selesai';
        color = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case 'paid':
        text = 'Sudah Dibayar';
        color = Colors.blue.shade600;
        icon = Icons.payments_outlined;
        break;
      case 'shipping':
        text = 'Pengiriman'; // Diperpendek dari "Dalam Pengiriman"
        color = Colors.orange.shade600;
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        text = 'Terkirim';
        color = Colors.purple.shade600;
        icon = Icons.archive_outlined;
        break;
      case 'canceled':
        text = 'Dibatalkan';
        color = Colors.red.shade600;
        icon = Icons.cancel_outlined;
        break;
      default:
        text = 'Tidak Diketahui';
        color = Colors.grey.shade600;
        icon = Icons.help_outline;
    }

    return Flexible(
      child: Chip(
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12, // Ukuran font diperkecil untuk menghindari overflow
          ),
          overflow: TextOverflow.ellipsis, // Menangani overflow teks
        ),
        avatar: Icon(icon, color: Colors.white, size: 16), // Ukuran ikon diperkecil
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Padding diperkecil
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Ukuran tap target diperkecil
      ),
    );
  }

  // Helper function untuk tombol aksi
  Widget _buildActionButtonRow(Transaction transaction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (transaction.status == 'paid') // Hanya tampilkan tombol "Proses Pengiriman" jika statusnya "paid"
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateTransactionStatus(
                        transaction,
                        'shipping',
                      ),
              icon: _isUpdatingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: const Text(
                'Proses Pengiriman',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700, // Warna oranye untuk pengiriman
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (transaction.status == 'paid' && transaction.status == 'shipping') // Spasi hanya jika kedua tombol muncul
          const SizedBox(width: 10), // Spasi antar tombol
        if (transaction.status == 'shipping')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateTransactionStatus(
                        transaction,
                        'delivered',
                      ),
              icon: _isUpdatingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Tandai Terkirim',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, // Warna hijau untuk terkirim
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}