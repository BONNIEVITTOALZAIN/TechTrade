import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class RatingScreen extends StatefulWidget {
  final String itemName;
  final String productId;

  const RatingScreen({
    super.key,
    required this.itemName,
    required this.productId,
  });

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _komentarController = TextEditingController();
  bool _isSubmitting = false;

  void _setRating(int value) {
    setState(() {
      _rating = value;
    });
  }

  void _showCustomSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showCustomSnackBar(
        'Silakan pilih rating bintang',
        Icons.star_border,
        Colors.orange,
      );
      return;
    }

    if (_komentarController.text.trim().isEmpty) {
      _showCustomSnackBar(
        'Komentar tidak boleh kosong',
        Icons.comment,
        Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showCustomSnackBar(
        'Anda harus login untuk memberikan review.',
        Icons.login,
        Colors.red,
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final uid = user.uid;
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final username = userDoc.data()?['fullName'] ?? 'Anonim';

      final reviewData = {
        'userId': uid,
        'fullName': username,
        'productId': widget.productId,
        'itemName': widget.itemName,
        'ratingValue': _rating,
        'komentar': _komentarController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('rating').add(reviewData);

      final ratingSnapshot =
          await FirebaseFirestore.instance
              .collection('rating')
              .where('productId', isEqualTo: widget.productId)
              .get();

      double totalRating = 0;
      for (var doc in ratingSnapshot.docs) {
        totalRating += (doc.data()['ratingValue'] as num).toDouble();
      }

      final ratingCount = ratingSnapshot.docs.length;
      final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.productId)
          .update({'averageRating': averageRating, 'ratingCount': ratingCount});

      HapticFeedback.mediumImpact();
      _showCustomSnackBar(
        'Review berhasil ditambahkan!',
        Icons.check_circle,
        Colors.green,
      );
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, true);
    } catch (e) {
      _showCustomSnackBar(
        'Gagal menambahkan review. Coba lagi.',
        Icons.error_outline,
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Beri Rating Produk', style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Pilih rating Anda:',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => _setRating(index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              _rating > 0
                  ? 'Anda memberi rating: $_rating bintang'
                  : 'Belum ada rating yang dipilih',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Tulis ulasan (wajib):',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _komentarController,
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Bagikan pendapat Anda tentang produk ini...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 30),
            _isSubmitting
                ? Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                )
                : ElevatedButton(
                  onPressed: _submitReview,
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15),
                    ),
                    textStyle: WidgetStateProperty.all(
                      theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  child: const Text('Kirim Rating'),
                ),
          ],
        ),
      ),
    );
  }
}
