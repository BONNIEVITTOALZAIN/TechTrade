import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutScreen extends StatefulWidget {
  final double price;
  final String itemName;
  final int stock;

  const CheckoutScreen({
    super.key,
    required this.price,
    required this.itemName,
    required this.stock,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController newAddressController = TextEditingController();

  List<String> addresses = [
    "Jl. Merdeka No. 10, Jakarta",
    "Jl. Sudirman No. 22, Bandung",
  ];
  int selectedAddressIndex = 0;

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

  double get shippingCost => courierCosts[selectedCourier] ?? 0;
  double get totalPrice => widget.price + shippingCost;

  Future<void> reduceStock() async {
    try {
      final postQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId')
              .where('itemName', isEqualTo: widget.itemName)
              .limit(1)
              .get();

      if (postQuery.docs.isEmpty) {
        throw Exception("Produk tidak ditemukan");
      }

      final doc = postQuery.docs.first;
      final docRef = doc.reference;
      final currentStock = doc['stock'];

      if (currentStock >= 1) {
        await docRef.update({'stock': currentStock - 1});
      } else {
        throw Exception("Stok habis");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengurangi stok: $e")));
    }
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

  void checkout() async {
    await reduceStock();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pembelian berhasil!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    newAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text("Checkout"),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Alamat Pengiriman"),
            ...addresses.asMap().entries.map((entry) {
              final idx = entry.key;
              final addr = entry.value;
              return Card(
                color:
                    selectedAddressIndex == idx
                        ? Colors.green.shade50
                        : Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        selectedAddressIndex == idx
                            ? Colors.green
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: RadioListTile<int>(
                  value: idx,
                  groupValue: selectedAddressIndex,
                  onChanged:
                      (val) => setState(() => selectedAddressIndex = val ?? 0),
                  title: Text(addr),
                ),
              );
            }),
            TextButton.icon(
              onPressed: showAddAddressDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Tambah Alamat Baru"),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Pilih Kurir"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCourier,
                  isExpanded: true,
                  items:
                      couriers.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                  onChanged:
                      (val) => setState(
                        () => selectedCourier = val ?? selectedCourier,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Rincian Biaya"),
            _buildCostTile("Harga Barang", widget.price),
            _buildCostTile("Ongkir - $selectedCourier", shippingCost),
            const Divider(),
            _buildCostTile("Total Bayar", totalPrice),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Bayar Sekarang",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCostTile(String label, double value, {bool highlight = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          fontSize: highlight ? 16 : 15,
        ),
      ),
      trailing: Text(
        "Rp ${value.toStringAsFixed(0)}",
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          fontSize: highlight ? 16 : 15,
          color: highlight ? Colors.green.shade700 : Colors.black87,
        ),
      ),
    );
  }
}
