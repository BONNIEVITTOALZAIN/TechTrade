import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/cart/cart_screen.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';
import 'package:techtrade/screens/favorite/favorite_screen.dart';
import 'package:techtrade/screens/setting/setting_screen.dart';

final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Stream<QuerySnapshot> getPostsStream() {
    return FirebaseFirestore.instance.collection('posts').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                final fullName = userData?['fullName'] ?? 'Nama Pengguna';
                final photo = userData?['photo'] ?? '';
                ImageProvider profileImage;

                if (photo.startsWith('http')) {
                  profileImage = NetworkImage(photo);
                } else if (photo.isNotEmpty) {
                  try {
                    final Uint8List bytes = base64Decode(photo);
                    profileImage = MemoryImage(bytes);
                  } catch (_) {
                    profileImage = const AssetImage(
                      'assets/default_profile.png',
                    );
                  }
                } else {
                  profileImage = const AssetImage('assets/default_profile.png');
                }

                return Row(
                  children: [
                    CircleAvatar(radius: 32, backgroundImage: profileImage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      color: Colors.teal,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritesScreen()),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'WishList',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen()),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.blueGrey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text('Cart', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rekomendasi
            const Text(
              "Rekomendasi Untuk Anda",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Produk Card (Grid)
            StreamBuilder<QuerySnapshot>(
              stream: getPostsStream(),
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
                    final location =
                        data['location'] ?? 'Lokasi tidak diketahui';
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
                                          child: const Center(
                                            child: Text("No Image"),
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
