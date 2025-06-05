import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techtrade/screens/Chat/chat_screen.dart';
import 'package:techtrade/screens/Checkout/checkout_screen.dart';
import 'package:techtrade/screens/cart/cart_screen.dart';
import 'package:techtrade/screens/detail/full_image_screen.dart';
import 'package:techtrade/screens/detail/review_screen.dart';
import 'package:techtrade/screens/other/seller_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String userId;

  const DetailScreen({
    super.key,
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
    required this.userId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  int currentImageIndex = 0;
  int quantity = 1;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
    }
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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

  bool get isOwnProduct => currentUserId == widget.userId;

  Future<void> addToCart() async {
    if (isOwnProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Anda tidak dapat menambahkan produk sendiri ke keranjang',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

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
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Theme.of(context).colorScheme.onPrimary,
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
    if (isOwnProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda tidak dapat membeli produk sendiri'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[300],
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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Stok: ${widget.stock}',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
                      Text(
                        'Jumlah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
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
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
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
      backgroundColor: Theme.of(context).colorScheme.background,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      floating: true,
      pinned: false,
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color:
                isFavorite
                    ? Colors.red
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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
      color: Theme.of(context).colorScheme.surface,
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        size: 80,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
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
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.grey[600]
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
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.price)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      widget.stock > 0
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        widget.stock > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.stock > 0 ? 'Stok: ${widget.stock}' : 'Habis',
                  style: TextStyle(
                    color:
                        widget.stock > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red,
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
                  color: Colors.blue.withValues(alpha: 0.1),
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
                  color: Colors.purple.withValues(alpha: 0.1),
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
      color: Theme.of(context).colorScheme.surface,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount ulasan)',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVariantSection() {
    if (isOwnProduct) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ini adalah produk yang Anda jual',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atur Jumlah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]!
                            : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                      icon: Icon(
                        Icons.remove,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          quantity < widget.stock
                              ? () => setState(() => quantity++)
                              : null,
                      icon: Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
              Text(
                'Informasi Penjual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SellerProfileScreen(
                            sellerId: widget.userId,
                            sellerName: widget.fullName,
                            sellerLocation: widget.location,
                          ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]!
                              : Colors.grey[200]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            userPhotoBytes != null
                                ? MemoryImage(userPhotoBytes)
                                : null,
                        child:
                            userPhotoBytes == null
                                ? Icon(
                                  Icons.person_2,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.location,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Toko',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Produk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ': $value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi Produk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.black26
                    : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isOwnProduct) ...[
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            sellerId: widget.userId,
                            sellerName: widget.fullName,
                            productId: widget.productId,
                            productName: widget.itemName,
                            productImage: widget.imagesBase64.first,
                          ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: const Icon(Icons.chat_bubble_outline, size: 20),
              ),
              const SizedBox(width: 8),
            ],

            OutlinedButton.icon(
              onPressed:
                  (widget.stock > 0 && !isOwnProduct)
                      ? _showQuantityBottomSheet
                      : null,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Keranjang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
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
                    (widget.stock > 0 && !isOwnProduct)
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
                  backgroundColor:
                      widget.stock > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isOwnProduct
                      ? 'Produk Anda'
                      : widget.stock > 0
                      ? 'Beli Sekarang'
                      : 'Stok Habis',
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
