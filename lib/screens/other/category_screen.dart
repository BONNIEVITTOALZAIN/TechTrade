import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryLabel;

  const CategoryScreen({Key? key, required this.categoryLabel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .where('category', isEqualTo: categoryLabel)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    size: 80,
                    color: Colors.teal.withOpacity(0.4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Produk tidak ditemukan di kategori ini.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 5,
              ),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final images = List<String>.from(data['images'] ?? []);
                final imageBase64 = images.isNotEmpty ? images[0] : '';
                Uint8List image =
                    imageBase64.isNotEmpty
                        ? base64Decode(imageBase64)
                        : Uint8List(0);

                final itemName = data['itemName'] ?? 'Nama Barang';
                final location = data['location'] ?? 'Lokasi tidak diketahui';
                final price = data['price'] ?? '-';

                String formattedPrice = '-';
                if (price is num) {
                  formattedPrice = currencyFormat.format(price);
                } else if (price is String) {
                  formattedPrice = price;
                }

                DateTime createdAt;
                try {
                  createdAt = DateTime.parse(data['createdAt']);
                } catch (e) {
                  createdAt = DateTime.now();
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DetailScreen(
                              imagesBase64: images,
                              description: data['description'] ?? '',
                              createdAt: createdAt,
                              fullName: data['fullName'] ?? 'Anonim',
                              location: location,
                              category: data['category'] ?? '',
                              itemName: itemName,
                              price: data['price'],
                              stock: data['stock'],
                              weight: data['weight'],
                              heroTag: 'post-$index',
                              productId: docs[index].id,
                              averageRating: (data['averageRating'] ?? 0.0),
                              condition: data['condition'],
                            ),
                      ),
                    );
                  },
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Colors.teal.withOpacity(0.15),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child:
                                image.isNotEmpty
                                    ? Image.memory(image, fit: BoxFit.cover)
                                    : Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formattedPrice,
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
