import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController newAddressController = TextEditingController();
  List<String> addresses = [];
  int selectedAddressIndex = 0;
  bool isLoading = true;

  List<String> couriers = [
    "JNE Regular",
    "JNE Express",
    "J&T Regular",
    "J&T Express",
  ];
  String selectedCourier = "JNE Regular";

  Map<String, double> courierCosts = {
    "JNE Regular": 15000,
    "JNE Express": 30000,
    "J&T Regular": 14000,
    "J&T Express": 28000,
  };

  double get itemsTotal => widget.items.fold(
    0.0,
    (sum, item) =>
        sum + ((item['price'] as num).toDouble() * (item['quantity'] ?? 1)),
  );

  double get shippingCost => courierCosts[selectedCourier] ?? 0;
  double get totalPrice => itemsTotal + shippingCost;

  @override
  void initState() {
    super.initState();
    fetchUserLocations();
  }

  Future<void> fetchUserLocations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('locations')
              .orderBy('timestamp', descending: true)
              .get();

      final newAddresses =
          snapshot.docs
              .map((doc) => doc['alamat']?.toString() ?? '')
              .where((alamat) => alamat.isNotEmpty)
              .toList();

      setState(() {
        addresses = newAddresses;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching locations: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> reduceStock() async {
    for (var item in widget.items) {
      final itemName = item['itemName'];
      final qty = item['quantity'] ?? 1;

      final query =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('itemName', isEqualTo: itemName)
              .limit(1)
              .get();

      if (query.docs.isEmpty) continue;

      final doc = query.docs.first;
      final currentStock = doc['stock'];
      final newStock = (currentStock - qty).clamp(0, currentStock);

      await doc.reference.update({'stock': newStock});
    }
  }

  void checkout() async {
    await reduceStock();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pembelian berhasil!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  void showAddAddressDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Alamat Baru"),
            content: TextField(
              controller: newAddressController,
              decoration: const InputDecoration(
                hintText: "Contoh: Jl. Contoh No. 123, Kota",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: addNewAddress,
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  void addNewAddress() {
    final newAddr = newAddressController.text.trim();
    if (newAddr.isNotEmpty) {
      setState(() {
        addresses.add(newAddr);
        selectedAddressIndex = addresses.length - 1;
      });
      newAddressController.clear();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    newAddressController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );

  Widget _buildCostTile(String label, double amount, {bool isTotal = false}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
        trailing: Text(
          'Rp${NumberFormat('#,##0', 'id_ID').format(amount)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 16,
            color: isTotal ? Colors.teal.shade700 : Colors.black87,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      "Alamat Pengiriman",
                      icon: Icons.location_on,
                    ),
                    if (addresses.isEmpty)
                      const Text("Tidak ada alamat ditemukan."),
                    ...addresses.asMap().entries.map((entry) {
                      final idx = entry.key;
                      return Card(
                        elevation: selectedAddressIndex == idx ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                selectedAddressIndex == idx
                                    ? Colors.teal
                                    : Colors.grey.shade300,
                            width: selectedAddressIndex == idx ? 2 : 1,
                          ),
                        ),
                        color:
                            selectedAddressIndex == idx
                                ? Colors.teal.shade50
                                : Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: RadioListTile<int>(
                          value: idx,
                          groupValue: selectedAddressIndex,
                          onChanged:
                              (val) => setState(
                                () => selectedAddressIndex = val ?? 0,
                              ),
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              color:
                                  selectedAddressIndex == idx
                                      ? Colors.teal.shade900
                                      : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: showAddAddressDialog,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text("Tambah Alamat Baru"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal.shade700,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      "Produk Dibeli",
                      icon: Icons.shopping_bag,
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              item['itemName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text("Qty: ${item['quantity']}"),
                            trailing: Text(
                              'Rp${NumberFormat('#,##0', 'id_ID').format((item['price'] as num) * item['quantity'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSectionTitle(
                      "Pilih Kurir",
                      icon: Icons.local_shipping,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCourier,
                      items:
                          couriers
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => selectedCourier = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      "Rincian Biaya",
                      icon: Icons.receipt_long,
                    ),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            _buildCostTile("Total Barang", itemsTotal),
                            const SizedBox(height: 6),
                            _buildCostTile(
                              "Ongkir - $selectedCourier",
                              shippingCost,
                            ),
                            const Divider(height: 32, thickness: 1.2),
                            _buildCostTile(
                              "Total Bayar",
                              totalPrice,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: checkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            shadowColor: Colors.black,
          ),
          child: const Text(
            "Bayar Sekarang",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
