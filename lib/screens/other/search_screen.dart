import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../detail/detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String searchKeyword;

  const SearchResultScreen({super.key, required this.searchKeyword});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchController;
  late String _currentKeyword;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _currentKeyword = widget.searchKeyword;
    _searchController = TextEditingController(text: _currentKeyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget filterButton(String label, String value) {
    final isSelected = selectedFilter == value;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedFilter = value;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.white,
        side: const BorderSide(color: Colors.teal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.teal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keywordLower = _currentKeyword.toLowerCase();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _currentKeyword = '';
                          });
                        },
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            cursorColor: Colors.teal,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              setState(() {
                _currentKeyword = value.trim();
              });
            },
            onChanged: (value) {
              setState(() {
                _currentKeyword = value.trim();
              });
            },
          ),
        ),
      ),
      body:
          _currentKeyword.isEmpty
              ? const Center(
                child: Text(
                  "Masukkan kata pencarian...",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          filterButton('All', 'all'),
                          const SizedBox(width: 7),
                          filterButton('Termurah', 'termurah'),
                          const SizedBox(width: 7),
                          filterButton('Termahal', 'termahal'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('posts')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        List<QueryDocumentSnapshot> filteredDocs =
                            docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final itemName =
                                  (data['itemName'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              return itemName.contains(keywordLower);
                            }).toList();

                        if (selectedFilter == 'termurah') {
                          filteredDocs.sort((a, b) {
                            final priceA = (a['price'] ?? 0);
                            final priceB = (b['price'] ?? 0);
                            return (priceA as num).compareTo(priceB as num);
                          });
                        } else if (selectedFilter == 'termahal') {
                          filteredDocs.sort((a, b) {
                            final priceA = (a['price'] ?? 0);
                            final priceB = (b['price'] ?? 0);
                            return (priceB as num).compareTo(priceA as num);
                          });
                        }

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Tidak ada produk ditemukan.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredDocs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3 / 5,
                              ),
                          itemBuilder: (context, index) {
                            final data =
                                filteredDocs[index].data()
                                    as Map<String, dynamic>;
                            final images = List<String>.from(
                              data['images'] ?? [],
                            );
                            final imageBase64 =
                                images.isNotEmpty ? images[0] : '';
                            Uint8List image =
                                imageBase64.isNotEmpty
                                    ? base64Decode(imageBase64)
                                    : Uint8List(0);

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
                                          description:
                                              data['description'] ?? '',
                                          createdAt: createdAt,
                                          fullName:
                                              data['fullName'] ?? 'Anonim',
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                  ),
                ],
              ),
    );
  }
}
