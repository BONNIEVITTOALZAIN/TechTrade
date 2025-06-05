import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryLabel;

  const CategoryScreen({super.key, required this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .where('category', isEqualTo: categoryLabel)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Produk tidak ditemukan di kategori ini.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
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
                              userId: data['userId'],
                            ),
                      ),
                    );
                  },
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    color: theme.cardColor,
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
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: 0.5),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                        size: 40,
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formattedPrice,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
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
