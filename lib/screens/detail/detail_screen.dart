import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/Checkout/checkout_screen.dart';
import 'package:techtrade/screens/detail/full_image_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techtrade/screens/detail/rating_screen.dart';

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
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<String> comments = [];
  bool isFavorite = false;
  Uint8List? userPhotoBytes;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _fetchUserPhoto();
  }

  Future<void> _fetchUserPhoto() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('fullName', isEqualTo: widget.fullName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final base64String = data['photo'] ?? null;

        if (base64String != null) {
          final decodedBytes = base64Decode(base64String);
          setState(() {
            userPhotoBytes = decodedBytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch user photo: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getBool(widget.itemName);
    setState(() {
      isFavorite = status ?? false;
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isFavorite = !isFavorite);

    if (isFavorite) {
      await prefs.setBool(widget.itemName, true);
    } else {
      await prefs.remove(widget.itemName);
    }
  }

  void addComment(String comment) {
    setState(() {
      comments.add(comment);
    });
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
        title: const Text('Detail Produk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildCarouselSlider(),
          _buildProductInfo(createdAtFormatted),
          _buildSellerInfo(),
          _buildDescription(),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: addToCart,
              icon: const Icon(Icons.add_shopping_cart, size: 24),
              label: const Text("Keranjang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
              child: const Text("Beli Sekarang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
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
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FullscreenImageScreen(
                                  imageBase64: imageBase64,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
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
                  InkWell(
                    onTap: toggleFavorite,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)},-',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text('Stok: ${widget.stock}'),
                    backgroundColor: Colors.grey[100],
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    avatar: const Icon(Icons.scale_outlined, size: 18),
                    label: Text('${widget.weight} kg'),
                    backgroundColor: Colors.grey[100],
                  ),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  const Icon(Icons.sell_outlined, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Text(widget.category),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  InkWell(
                    // onTap: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder:
                    //           (context) =>
                    //               RatingScreen(itemName: widget.itemName, productId: widget.pro)

                    //     ),
                    //   );
                    // },
                    child: const Icon(Icons.star, color: Colors.yellow),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(createdAtFormatted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              userPhotoBytes != null
                  ? CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: null,
                    child: ClipOval(
                      child: Image.memory(
                        userPhotoBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  : CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person_2,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
              const SizedBox(width: 12),
              Text(
                widget.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_rounded, color: Colors.teal),
            title: Text(widget.location),
            subtitle: const Text("Lokasi produk"),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Produk',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komentar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _CommentInput(onSubmit: addComment),
          const SizedBox(height: 16),
          ...comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(comment),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  final void Function(String) onSubmit;

  const _CommentInput({required this.onSubmit});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Tulis komentar...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _submit,
          color: Colors.blue,
        ),
      ],
    );
  }
}
