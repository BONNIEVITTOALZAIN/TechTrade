import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techtrade/screens/home_screen.dart';

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
  final List<String> _categories = [
    'Smartphone',
    'Mouse',
    'Keyboard',
    'Pc',
    'Vga',
    'Cpu',
    'Storage',
    'Ram',
    'Console',
    'Controller',
    'Headphone',
    'Laptop',
    'Other',
  ];

  Future<void> _pickImage(int index) async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil Foto'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    await _processPickedImage(picked, index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    await _processPickedImage(picked, index);
                  },
                ),
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
          quality: 50,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to compress image')),
          );
        }
      } catch (e) {
        debugPrint('Compress error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error processing image')));
      }
    }
  }

  Future<void> _submitPost() async {
    if (_base64Images.any((img) => img == null) ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and upload all 3 images."),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now().toIso8601String();

    if (uid == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not found.')));
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
        'images': _base64Images,
        'itemName': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'createdAt': now,
        'location': _locationController.text,
        'fullName': fullName,
        'userId': uid,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload post.')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  int _currentImageIndex = 0;

  Widget _buildImageCarousel() {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[300],
          ),
          child:
              _images[_currentImageIndex] != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _images[_currentImageIndex]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                  : Center(
                    child: Text(
                      'Image',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _currentImageIndex == index
                            ? Colors.teal
                            : Colors.transparent,
                    width: 2,
                  ),
                  color: Colors.grey[200],
                  image:
                      _images[index] != null
                          ? DecorationImage(
                            image: FileImage(_images[index]!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _images[index] == null
                        ? Icon(Icons.add_a_photo, color: Colors.grey[600])
                        : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(_currentImageIndex),
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text(
            'Tambah foto produk',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Kategori Produk',
          prefixIcon: const Icon(Icons.category_outlined, color: Colors.teal),
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        dropdownColor: Colors.white,
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
        items:
            _categories.map((cat) {
              IconData iconData;

              switch (cat) {
                case 'Smartphone':
                  iconData = Icons.smartphone;
                  break;
                case 'Mouse':
                  iconData = Icons.mouse;
                  break;
                case 'Keyboard':
                  iconData = Icons.keyboard;
                  break;
                case 'Pc':
                  iconData = Icons.computer;
                  break;
                case 'Vga':
                  iconData = Icons.memory;
                  break;
                case 'Cpu':
                  iconData = Icons.memory;
                  break;
                case 'Storage':
                  iconData = Icons.sd_storage;
                  break;
                case 'Ram':
                  iconData = Icons.memory;
                  break;
                case 'Console':
                  iconData = Icons.videogame_asset;
                  break;
                case 'Controller':
                  iconData = Icons.gamepad;
                  break;
                case 'Headphone':
                  iconData = Icons.headphones;
                  break;
                case 'Laptop':
                  iconData = Icons.laptop;
                  break;
                case 'Other':
                default:
                  iconData = Icons.device_unknown;
                  break;
              }

              return DropdownMenuItem<String>(
                value: cat,
                child: Row(
                  children: [
                    Icon(iconData, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(cat),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Jual Produk", style: TextStyle(color: Colors.black)),
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _isUploading
              ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
              : TextButton(
                onPressed: _submitPost,
                child: const Text(
                  'Jual',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(),
                const SizedBox(height: 20),
                _buildInput('Nama Produk', _nameController),
                const SizedBox(height: 14),
                _buildCategoryDropdown(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        'Harga',
                        _priceController,
                        type: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildInput(
                        'Berat (Kg)',
                        _weightController,
                        type: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInput(
                  'Stok',
                  _stockController,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildInput('Lokasi Produk', _locationController),
                const SizedBox(height: 14),
                _buildInput(
                  'Deskripsi Produk',
                  _descriptionController,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
