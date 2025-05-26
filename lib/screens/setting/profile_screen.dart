import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  final TextEditingController _jenisKelaminController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? base64Image;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> _pickImage() async {
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
                    await _processPickedImage(picked);
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
                    await _processPickedImage(picked);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _processPickedImage(XFile? picked) async {
    if (picked != null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        picked.path,
        quality: 50,
      );
      if (compressed != null) {
        setState(() {
          base64Image = base64Encode(compressed);
        });
      }
    }
  }

  Future<void> fetchUserData() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final data = doc.data()!;
          _fullNameController.text = data['fullName'] ?? '';
          _userNameController.text = data['userName'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _emailController.text = data['email'] ?? '';
          _nomorHpController.text = data['nomorHp'] ?? '';
          _jenisKelaminController.text = data['jenisKelamin'] ?? '';
          _tanggalLahirController.text = data['tanggalLahir'] ?? '';
          base64Image = data['photo'] ?? null;
        }
      }
    } catch (e) {
      print('Gagal ambil data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUserProfile() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text,
          'userName': _userNameController.text,
          'bio': _bioController.text,
          'email': _emailController.text,
          'nomorHp': _nomorHpController.text,
          'jenisKelamin': _jenisKelaminController.text,
          'tanggalLahir': _tanggalLahirController.text,
          'photo': base64Image ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      print('Gagal update profil: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update profil: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editField(
    String title,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final tempController = TextEditingController(text: controller.text);
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: tempController,
            keyboardType: inputType,
            decoration: InputDecoration(labelText: title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempController.text),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => controller.text = result);
    }
  }

  void _selectJenisKelamin() async {
    final options = ['Laki-laki', 'Perempuan'];
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Pilih Jenis Kelamin'),
            children:
                options
                    .map(
                      (option) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, option),
                        child: Text(option),
                      ),
                    )
                    .toList(),
          ),
    );

    if (result != null) {
      setState(() => _jenisKelaminController.text = result);
    }
  }

  void _selectTanggalLahir() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_tanggalLahirController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildItemRow(
    String label,
    TextEditingController controller, {
    VoidCallback? onTapOverride,
    TextInputType inputType = TextInputType.text,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        controller.text.isNotEmpty ? controller.text : 'Tambah $label',
        style: TextStyle(
          color: controller.text.isEmpty ? Colors.blue : Colors.grey[800],
          fontStyle:
              controller.text.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap:
          onTapOverride ??
          () => _editField(label, controller, inputType: inputType),
    );
  }

  Widget _buildLabel(String text) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        const Icon(Icons.info_outline, size: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil'),
        leading: const BackButton(),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (base64Image != null && base64Image!.isNotEmpty)
                                ? MemoryImage(base64Decode(base64Image!))
                                : null,
                        child:
                            (base64Image == null || base64Image!.isEmpty)
                                ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.blue,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text(
                        'Ubah Foto Profil',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                    const Divider(height: 32),
                    _buildLabel('Info Profil'),
                    const SizedBox(height: 12),
                    _buildItemRow('Nama', _fullNameController),
                    _buildItemRow('Username', _userNameController),
                    _buildItemRow('Bio', _bioController),
                    const Divider(height: 32),
                    _buildLabel('Info Pribadi'),
                    const SizedBox(height: 12),
                    _buildItemRow(
                      'E-mail',
                      _emailController,
                      inputType: TextInputType.emailAddress,
                    ),
                    _buildItemRow(
                      'Nomor HP',
                      _nomorHpController,
                      inputType: TextInputType.phone,
                    ),
                    _buildItemRow(
                      'Jenis Kelamin',
                      _jenisKelaminController,
                      onTapOverride: _selectJenisKelamin,
                    ),
                    _buildItemRow(
                      'Tanggal Lahir',
                      _tanggalLahirController,
                      onTapOverride: _selectTanggalLahir,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: updateUserProfile,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
    );
  }
}
