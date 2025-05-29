import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';

final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp');

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      favoriteItems = favorites;
    });
  }

  Future<void> _removeFavoriteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedFavorites = List<String>.from(favoriteItems);
    updatedFavorites.removeAt(index);
    await prefs.setStringList('favorites', updatedFavorites);
    setState(() {
      favoriteItems = updatedFavorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Produk Wishlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              favoriteItems.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.teal.withOpacity(0.4),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum ada produk favorit',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, index) {
                      final itemData = jsonDecode(favoriteItems[index]);
                      final itemName = itemData['itemName'] ?? 'Produk';
                      final price = itemData['price'] ?? 0;
                      final imageBase64 = itemData['image'] ?? '';
                      Uint8List? imageBytes;
                      try {
                        if (imageBase64.isNotEmpty) {
                          imageBytes = base64Decode(imageBase64);
                        }
                      } catch (_) {
                        imageBytes = null;
                      }
                      final formattedPrice = currencyFormat.format(price);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading:
                              imageBytes != null
                                  ? Image.memory(
                                    imageBytes,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                          title: Text(
                            itemName,
                            style: const TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.teal,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              await _removeFavoriteAt(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 24),
              const Text(
                'Baru Diupload',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ProductGrid(stream: getPostsStream()),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  const ProductGrid({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
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
                    "Tidak ada produk ditemukan.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
            Uint8List image = Uint8List(0);

            try {
              if (imageBase64.isNotEmpty) {
                image = base64Decode(imageBase64);
              }
            } catch (_) {}

            final itemName = data['itemName'] ?? 'Nama Barang';
            final location = data['location'] ?? 'Lokasi tidak diketahui';
            final price = data['price'];
            final formattedPrice =
                price is num
                    ? currencyFormat.format(price)
                    : price?.toString() ?? '-';

            DateTime createdAt;
            try {
              createdAt = DateTime.parse(data['createdAt']);
            } catch (_) {
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                                  child: const Center(child: Text("No Image")),
                                ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedPrice,
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
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
        );
      },
    );
  }
}

Stream<QuerySnapshot> getPostsStream() {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(6)
      .snapshots();
}
