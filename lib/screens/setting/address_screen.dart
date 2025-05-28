import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AddressPage extends StatefulWidget {
  const AddressPage({Key? key}) : super(key: key);

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  String strLatLong = 'Mencari lokasi...';
  String strAlamat = 'Mencari alamat...';
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _handleGetLocationAndSave();
  }

  Future<void> _handleGetLocationAndSave() async {
    try {
      Position position = await _getGeoLocationPosition();
      await getAddressFromLongLat(position);

      if (!mounted) return;

      setState(() {
        strLatLong = '${position.latitude}, ${position.longitude}';
      });

      await simpanLokasiKeFirestore(position, strAlamat);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw 'Layanan lokasi belum aktif';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak secara permanen';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> getAddressFromLongLat(Position position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&accept-language=id',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'FlutterApp/1.0 (bonnievittoalzain_2327250050@mhs.mdp.ac.id)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? alamat = data['display_name'];

        if (alamat == null || alamat.trim().isEmpty) {
          alamat = 'Alamat tidak ditemukan';
        }

        if (!mounted) return;
        setState(() {
          strAlamat = alamat!;
        });
      } else {
        throw 'Server gagal merespon: ${response.statusCode}';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        strAlamat = 'Gagal mendapatkan alamat: $e';
      });
    }
  }

  Future<void> simpanLokasiKeFirestore(Position position, String alamat) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum login')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .add({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'alamat': alamat,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lokasi berhasil disimpan')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan lokasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alamat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              loading
                  ? const CircularProgressIndicator()
                  : errorMessage != null
                  ? Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Titik Koordinat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strLatLong,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Alamat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strAlamat,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
