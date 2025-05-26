import 'dart:convert';
import 'dart:typed_data';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/setting/account_screen.dart';
import 'package:techtrade/screens/other/add_post_screen.dart';
import 'package:techtrade/screens/other/category_screen.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';
import 'package:techtrade/screens/AuthScreen/sign_in_screen.dart';
import 'package:techtrade/screens/other/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchKeyword = '';
  String productFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> bannerImages = [
    'https://hijra.id/wp-content/uploads/2023/06/161-1024x724.jpg',
    'https://template.canva.com/EAGTPnb3Pe8/2/0/1600w-BmbteSOKUVE.jpg',
  ];

  // Format waktu menjadi string relatif
  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inHours < 48) return 'Kemarin';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  // Fungsi keluar akun
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  // filter
  Stream<QuerySnapshot> getPostsStream() {
    Query query = FirebaseFirestore.instance.collection('posts');

    if (productFilter == 'terbaru') {
      query = query.orderBy('createdAt', descending: true);
    } else if (productFilter == 'terlama') {
      query = query.orderBy('createdAt', descending: false);
    } else {
      query = query.orderBy('createdAt', descending: true);
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TechTrade',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.teal,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_2_outlined),
                        tooltip: 'Profil',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari produk...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  setState(() {
                    searchKeyword = value.trim();
                  });
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

              // Banner Promosi
              CarouselSlider(
                options: CarouselOptions(
                  height: 160,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                ),
                items:
                    bannerImages.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 24),

              // Kategori
              const Text(
                "Kategori",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    kategoriItem(context, "Sepatu", Icons.laptop),
                    kategoriItem(context, "Smartphone", Icons.phone_android),
                    kategoriItem(context, "Aksesoris", Icons.headphones),
                    kategoriItem(context, "PC", Icons.desktop_windows),
                    kategoriItem(context, "Mouse", Icons.mouse),
                    kategoriItem(context, "Keyboard", Icons.keyboard),
                    kategoriItem(context, "PC", Icons.desktop_windows),
                    kategoriItem(context, "Vga", Icons.memory),
                    kategoriItem(context, "Cpu", Icons.memory),
                    kategoriItem(context, "Storage", Icons.sd_storage),
                    kategoriItem(context, "Ram", Icons.memory),
                    kategoriItem(context, "Console", Icons.videogame_asset),
                    kategoriItem(context, "Controller", Icons.gamepad),
                    kategoriItem(context, "Headphone", Icons.headphones),
                    kategoriItem(context, "Laptop", Icons.laptop),
                    kategoriItem(context, "Other", Icons.devices_other),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Judul Produk
              Text(
                "Semua Produk",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  filterButton('All', 'all'),
                  const SizedBox(width: 7),
                  filterButton('Terbaru', 'terbaru'),
                  const SizedBox(width: 7),
                  filterButton('Terlama', 'terlama'),
                ],
              ),

              const SizedBox(height: 6),

              // StreamBuilder produk
              StreamBuilder<QuerySnapshot>(
                stream: getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text("Tidak ada produk ditemukan.")),
                    );
                  }

                  // Ambil data dan filter manual jika ada pencarian
                  final docs = snapshot.data!.docs;

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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 5,
                        ),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      // Ambil list images base64
                      final images = List<String>.from(data['images'] ?? []);
                      final imageBase64 = images.isNotEmpty ? images[0] : '';

                      Uint8List image = Uint8List(0);
                      try {
                        if (imageBase64.isNotEmpty) {
                          image = base64Decode(imageBase64);
                        }
                      } catch (e) {
                        image = Uint8List(0);
                      }

                      final itemName = data['itemName'] ?? 'Nama Barang';
                      final location =
                          data['location'] ?? 'Lokasi tidak diketahui';
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
                                    latitude: data['latitude'],
                                    longitude: data['longitude'],
                                    location: location,
                                    category: data['category'] ?? '',
                                    itemName: itemName,
                                    price: data['price'],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPostScreen()),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget kategori item horizontal
  Widget kategoriItem(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryScreen(categoryLabel: label),
            ),
          );
        },
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.1),
              child: Icon(icon, color: Colors.teal),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Widget tombol filter produk
  Widget filterButton(String label, String filterValue) {
    final bool isSelected = productFilter == filterValue;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          productFilter = filterValue;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(60, 28),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
