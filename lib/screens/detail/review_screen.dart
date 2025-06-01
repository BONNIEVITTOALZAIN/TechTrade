import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'rating_screen.dart';

class ReviewScreen extends StatelessWidget {
  final String itemName;
  final String productId;

  const ReviewScreen({
    super.key,
    required this.itemName,
    required this.productId,
  });

  Future<Map<String, dynamic>> _fetchUser(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  Uint8List? _decodePhoto(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding photo: $e');
      return null;
    }
  }

  Widget _buildRatingTile(
    Map<String, dynamic> user,
    String comment,
    int ratingValue,
  ) {
    final photoBytes = _decodePhoto(user['photo']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: (0.1)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.teal.withValues(alpha: (0.1)),
              backgroundImage:
                  photoBytes != null ? MemoryImage(photoBytes) : null,
              child:
                  photoBytes == null
                      ? Icon(Icons.person_2, size: 28, color: Colors.teal)
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullName'] ?? 'Pengguna',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < ratingValue
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color:
                          index < ratingValue ? Colors.amber : Colors.grey[300],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ulasan Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('rating')
                .where('productId', isEqualTo: productId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ratingDocs = snapshot.data!.docs;

          if (ratingDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.reviews_outlined,
                    size: 80,
                    color: Colors.teal.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada ulasan untuk produk ini.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: ratingDocs.length,
            itemBuilder: (context, index) {
              final rating = ratingDocs[index].data() as Map<String, dynamic>;
              final userId = rating['userId'] ?? '';

              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchUser(userId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();

                  final user = userSnapshot.data!;
                  return _buildRatingTile(
                    user,
                    rating['komentar'] ?? '',
                    rating['ratingValue'] ?? 0,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      RatingScreen(itemName: itemName, productId: productId),
            ),
          );
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Tulis Ulasan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
