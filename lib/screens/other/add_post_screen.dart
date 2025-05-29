import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techtrade/screens/home_screen.dart';
import 'package:http/http.dart' as http;

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final ImagePicker _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();

  final List<File?> _images = [null, null, null];
  final List<String?> _base64Images = [null, null, null];
  bool _isUploading = false;

  String _selectedCategory = 'Other';
  String _selectedCondition = 'Baru';
  final List<String> _categories = [
    'Smartphone',
    'Mouse',
    'Keyboard',
    'PC',
    'VGA',
    'CPU',
    'Storage',
    'RAM',
    'Console',
    'Controller',
    'Headphone',
    'Laptop',
    'Other',
  ];

  final List<String> _conditions = ['Baru', 'Bekas', 'Bekas Seperti Baru'];

  Future<void> _pickImage(int index) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.camera_alt,
                        label: 'Kamera',
                        onTap: () async {
                          Navigator.pop(context);
                          final picked = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          await _processPickedImage(picked, index);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.photo_library,
                        label: 'Galeri',
                        onTap: () async {
                          Navigator.pop(context);
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          await _processPickedImage(picked, index);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.teal),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _processPickedImage(XFile? picked, int index) async {
    if (picked != null) {
      try {
        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: 70,
        );
        if (compressed != null) {
          setState(() {
            _images[index] = File(picked.path);
            _base64Images[index] = base64Encode(compressed);
          });
        } else {
          setState(() {
            _images[index] = File(picked.path);
            _base64Images[index] = null;
          });
          _showSnackBar('Gagal mengompres gambar', isError: true);
        }
      } catch (e) {
        debugPrint('Compress error: $e');
        _showSnackBar('Error memproses gambar', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> sendNotificationToTopic(
    String body,
    String senderName,
    String detail,
  ) async {
    final url = Uri.parse('https://server-fasum.vercel.app/send-to-topic');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "topic": "news",
        "title": "Notifikasi Baru",
        "body": body,
        "detail": detail,
        "senderName": senderName,
        "senderPhotoUrl":
            "https://tse2.mm.bing.net/th?id=OIP.psKLmU_dN2MJc8-IX3LcIgAAAA&pid=Api&P=0&h=180",
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Notifikasi berhasil dikirim')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal kirim notifikasi: ${response.body}')),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_validateForm()) return;

    setState(() => _isUploading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now().toIso8601String();

    if (uid == null) {
      setState(() => _isUploading = false);
      _showSnackBar('User tidak ditemukan', isError: true);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fullName = userDoc.data()?['fullName'] ?? 'Anonymous';

      final docRef = FirebaseFirestore.instance.collection('posts').doc();
      final productId = docRef.id;

      await docRef.set({
        'productId': productId,
        'images': _base64Images.where((img) => img != null).toList(),
        'itemName': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'createdAt': now,
        'location': _locationController.text.trim(),
        'fullName': fullName,
        'userId': uid,
      });

      sendNotificationToTopic(
        _nameController.text,
        fullName,
        _descriptionController.text,
      );

      if (mounted) {
        _showSnackBar('Produk berhasil ditambahkan!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      _showSnackBar('Gagal mengunggah produk', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  bool _validateForm() {
    if (_base64Images.where((img) => img != null).isEmpty) {
      _showSnackBar('Minimal upload 1 foto produk', isError: true);
      return false;
    }

    if (_nameController.text.trim().isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showSnackBar(
        'Mohon lengkapi semua field yang diperlukan',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.teal[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Foto Produk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Min. 1 foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Upload foto produk dengan pencahayaan yang baik untuk menarik pembeli',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildImageSlot(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    final hasImage = _images[index] != null;
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasImage ? Colors.teal : Colors.grey[300]!,
            width: hasImage ? 2 : 1,
          ),
          color: hasImage ? null : Colors.grey[50],
        ),
        child:
            hasImage
                ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        _images[index]!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images[index] = null;
                            _base64Images[index] = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey[400], size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${index + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.teal[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Informasi Produk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Nama Produk*',
              controller: _nameController,
              hint: 'Contoh: iPhone 13 Pro Max 256GB',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Kategori*',
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                    icon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Kondisi*',
                    value: _selectedCondition,
                    items: _conditions,
                    onChanged: (value) {
                      setState(() => _selectedCondition = value!);
                    },
                    icon: Icons.info_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Harga*',
                    controller: _priceController,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefix: 'Rp ',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Stok*',
                    controller: _stockController,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    suffix: ' pcs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Berat*',
                    controller: _weightController,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    suffix: ' kg',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Lokasi*',
                    controller: _locationController,
                    hint: 'Kota, Provinsi',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Deskripsi Produk*',
              controller: _descriptionController,
              hint:
                  'Jelaskan detail produk, spesifikasi, dan kondisi barang...',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          items:
              items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.teal),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 20,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Jual Produk",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        elevation: 1,
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildFormSection(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child:
                  _isUploading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Jual Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
