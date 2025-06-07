import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import 'package:timezone/timezone.dart' as tz; 
import 'package:timezone/data/latest.dart' as tz; 
import '../models/transactionModel.dart'; 
import '../services/transactionService.dart'; 
import '../services/petInSaleService.dart';
import '../models/petInSaleModel.dart';
import 'petDetailPage.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String? _buyerEmail;
  Future<List<Transaction>>? _transactionsFuture; 
  String _selectedTimeZoneId = 'Asia/Jakarta'; 

  final Map<String, String> _timeZoneMap = {
    'WIB (Jakarta)': 'Asia/Jakarta',
    'WITA (Makassar)': 'Asia/Makassar',
    'WIT (Jayapura)': 'Asia/Jayapura',
    'London (UTC+1)': 'Europe/London',
    'New York (UTC-4)': 'America/New_York',
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); 
    _loadPreferencesAndTransactions();
  }

  Future<void> _loadPreferencesAndTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    _buyerEmail = prefs.getString('username');
    _selectedTimeZoneId = prefs.getString('selectedTimeZone') ?? 'Asia/Jakarta';

    if (_buyerEmail != null) {
      setState(() {
        _transactionsFuture = _fetchTransactions(_buyerEmail!);
      });
    } else {
      setState(() {
        _transactionsFuture = Future.error(
          'Email pengguna tidak ditemukan. Harap login kembali.',
        );
      });
    }
  }

  Future<List<Transaction>> _fetchTransactions(String email) async {
    try {
      final Map<String, dynamic> response =
          await TransactionApi.getTransactionByBuyerEmail(email);

      if (response['status'] == 'success' && response['data'] != null) {
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

  String _formatDateTimeWithTimeZone(
      String? dateTimeString, String targetTimeZoneId) {
    if (dateTimeString == null) {
      return 'N/A';
    }
    try {
      final DateTime originalUtcDateTime =
          DateTime.parse(dateTimeString).toUtc();

      final location = tz.getLocation(targetTimeZoneId);

      final tz.TZDateTime convertedDateTime =
          tz.TZDateTime.from(originalUtcDateTime, location);

      final formatter = DateFormat('dd/MM/yyyy HH:mm:ss zzz');
      return formatter.format(convertedDateTime);
    } catch (e) {
      print('Error formatting date/time: $e'); 
      return 'Invalid Date';
    }
  }

  Widget _buildTransactionItem(Transaction transaction) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    switch (transaction.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () async {
        if (transaction.animalId != null) {
          try {
            final Map<String, dynamic> petData =
                await PetInSaleApi.getPetInSaleById(transaction.animalId!);

            if (petData['error'] != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Error memuat detail hewan peliharaan: ${petData['error']}')),
              );
              return;
            }

            final PetInSale pet = PetInSale.fromJson(petData);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PetDetailPage(pet: pet)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat detail hewan peliharaan: $e'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID hewan peliharaan tidak tersedia.'),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi ID: ${transaction.id ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50), 
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 24),
                ],
              ),
              const Divider(height: 16, thickness: 1), 
              _buildInfoRow(
                'Hewan:',
                transaction.animalId.toString(),
                Icons.pets,
              ),
              _buildInfoRow(
                'Penjual:',
                transaction.sellerEmail ?? 'N/A',
                Icons.store,
              ),
              _buildInfoRow(
                'Pembeli:',
                transaction.buyerEmail ?? 'N/A',
                Icons.person,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Harga: IDR ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 2).format(transaction.price ?? 0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20), 
                const SizedBox(width: 8),
                Text(
                  'Status: ${transaction.status ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: statusColor, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alamat Pengiriman: ${transaction.shippingAddress ?? 'N/A'}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tanggal: ${_formatDateTimeWithTimeZone(transaction.createdAt, _selectedTimeZoneId)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Container(
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade50, 
        ),
        child: _buyerEmail == null
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
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.green, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'Zona Waktu:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedTimeZoneId,
                                dropdownColor: Colors.white,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.green, 
                                ),
                                style: const TextStyle(color: Colors.black87, fontSize: 16),
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedTimeZoneId = newValue;
                                    });
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'selectedTimeZone', newValue);
                                    _loadPreferencesAndTransactions();
                                  }
                                },
                                items: _timeZoneMap.keys
                                    .map<DropdownMenuItem<String>>(
                                        (String key) {
                                      return DropdownMenuItem<String>(
                                        value: _timeZoneMap[key],
                                        child: Text(
                                          key, 
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Transaction>>(
                      future: _transactionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                
                                const SizedBox(height: 20),
                                const Text('Memuat transaksi fauna...',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.green)),
                              ],
                            ),
                          );
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _loadPreferencesAndTransactions, 
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Coba Lagi',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Tidak ada transaksi yang ditemukan.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Mulai jelajahi hewan peliharaan kami untuk melakukan pembelian pertama Anda!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
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
                  ),
                ],
              ),
      ),
    );
  }
}