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
    cartItems.removeAt(index);
    await saveCartItems();
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          cartItems.isEmpty
              ? const Center(child: Text('Keranjang masih kosong'))
              : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final imageBytes = base64Decode(item['image']);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isCheckedList[index],
                                onChanged: (value) {
                                  setState(() {
                                    isCheckedList[index] = value!;
                                  });
                                },
                              ),
                              Image.memory(
                                Uint8List.fromList(imageBytes),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item['originalPrice'] != null)
                                          Text(
                                            'Rp${NumberFormat('#,##0', 'id_ID').format(item['originalPrice'])}',
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Rp${NumberFormat('#,##0', 'id_ID').format(item['price'])}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (cartItems[index]['quantity'] > 1) {
                                      cartItems[index]['quantity']--;
                                      saveCartItems();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${cartItems[index]['quantity']}'),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    cartItems[index]['quantity'] =
                                        (cartItems[index]['quantity'] ?? 1) + 1;
                                    saveCartItems();
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                onPressed: () => removeFromCart(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar:
          cartItems.isEmpty
              ? null
              : Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Rp${NumberFormat('#,##0', 'id_ID').format(getTotal())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final selectedItems = <Map<String, dynamic>>[];
                        final selectedIndexes = <int>[];

                        for (int i = 0; i < isCheckedList.length; i++) {
                          if (isCheckedList[i]) {
                            selectedItems.add(cartItems[i]);
                            selectedIndexes.add(i);
                          }
                        }

                        if (selectedItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pilih minimal satu produk untuk checkout',
                              ),
                            ),
                          );
                          return;
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Beli'),
                    ),
                  ],
                ),
              ),
    );
  }
}
