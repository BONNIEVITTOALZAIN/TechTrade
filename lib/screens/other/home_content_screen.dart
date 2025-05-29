import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:techtrade/screens/cart/cart_screen.dart';
import 'package:techtrade/screens/favorite/favorite_screen.dart';
import 'package:techtrade/screens/other/category_screen.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';
import 'package:techtrade/screens/other/search_screen.dart';
import 'package:shimmer/shimmer.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String productFilter = 'all';
  final user = FirebaseAuth.instance.currentUser;

  String? fullName;

  final List<String> bannerImages = [
    'https://hijra.id/wp-content/uploads/2023/06/161-1024x724.jpg',
    'https://template.canva.com/EAGTPnb3Pe8/2/0/1600w-BmbteSOKUVE.jpg',
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void loadUserData() async {
    if (user != null) {
      final uid = user!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = doc.data()?['fullName'];
      if (name != null && mounted) {
        setState(() {
          fullName = name;
        });
      }
    }
  }

  Stream<QuerySnapshot> getPostsStream() {
    Query query = FirebaseFirestore.instance.collection('posts');

    if (productFilter == 'terbaru') {
      query = query.orderBy('createdAt', descending: true);
    } else if (productFilter == 'terlama') {
      query = query.orderBy('createdAt', descending: false);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hai $fullName!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Text(
              'Selamat datang di TechTrade',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari di TechTrade",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                SearchResultScreen(searchKeyword: value.trim()),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Banner Carousel with Shimmer
              SizedBox(
                height: 160,
                child:
                    bannerImages.isEmpty
                        ? Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                        : CarouselSlider(
                          options: CarouselOptions(
                            height: 160,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(
                              milliseconds: 800,
                            ),
                          ),
                          items:
                              bannerImages.map((url) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: double.infinity,
                                          height: 160,
                                          color: Colors.grey[300],
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error),
                                          ),
                                        ),
                                  ),
                                );
                              }).toList(),
                        ),
              ),

              const SizedBox(height: 24),

              // Kategori Slide Horizontal
              const Text(
                "Kategori produk",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                            kategoriItem("Laptop", Icons.laptop),
                            kategoriItem("Smartphone", Icons.phone_android),
                            kategoriItem("Headset", Icons.headphones),
                            kategoriItem("PC", Icons.desktop_windows),
                            kategoriItem("Mouse", Icons.mouse),
                            kategoriItem("Keyboard", Icons.keyboard),
                            kategoriItem("VGA", Icons.memory),
                            kategoriItem("Storage", Icons.sd_storage),
                            kategoriItem("CPU", Icons.memory),
                            kategoriItem("RAM", Icons.memory),
                            kategoriItem("Console", Icons.videogame_asset),
                            kategoriItem("Controller", Icons.gamepad),
                            kategoriItem("Other", Icons.category),
                          ]
                          .map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: w,
                            ),
                          )
                          .toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Produk
              const Text(
                "Produk Lainnya",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Filter
              Row(
                children: [
                  filterButton("Semua", 'all'),
                  const SizedBox(width: 8),
                  filterButton("Terbaru", 'terbaru'),
                  const SizedBox(width: 8),
                  filterButton("Terlama", 'terlama'),
                ],
              ),
              const SizedBox(height: 16),

              // Produk Grid with Shimmer loading
              StreamBuilder<QuerySnapshot>(
                stream: getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3 / 5,
                          ),
                      itemBuilder: (_, __) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.width /
                                      2 *
                                      (3 / 5) *
                                      0.6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Container(
                                    height: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Container(
                                    height: 16,
                                    width: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Container(
                                    height: 14,
                                    width: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Tidak ada produk ditemukan."),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      String formattedPrice =
                          price is num
                              ? currencyFormat.format(price)
                              : price.toString();

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
                                    averageRating:
                                        (data['averageRating'] ?? 0.0),
                                    condition: docs[index].get('condition'),
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
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child:
                                      image.isNotEmpty
                                          ? Image.memory(
                                            image,
                                            fit: BoxFit.cover,
                                          )
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedPrice,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
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
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget kategoriItem(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(categoryLabel: label),
          ),
        );
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.withOpacity(0.1),
              child: Icon(icon, color: Colors.teal, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterButton(String label, String value) {
    final bool selected = productFilter == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            productFilter = value;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.teal : Colors.grey.shade300,
          foregroundColor: selected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
