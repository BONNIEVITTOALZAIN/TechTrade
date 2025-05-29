import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techtrade/screens/Checkout/checkout_screen.dart';
import 'package:techtrade/screens/cart/cart_screen.dart';
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
  final String condition;

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
    required this.condition,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  int currentImageIndex = 0;
  int quantity = 1;

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
          SnackBar(
            content: const Text('Produk ditambahkan ke favorit'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      if (favorites.contains(currentItem)) {
        favorites.remove(currentItem);
        await prefs.setStringList('favorites', favorites);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produk dihapus dari favorit'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
      'quantity': quantity,
    });

    bool itemExists = false;
    List<String> updatedCart = [];

    for (String item in cart) {
      Map<String, dynamic> decodedItem = jsonDecode(item);
      if (decodedItem['itemName'] == widget.itemName) {
        decodedItem['quantity'] = (decodedItem['quantity'] ?? 1) + quantity;
        updatedCart.add(jsonEncode(decodedItem));
        itemExists = true;
      } else {
        updatedCart.add(item);
      }
    }

    if (!itemExists) {
      updatedCart.add(currentItem);
    }

    await prefs.setStringList('cart', updatedCart);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          itemExists
              ? 'Jumlah produk di keranjang diperbarui'
              : 'Produk ditambahkan ke keranjang',
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showQuantityBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(widget.imagesBase64.first),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)}',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Stok: ${widget.stock}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jumlah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                                quantity > 1
                                    ? () {
                                      setModalState(() => quantity--);
                                      setState(() {});
                                    }
                                    : null,
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                quantity < widget.stock
                                    ? () {
                                      setModalState(() => quantity++);
                                      setState(() {});
                                    }
                                    : null,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.teal[100],
                              foregroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        addToCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tambah ke Keranjang (${quantity})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildImageCarousel(),
              _buildProductHeader(),
              _buildRatingAndReviews(),
              _buildVariantSection(),
              _buildSellerInfo(),
              _buildProductDetails(),
              _buildDescription(),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      floating: true,
      pinned: false,
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey[600],
          ),
          onPressed: toggleFavorite,
        ),
        IconButton(
          icon: Stack(children: [const Icon(Icons.shopping_cart_outlined)]),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              enableInfiniteScroll: widget.imagesBase64.length > 1,
              onPageChanged: (index, reason) {
                setState(() {
                  currentImageIndex = index;
                });
              },
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
                      child: Image.memory(
                        bytes,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    );
                  } catch (_) {
                    return Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    );
                  }
                }).toList(),
          ),
          if (widget.imagesBase64.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  widget.imagesBase64.asMap().entries.map((entry) {
                    return Container(
                      width: currentImageIndex == entry.key ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color:
                            currentImageIndex == entry.key
                                ? Colors.teal
                                : Colors.grey[300],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.stock > 0 ? Colors.teal[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.stock > 0 ? Colors.teal : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.stock > 0 ? 'Stok: ${widget.stock}' : 'Habis',
                  style: TextStyle(
                    color: widget.stock > 0 ? Colors.teal : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.weight} kg',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 14,
                      color: Colors.purple[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.category,
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndReviews() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
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
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.averageRating.floor()
                          ? Icons.star
                          : index == widget.averageRating.floor() &&
                              widget.averageRating % 1 != 0
                          ? Icons.star_half
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount ulasan)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVariantSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atur Jumlah',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                      icon: const Icon(Icons.remove, size: 16),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          quantity < widget.stock
                              ? () => setState(() => quantity++)
                              : null,
                      icon: const Icon(Icons.add, size: 16),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Maksimal ${widget.stock} pcs',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('fullName', isEqualTo: widget.fullName)
                .limit(1)
                .snapshots(),
        builder: (context, snapshot) {
          Uint8List? userPhotoBytes;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final data =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final base64String = data['photo'];
            if (base64String is String && base64String.isNotEmpty) {
              userPhotoBytes = base64Decode(base64String);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Penjual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        userPhotoBytes != null
                            ? MemoryImage(userPhotoBytes)
                            : null,
                    child:
                        userPhotoBytes == null
                            ? const Icon(Icons.person_2, size: 24)
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductDetails() {
    final createdAtFormatted = DateFormat(
      'dd MMM yyyy',
    ).format(widget.createdAt);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Produk',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Kategori', widget.category),
          _buildDetailRow('Berat', '${widget.weight} kg'),
          _buildDetailRow('Stok', widget.stock.toString()),
          _buildDetailRow('Kondisi', widget.condition),
          _buildDetailRow('Dipublikasikan', createdAtFormatted),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Text(
            ': $value',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Produk',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.stock > 0 ? _showQuantityBottomSheet : null,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Keranjang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    widget.stock > 0
                        ? () {
                          final itemsToCheckout = [
                            {
                              'itemName': widget.itemName,
                              'price': widget.price,
                              'stock': widget.stock,
                              'image': widget.imagesBase64.first,
                              'quantity': quantity,
                            },
                          ];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CheckoutScreen(items: itemsToCheckout),
                            ),
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.stock > 0 ? Colors.teal : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.stock > 0 ? 'Beli Sekarang' : 'Stok Habis',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
