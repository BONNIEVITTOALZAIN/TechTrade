import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techtrade/screens/Checkout/checkout_screen.dart';
import 'package:techtrade/screens/detail/full_image_screen.dart';
import 'package:techtrade/screens/detail/review_screen.dart';

class DetailScreen extends StatefulWidget {
  final List<String> imagesBase64;
  final String description;
  final DateTime createdAt;
  final String fullName;
  final String category;
  final String itemName;
  final double price;
  final int stock;
  final double weight;
  final String heroTag;
  final String location;
  final String productId;
  final double averageRating;

  const DetailScreen({
    Key? key,
    required this.imagesBase64,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.category,
    required this.itemName,
    required this.price,
    required this.stock,
    required this.weight,
    required this.heroTag,
    required this.location,
    required this.productId,
    required this.averageRating,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    final currentItem = jsonEncode({
      'itemName': widget.itemName,
      'price': widget.price,
      'stock': widget.stock,
      'image': widget.imagesBase64.first,
    });

    setState(() {
      isFavorite = favorites.contains(currentItem);
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    final currentItem = jsonEncode({
      'itemName': widget.itemName,
      'price': widget.price,
      'stock': widget.stock,
      'image': widget.imagesBase64.first,
    });

    setState(() => isFavorite = !isFavorite);

    if (isFavorite) {
      if (!favorites.contains(currentItem)) {
        favorites.add(currentItem);
        await prefs.setStringList('favorites', favorites);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk ditambahkan ke favorit')),
        );
      }
    } else {
      if (favorites.contains(currentItem)) {
        favorites.remove(currentItem);
        await prefs.setStringList('favorites', favorites);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk dihapus dari favorit')),
        );
      }
    }
  }

  Future<void> addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cart = prefs.getStringList('cart') ?? [];
    final currentItem = jsonEncode({
      'itemName': widget.itemName,
      'price': widget.price,
      'stock': widget.stock,
      'image': widget.imagesBase64.first,
      'quantity': 1,
    });
    if (!cart.contains(currentItem)) {
      cart.add(currentItem);
      await prefs.setStringList('cart', cart);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ada di keranjang')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAtFormatted = DateFormat(
      'dd MMM yyyy • HH:mm',
    ).format(widget.createdAt);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        children: [
          _buildCarouselSlider(),
          _buildProductInfo(createdAtFormatted),
          _buildSellerInfoStream(),
          _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Keranjang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (widget.stock == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang sudah sold out!')),
                  );
                  return;
                }
                final itemsToCheckout = [
                  {
                    'itemName': widget.itemName,
                    'price': widget.price,
                    'stock': widget.stock,
                    'image': widget.imagesBase64.first,
                    'quantity': 1,
                  },
                ];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(items: itemsToCheckout),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Beli Sekarang"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.9,
        ),
        items:
            widget.imagesBase64.map((imageBase64) {
              try {
                final bytes = base64Decode(imageBase64);
                return GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullscreenImageScreen(
                                imageBase64: imageBase64,
                              ),
                        ),
                      ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              } catch (_) {
                return Container(
                  width: double.infinity,
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey[700],
                  ),
                );
              }
            }).toList(),
      ),
    );
  }

  Widget _buildProductInfo(String createdAtFormatted) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.itemName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: toggleFavorite,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)},-',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Chip(
                label: Text('Stok: ${widget.stock}'),
                avatar: Icon(Icons.inventory_2_outlined),
              ),
              Chip(
                label: Text('${widget.weight} kg'),
                avatar: Icon(Icons.scale_outlined),
              ),
              Chip(
                label: Text(widget.category),
                avatar: Icon(Icons.category_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingSection(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                createdAtFormatted,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ReviewScreen(
                  itemName: widget.itemName,
                  productId: widget.productId,
                ),
          ),
        );
      },
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('rating')
                .where('productId', isEqualTo: widget.productId)
                .snapshots(),
        builder: (context, snapshot) {
          int reviewCount = snapshot.data?.docs.length ?? 0;
          return Row(
            children: [
              const Icon(Icons.star, color: Colors.yellow),
              const SizedBox(width: 6),
              Text(
                widget.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($reviewCount ulasan)',
                style: const TextStyle(color: Colors.grey),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSellerInfoStream() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('fullName', isEqualTo: widget.fullName)
              .limit(1)
              .snapshots(),
      builder: (context, snapshot) {
        Uint8List? userPhotoBytes;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final base64String = data['photo'];
          if (base64String is String && base64String.isNotEmpty) {
            userPhotoBytes = base64Decode(base64String);
          }
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    userPhotoBytes != null ? MemoryImage(userPhotoBytes) : null,
                child:
                    userPhotoBytes == null
                        ? const Icon(
                          Icons.person_2,
                          size: 40,
                          color: Colors.grey,
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(widget.location),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Deskripsi Produk",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.description, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
