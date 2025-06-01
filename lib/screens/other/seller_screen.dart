import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:techtrade/screens/detail/detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerLocation;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? sellerData;
  bool _isLocaleInitialized = false;

  List<QueryDocumentSnapshot>? _cachedProducts;
  List<QueryDocumentSnapshot>? _cachedRatings;
  DateTime? _lastProductsUpdate;
  DateTime? _lastRatingsUpdate;

  bool _isLoadingProducts = false;
  bool _isLoadingRatings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocale();
    _loadSellerData();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _isLocaleInitialized = true;
      });
    } catch (e) {
      print('Error initializing locale: $e');
      setState(() {
        _isLocaleInitialized = false;
      });
    }
  }

  Future<void> _loadSellerData() async {
    try {
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.sellerId)
              .get();

      if (userSnapshot.exists) {
        setState(() {
          sellerData = userSnapshot.data();
        });
      }
    } catch (e) {
      print('Error loading seller data: $e');
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadProducts(), _loadRatings()]);
  }

  Future<void> _loadProducts() async {
    if (_isLoadingProducts) return;

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: widget.sellerId)
              .get();

      setState(() {
        _cachedProducts = snapshot.docs;
        _lastProductsUpdate = DateTime.now();
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadRatings() async {
    if (_isLoadingRatings) return;

    setState(() {
      _isLoadingRatings = true;
    });

    try {
      QuerySnapshot? snapshot;
      List<String> possibleFields = ['userId', 'sellerId'];

      for (String field in possibleFields) {
        try {
          final tempSnapshot =
              await FirebaseFirestore.instance
                  .collection('rating')
                  .where(field, isEqualTo: widget.sellerId)
                  .get();

          if (tempSnapshot.docs.isNotEmpty) {
            snapshot = tempSnapshot;
            print('Found ratings using field: $field');
            break;
          }
        } catch (e) {
          print('Field $field not found or error: $e');
          continue;
        }
      }

      if (snapshot == null || snapshot.docs.isEmpty) {
        print('Trying to get ratings from products...');

        final productsSnapshot =
            await FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: widget.sellerId)
                .get();

        List<String> productIds =
            productsSnapshot.docs.map((doc) => doc.id).toList();

        if (productIds.isNotEmpty) {
          final ratingsSnapshot =
              await FirebaseFirestore.instance
                  .collection('rating')
                  .where('productId', whereIn: productIds.take(10).toList())
                  .get();

          snapshot = ratingsSnapshot;
          print('Found ${snapshot.docs.length} ratings from products');
        }
      }

      setState(() {
        _cachedRatings = snapshot?.docs ?? [];
        _lastRatingsUpdate = DateTime.now();
        _isLoadingRatings = false;
      });

      print('Total ratings loaded: ${_cachedRatings?.length ?? 0}');
    } catch (e) {
      print('Error loading ratings: $e');
      setState(() {
        _isLoadingRatings = false;
        _cachedRatings = [];
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadProducts(), _loadRatings(), _loadSellerData()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: SizedBox(
                    height: 40,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontSize: 14),
                      tabs: const [Tab(text: 'Produk'), Tab(text: 'Info Toko')],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [_buildProductsTab(), _buildStoreInfoTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal, Color(0xFF00695C)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              _buildSellerAvatar(),
              const SizedBox(height: 6),
              Text(
                widget.sellerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.sellerLocation,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildSellerStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellerAvatar() {
    Uint8List? userPhotoBytes;
    if (sellerData != null && sellerData!['photo'] != null) {
      final base64String = sellerData!['photo'];
      if (base64String is String && base64String.isNotEmpty) {
        try {
          userPhotoBytes = base64Decode(base64String);
        } catch (e) {
          print('Error decoding image: $e');
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundImage:
            userPhotoBytes != null ? MemoryImage(userPhotoBytes) : null,
        backgroundColor: Colors.white24,
        child:
            userPhotoBytes == null
                ? const Icon(Icons.person_2, size: 30, color: Colors.white)
                : null,
      ),
    );
  }

  Widget _buildSellerStats() {
    final totalProducts = _cachedProducts?.length ?? 0;

    double averageRating = 0.0;
    int totalRatings = 0;

    if (_cachedRatings != null && _cachedRatings!.isNotEmpty) {
      totalRatings = _cachedRatings!.length;
      double totalScore = 0.0;

      for (var doc in _cachedRatings!) {
        final data = doc.data() as Map<String, dynamic>;
        totalScore += (data['ratingValue'] ?? 0).toDouble();
      }

      averageRating = totalRatings > 0 ? totalScore / totalRatings : 0.0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Produk', totalProducts.toString()),
              Container(
                height: 20,
                width: 1,
                color: Colors.white54,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildStatItem(
                'Rating',
                totalRatings > 0 ? averageRating.toStringAsFixed(1) : '0.0',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedProducts == null || _cachedProducts!.isEmpty) {
      return _buildEmptyState();
    }

    final sortedProducts = List<QueryDocumentSnapshot>.from(_cachedProducts!);
    sortedProducts.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      DateTime? aCreatedAt = _parseCreatedAt(aData['createdAt']);
      DateTime? bCreatedAt = _parseCreatedAt(bData['createdAt']);

      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (aCreatedAt == null) return 1;
      if (bCreatedAt == null) return -1;

      return bCreatedAt.compareTo(aCreatedAt);
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final doc = sortedProducts[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildProductCard(data, doc.id);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String postId) {
    final List<String> images = List<String>.from(data['images'] ?? []);
    final String itemName = data['itemName'] ?? data['title'] ?? '';
    final double price = (data['price'] ?? 0).toDouble();
    final String location = data['location'] ?? widget.sellerLocation ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => DetailScreen(
                  imagesBase64: images,
                  description: data['description'] ?? '',
                  createdAt:
                      _parseCreatedAt(data['createdAt']) ?? DateTime.now(),
                  fullName: data['fullName'] ?? widget.sellerName,
                  category: data['category'] ?? '',
                  itemName: itemName,
                  price: price,
                  stock: data['stock'] ?? 0,
                  weight: (data['weight'] ?? 0).toDouble(),
                  heroTag: postId,
                  location: location,
                  productId: postId,
                  averageRating: (data['averageRating'] ?? 0).toDouble(),
                  condition: data['condition'] ?? '',
                  userId: data['userId'],
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      images.isNotEmpty
                          ? Image.memory(
                            base64Decode(images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                ),
              ),
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${NumberFormat('#,##0', 'id_ID').format(price)}',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Informasi Toko', [
            _buildInfoRow('Nama', widget.sellerName),
            _buildInfoRow('Lokasi', widget.sellerLocation),
            _buildInfoRow('Bergabung', _getJoinDate()),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Kategori Produk', [_buildCategoriesSection()]),
          const SizedBox(height: 16),
          _buildInfoCard('Rating & Ulasan', [_buildRatingSection()]),
          const SizedBox(height: 16),
          _buildInfoCard('Jam Operasional', [
            _buildInfoRow('Senin - Jumat', '08:00 - 17:00'),
            _buildInfoRow('Sabtu', '08:00 - 15:00'),
            _buildInfoRow('Minggu', 'Tutup'),
          ]),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    if (_isLoadingRatings) {
      return const Text('Loading...');
    }

    if (_cachedRatings == null || _cachedRatings!.isEmpty) {
      return const Text(
        'Belum ada rating',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    double totalScore = 0.0;
    Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var doc in _cachedRatings!) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['ratingValue'] ?? 0).toInt();
      totalScore += rating;
      ratingCount[rating] = (ratingCount[rating] ?? 0) + 1;
    }

    double averageRating = totalScore / _cachedRatings!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : (index < averageRating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                Text(
                  '${_cachedRatings!.length} ulasan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ratingCount.entries.toList().reversed.map((entry) {
          final stars = entry.key;
          final count = entry.value;
          final percentage =
              _cachedRatings!.isNotEmpty ? count / _cachedRatings!.length : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('$stars', style: const TextStyle(fontSize: 12)),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_cachedProducts == null) {
      return const Text('Loading...');
    }

    final Set<String> categories = {};
    for (var doc in _cachedProducts!) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['category'] != null) {
        categories.add(data['category']);
      }
    }

    if (categories.isEmpty) {
      return const Text(
        'Belum ada kategori produk',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          categories.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Penjual belum menambahkan produk apapun',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  DateTime? _parseCreatedAt(dynamic createdAt) {
    if (createdAt == null) return null;

    try {
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      } else if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt);
      }
    } catch (e) {
      print(
        'Error parsing createdAt: $e, value: $createdAt, type: ${createdAt.runtimeType}',
      );
    }

    return null;
  }

  String _getJoinDate() {
    if (sellerData != null && sellerData!['createdAt'] != null) {
      final createdAt = _parseCreatedAt(sellerData!['createdAt']);
      if (createdAt != null) {
        if (_isLocaleInitialized) {
          try {
            return DateFormat('MMMM yyyy', 'id_ID').format(createdAt);
          } catch (e) {
            print('Error formatting date with Indonesian locale: $e');
            return DateFormat('MMMM yyyy').format(createdAt);
          }
        } else {
          return DateFormat('MMMM yyyy').format(createdAt);
        }
      }
    }
    return 'Tidak diketahui';
  }
}
