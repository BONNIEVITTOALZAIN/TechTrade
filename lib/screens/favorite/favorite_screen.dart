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
  List<DocumentSnapshot> favoriteProducts = []; // To store fetched product data

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteProductIds =
        prefs.getStringList('favoriteProductIds') ??
        []; // Assuming you save IDs as a list

    if (favoriteProductIds.isEmpty) {
      setState(() {
        favoriteProducts = [];
      });
      return;
    }

    // Fetch product details for each favorite ID
    List<DocumentSnapshot> fetchedProducts = [];
    for (String productId in favoriteProductIds) {
      try {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(productId)
                .get();
        if (doc.exists) {
          fetchedProducts.add(doc);
        } else {
          // If a favorite product no longer exists in Firestore, remove it from SharedPreferences
          favoriteProductIds.remove(productId);
          prefs.setStringList('favoriteProductIds', favoriteProductIds);
        }
      } catch (e) {
        print("Error fetching favorite product $productId: $e");
      }
    }

    setState(() {
      favoriteProducts = fetchedProducts;
    });
  }

  Future<void> _removeFavorite(String productIdToRemove) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteProductIds =
        prefs.getStringList('favoriteProductIds') ?? [];

    favoriteProductIds.remove(productIdToRemove);
    await prefs.setStringList('favoriteProductIds', favoriteProductIds);

    _loadFavorites(); // Reload favorites to update the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Produk Favorit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              favoriteProducts.isEmpty
                  ? const Center(child: Text('Belum ada produk favorit'))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favoriteProducts.length,
                    itemBuilder: (context, index) {
                      final doc = favoriteProducts[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final images = List<String>.from(data['images'] ?? []);
                      final imageBase64 = images.isNotEmpty ? images[0] : '';
                      Uint8List image = Uint8List(0);
                      try {
                        if (imageBase64.isNotEmpty) {
                          image = base64Decode(imageBase64);
                        }
                      } catch (_) {}

                      final itemName = data['itemName'] ?? 'Nama Barang';
                      final description =
                          data['description'] ?? 'Deskripsi tidak tersedia';
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
                      final fullName = data['fullName'] ?? 'Anonim';
                      final location =
                          data['location'] ?? 'Lokasi tidak diketahui';
                      final category = data['category'] ?? '';
                      final stock = data['stock'];
                      final weight = data['weight'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DetailScreen(
                                      imagesBase64: images,
                                      description: description,
                                      createdAt: createdAt,
                                      fullName: fullName,
                                      location: location,
                                      category: category,
                                      itemName: itemName,
                                      price: price,
                                      stock: stock,
                                      weight: weight,
                                      heroTag:
                                          'favorite-post-$index', // Unique heroTag
                                    ),
                              ),
                            ).then(
                              (_) => _loadFavorites(),
                            ); // Reload after returning from detail screen
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: SizedBox(
                              width: 80, // Adjust size as needed
                              height: 80, // Adjust size as needed
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child:
                                    image.isNotEmpty
                                        ? Image.memory(image, fit: BoxFit.cover)
                                        : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),
                            title: Text(
                              itemName,
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await _removeFavorite(doc.id);
                              },
                            ),
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
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text("Tidak ada produk ditemukan.")),
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
            final doc = docs[index]; // Get the DocumentSnapshot
            final data = doc.data() as Map<String, dynamic>;
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
                          price: price,
                          stock: data['stock'],
                          weight: data['weight'],
                          heroTag: 'post-$index',
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
