import 'package:flutter/material.dart';
import 'package:techtrade/screens/Checkout/transaksi_list_screen.dart';
import 'package:techtrade/screens/other/add_post_screen.dart';
import 'package:techtrade/screens/other/home_content_screen.dart';
import 'package:techtrade/screens/setting/account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeContent(),
    const AddPostScreen(),
    const AccountPage(),
    const TransactionListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex.clamp(0, screens.length - 1)],
      bottomNavigationBar: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(icon: Icons.home, index: 0, label: "Beranda"),
            navItem(
              icon: Icons.add_a_photo_outlined,
              index: 1,
              label: "Upload",
            ),
            navItem(
              icon: Icons.shopping_bag_outlined,
              index: 3,
              label: "Transaksi",
            ),
            navItem(icon: Icons.person_2, index: 2, label: "Akun"),
          ],
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.teal : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
