import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techtrade/screens/Checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<bool> isCheckedList = [];
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getStringList('cart') ?? [];
    final items =
        cartData.map((item) {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          decoded['quantity'] = decoded['quantity'] ?? 1;
          decoded['stock'] = decoded['stock'] ?? 10;
          return decoded;
        }).toList();

    setState(() {
      cartItems = items;
      isCheckedList = List<bool>.filled(items.length, false).toList();
    });
  }

  Future<void> saveCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartData = cartItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cart', cartData);
  }

  Future<void> removeFromCart(int index) async {
    final isChecked = isCheckedList[index];

    if (isChecked) {
      final removedItem = cartItems[index];
      cartItems.removeAt(index);
      isCheckedList.removeAt(index);

      await saveCartItems();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedItem['itemName']} dihapus dari keranjang'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              setState(() {
                cartItems.insert(index, removedItem);
                isCheckedList.insert(index, false);
              });
              await saveCartItems();
            },
          ),
        ),
      );
    } else {
      // Jika belum dipilih, jangan hapus, cuma kasih notif
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih item terlebih dahulu sebelum menghapus'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      isCheckedList = List<bool>.filled(cartItems.length, selectAll);
    });
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0 && newQuantity <= cartItems[index]['stock']) {
      setState(() {
        cartItems[index]['quantity'] = newQuantity;
      });
      saveCartItems();
    }
  }

  double getTotal() {
    double total = 0.0;
    for (int i = 0; i < cartItems.length; i++) {
      if (isCheckedList[i]) {
        final price = (cartItems[i]['price'] as num).toDouble();
        final quantity = cartItems[i]['quantity'] ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  int getSelectedItemsCount() {
    return isCheckedList.where((isChecked) => isChecked).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja (${cartItems.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Hapus Semua'),
                        content: const Text(
                          'Yakin ingin menghapus semua item dari keranjang?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                cartItems.clear();
                                isCheckedList.clear();
                              });
                              await saveCartItems();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              child: const Text(
                'Hapus Semua',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty ? _buildEmptyCart() : _buildCartList(),
      bottomNavigationBar: cartItems.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Masih Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk, mulai belanja dan tambahkan produk ke keranjang',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Mulai Belanja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: selectAll,
                onChanged: (_) => toggleSelectAll(),
                activeColor: Colors.teal,
              ),
              const Text(
                'Pilih Semua',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (getSelectedItemsCount() > 0)
                Text(
                  '${getSelectedItemsCount()} item dipilih',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cartItems.length,
            itemBuilder: (context, index) => _buildCartItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(int index) {
    final item = cartItems[index];
    final imageBytes = base64Decode(item['image']);
    final isSelected = isCheckedList[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      isCheckedList[index] = value!;
                      selectAll = isCheckedList.every((checked) => checked);
                    });
                  },
                  activeColor: Colors.teal,
                ),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(imageBytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['itemName'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          if (item['originalPrice'] != null) ...[
                            Text(
                              'Rp${NumberFormat('#,##0', 'id_ID').format(item['originalPrice'])}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'Rp${NumberFormat('#,##0', 'id_ID').format(item['price'])}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (item['stock'] != null)
                        Text(
                          'Stok: ${item['stock']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  onPressed: () => removeFromCart(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.teal[400],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (cartItems[index]['quantity'] > 1) {
                            updateQuantity(
                              index,
                              cartItems[index]['quantity'] - 1,
                            );
                          }
                        },
                        icon: const Icon(Icons.remove),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${cartItems[index]['quantity']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final maxStock = item['stock'] ?? 999;
                          if (cartItems[index]['quantity'] < maxStock) {
                            updateQuantity(
                              index,
                              cartItems[index]['quantity'] + 1,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Jumlah melebihi stok yang tersedia',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  'Rp${NumberFormat('#,##0', 'id_ID').format((item['price'] as num) * item['quantity'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = getSelectedItemsCount();
    final total = getTotal();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ($selectedCount item)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp${NumberFormat('#,##0', 'id_ID').format(total)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedCount > 0
                            ? () async {
                              final selectedItems = <Map<String, dynamic>>[];
                              final selectedIndexes = <int>[];

                              for (int i = 0; i < isCheckedList.length; i++) {
                                if (isCheckedList[i]) {
                                  selectedItems.add(cartItems[i]);
                                  selectedIndexes.add(i);
                                }
                              }

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          CheckoutScreen(items: selectedItems),
                                ),
                              );

                              if (result == true) {
                                setState(() {
                                  for (
                                    int i = selectedIndexes.length - 1;
                                    i >= 0;
                                    i--
                                  ) {
                                    cartItems.removeAt(selectedIndexes[i]);
                                    isCheckedList.removeAt(selectedIndexes[i]);
                                  }
                                  saveCartItems();
                                });
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      selectedCount > 0
                          ? 'Checkout ($selectedCount)'
                          : 'Pilih Item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
