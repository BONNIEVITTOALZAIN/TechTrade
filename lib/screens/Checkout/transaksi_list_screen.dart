import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techtrade/screens/Checkout/transaksi_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with TickerProviderStateMixin {
  bool _localeInitialized = false;
  String _selectedFilter = 'Semua';
  late TabController _tabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];

  final List<String> _filterOptions = [
    'Semua',
    'Berhasil',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeLocale();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _localeInitialized = true;
      });
    } catch (e) {
      print("Error initializing locale: $e");
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Cek apakah user sudah login
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User belum login';
          _isLoading = false;
        });
        return;
      }

      // Query transaksi berdasarkan userId dari current user
      // Menggunakan query yang lebih sederhana untuk menghindari composite index
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('transactions')
              .where(
                'userId',
                isEqualTo: currentUser.uid,
              ) // Filter berdasarkan userId
              .get();

      List<Map<String, dynamic>> loadedTransactions = [];

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['transactionDate'] is Timestamp) {
          data['transactionDate'] =
              (data['transactionDate'] as Timestamp).toDate();
        }

        if (data['items'] != null) {
          data['items'] = List<Map<String, dynamic>>.from(data['items']);
        }

        data['id'] = data['transactionId'] ?? doc.id;
        data['date'] = data['transactionDate'] ?? DateTime.now();
        data['address'] = data['selectedAddress'] ?? '';
        data['courier'] = data['selectedCourier'] ?? '';

        loadedTransactions.add(data);
      }

      // Sort secara manual berdasarkan tanggal transaksi (descending)
      loadedTransactions.sort((a, b) {
        DateTime dateA = a['transactionDate'] ?? a['date'] ?? DateTime.now();
        DateTime dateB = b['transactionDate'] ?? b['date'] ?? DateTime.now();
        return dateB.compareTo(dateA); // Descending order
      });

      setState(() {
        _transactions = loadedTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading transactions: ${e.toString()}';
        _isLoading = false;
      });
      print("Error loading transactions: $e");
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  String _formatCurrency(num amount) {
    try {
      if (_localeInitialized) {
        return NumberFormat('#,##0', 'id_ID').format(amount);
      } else {
        return NumberFormat('#,##0').format(amount);
      }
    } catch (e) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
  }

  String _formatDate(DateTime date) {
    try {
      if (_localeInitialized) {
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(date);
      }
    } catch (e) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Berhasil':
        return Colors.green;
      case 'Dikirim':
        return Colors.blue;
      case 'Selesai':
        return Colors.teal;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Berhasil':
        return Icons.check_circle;
      case 'Dikirim':
        return Icons.local_shipping;
      case 'Selesai':
        return Icons.done_all;
      case 'Dibatalkan':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (_selectedFilter == 'Semua') {
      return _transactions;
    }
    return _transactions
        .where((transaction) => transaction['status'] == _selectedFilter)
        .toList();
  }

  void _navigateToTransactionDetail(Map<String, dynamic> transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TransactionDetailScreen(
              transactionId:
                  transaction['transactionId'] ?? transaction['id'] ?? '',
              items: List<Map<String, dynamic>>.from(
                transaction['items'] ?? [],
              ),
              selectedAddress: transaction['selectedAddress'] ?? '',
              selectedCourier: transaction['selectedCourier'] ?? '',
              itemsTotal: (transaction['itemsTotal'] ?? 0).toDouble(),
              shippingCost: (transaction['shippingCost'] ?? 0).toDouble(),
              totalPrice: (transaction['totalPrice'] ?? 0).toDouble(),
              transactionDate:
                  transaction['transactionDate'] ??
                  transaction['date'] ??
                  DateTime.now(),
            ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final items = (transaction['items'] as List<Map<String, dynamic>>?) ?? [];

    if (items.isEmpty) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No items available for transaction ${transaction['id']}',
          ),
        ),
      );
    }

    final firstItem = items.first;
    final remainingCount = items.length - 1;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction['id'] ?? 'Unknown ID',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        transaction['status'] ?? 'Unknown',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(transaction['status'] ?? 'Unknown'),
                          size: 14,
                          color: _getStatusColor(
                            transaction['status'] ?? 'Unknown',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction['status'] ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(
                              transaction['status'] ?? 'Unknown',
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(
                      transaction['transactionDate'] ??
                          transaction['date'] ??
                          DateTime.now(),
                    ),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildItemImage(firstItem['image']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItem['itemName'] ?? 'Unknown Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingCount > 0
                              ? '+ ${remainingCount} produk lainnya'
                              : 'Qty: ${firstItem['quantity'] ?? 0}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Divider(color: Colors.grey.shade300, height: 1),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Rp${_formatCurrency(transaction['totalPrice'] ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction['selectedCourier'] ??
                            transaction['courier'] ??
                            'Unknown',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi Anda akan muncul di sini\nsetelah melakukan pembelian',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Gagal memuat data transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage == 'User belum login') ...[
                ElevatedButton(
                  onPressed: () {
                    // Navigate to login screen
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: _loadTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat transaksi...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 20);
    }

    try {
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',').last;
      }
      Uint8List? imageBytes = base64Decode(cleanBase64);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            print("Error loading base64 image: $error");
            return Icon(
              Icons.inventory_2,
              color: Colors.grey.shade600,
              size: 20,
            );
          },
        ),
      );
    } catch (e) {
      print("Error decoding base64 image: $e");
      return Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _filterOptions.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.teal.shade100,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.teal.shade700
                                          : Colors.grey.shade700,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? Colors.teal.shade300
                                          : Colors.grey.shade300,
                                ),
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
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : _getFilteredTransactions().isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _refreshTransactions,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _getFilteredTransactions().length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(
                      _getFilteredTransactions()[index],
                    );
                  },
                ),
              ),
    );
  }
}
