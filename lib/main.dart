import 'package:techtrade/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:techtrade/screens/other/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechTrade',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

// notes :
// 1. belum bikin navbar ( done )
// 2. desain ulang wishlist ( done )
// 3. buat keranjang belanja ( done )
// 4. buat profile screen yang bisa lupa password,ganti foto (done)
// 5. tambahkan di detail screen tombol add to cart dan buy now (done)
// 6. tambahkan di cart screen (done)
// 7.
