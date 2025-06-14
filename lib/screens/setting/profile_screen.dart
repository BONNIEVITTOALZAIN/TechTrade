import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

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
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    fetchUserData();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {
      print('Failed to initialize Indonesian locale: $e');
    }
  }

  Future<void> _pickImage() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Ambil Foto',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Gunakan kamera untuk foto baru',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      await _processPickedImage(picked);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Pilih dari Galeri',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Pilih foto dari galeri perangkat',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      await _processPickedImage(picked);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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

          String dateString = data['tanggalLahir'] ?? '';
          if (dateString.isNotEmpty) {
            _tanggalLahirController.text = dateString;
            try {
              selectedDate = DateTime.tryParse(dateString);

              if (selectedDate == null) {
                final formats = [
                  DateFormat('dd MMMM yyyy', 'id_ID'),
                  DateFormat('dd/MM/yyyy'),
                  DateFormat('yyyy-MM-dd'),
                  DateFormat('dd-MM-yyyy'),
                ];

                for (var format in formats) {
                  try {
                    selectedDate = format.parse(dateString);
                    break;
                  } catch (e) {
                    continue;
                  }
                }
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }

          base64Image = data['photo'] ?? '';
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
        String tanggalLahirISO = '';
        if (selectedDate != null) {
          tanggalLahirISO = selectedDate!.toIso8601String().split('T')[0];
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text,
          'userName': _userNameController.text,
          'bio': _bioController.text,
          'email': _emailController.text,
          'nomorHp': _nomorHpController.text,
          'jenisKelamin': _jenisKelaminController.text,
          'tanggalLahir': _tanggalLahirController.text,
          'tanggalLahirISO': tanggalLahirISO,
          'photo': base64Image ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil berhasil diperbarui'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Gagal update profil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Gagal update profil: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit $title',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: tempController,
            keyboardType: inputType,
            maxLines: title == 'Bio' ? 3 : 1,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: title,
              labelStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
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
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Pilih Jenis Kelamin',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  options
                      .map(
                        (option) => ListTile(
                          leading: Radio<String>(
                            value: option,
                            groupValue: _jenisKelaminController.text,
                            onChanged: (value) => Navigator.pop(context, value),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, option),
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _jenisKelaminController.text = result);
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      try {
        return DateFormat('dd MMM yyyy').format(date);
      } catch (e2) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
  }

  void _selectTanggalLahir() async {
    DateTime initialDate;
    if (selectedDate != null) {
      initialDate = selectedDate!;
    } else if (_tanggalLahirController.text.isNotEmpty) {
      initialDate =
          DateTime.tryParse(_tanggalLahirController.text) ?? DateTime(2000);
    } else {
      initialDate = DateTime(2000);
    }

    final now = DateTime.now();
    final firstDate = DateTime(1900);

    if (initialDate.isAfter(now)) {
      initialDate = now;
    } else if (initialDate.isBefore(firstDate)) {
      initialDate = DateTime(2000);
    }

    try {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: now,
        helpText: 'Pilih Tanggal Lahir',
        cancelText: 'Batal',
        confirmText: 'OK',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Theme.of(context).cardColor,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          selectedDate = picked;
          _tanggalLahirController.text = _formatDate(picked);
        });
      }
    } catch (e) {
      print('Error selecting date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal memilih tanggal'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildItemRow(
    String label,
    TextEditingController controller, {
    VoidCallback? onTapOverride,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading:
            icon != null
                ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                )
                : null,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            controller.text.isNotEmpty ? controller.text : 'Tambah $label',
            style: TextStyle(
              fontSize: 16,
              color:
                  controller.text.isEmpty
                      ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurface,
              fontStyle:
                  controller.text.isEmpty ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
        onTap:
            onTapOverride ??
            () => _editField(label, controller, inputType: inputType),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    title == 'Info Profil' ? Icons.person_2 : Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ubah Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDarkMode
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[200],
                                  backgroundImage:
                                      (base64Image != null &&
                                              base64Image!.isNotEmpty)
                                          ? MemoryImage(
                                            base64Decode(base64Image!),
                                          )
                                          : null,
                                  child:
                                      (base64Image == null ||
                                              base64Image!.isEmpty)
                                          ? Icon(
                                            Icons.person_2,
                                            size: 50,
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[500]
                                                    : Colors.grey[400],
                                          )
                                          : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Foto Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ketuk untuk mengubah foto',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard('Info Profil', [
                      _buildItemRow(
                        'Nama Lengkap',
                        _fullNameController,
                        icon: Icons.person_outline,
                      ),
                      _buildItemRow(
                        'Username',
                        _userNameController,
                        icon: Icons.alternate_email,
                      ),
                      _buildItemRow(
                        'Bio',
                        _bioController,
                        icon: Icons.description_outlined,
                      ),
                    ]),
                    _buildSectionCard('Info Pribadi', [
                      _buildItemRow(
                        'E-mail',
                        _emailController,
                        inputType: TextInputType.emailAddress,
                        icon: Icons.email_outlined,
                      ),
                      _buildItemRow(
                        'Nomor HP',
                        _nomorHpController,
                        inputType: TextInputType.phone,
                        icon: Icons.phone_outlined,
                      ),
                      _buildItemRow(
                        'Jenis Kelamin',
                        _jenisKelaminController,
                        onTapOverride: _selectJenisKelamin,
                        icon: Icons.wc_outlined,
                      ),
                      _buildItemRow(
                        'Tanggal Lahir',
                        _tanggalLahirController,
                        onTapOverride: _selectTanggalLahir,
                        icon: Icons.cake_outlined,
                      ),
                    ]),
                    Container(
                      width: double.infinity,
                      height: 50,
                      margin: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : updateUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
