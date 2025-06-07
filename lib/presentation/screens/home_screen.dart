import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/account/account_screen.dart'; // Akan dibuat
import 'package:loker_kabur_aja_dulu/presentation/screens/auth/login_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/favorites/favorites_host_screen.dart'; // Akan dibuat (host untuk tab Lowongan & Kos Disimpan)
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/kos_screen.dart'; // Akan dibuat
import 'package:loker_kabur_aja_dulu/presentation/screens/lowongan/lowongan_screen.dart'; // Akan dibuat
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Indeks untuk tab yang aktif

  // Daftar halaman yang akan ditampilkan sesuai tab
  // Kita akan buat halaman-halaman ini nanti
  static final List<Widget> _widgetOptions = <Widget>[
    const LowonganScreen(), // Indeks 0
    const KosScreen(),      // Indeks 1
    const FavoritesHostScreen(), // Indeks 2 (Akan berisi TabController untuk Lowongan & Kos disimpan)
    const AccountScreen(),  // Indeks 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // listen:false jika hanya butuh data sekali
    // final user = authProvider.currentUser; // Bisa diambil jika perlu

    return Scaffold(
      appBar: AppBar(
        title: const Text('KaburAjaDulu'),
        // Tombol "Where I am" akan ditambahkan di sini nanti
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Lowongan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Kos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Disimpan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true, // Agar label selalu tampil
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Agar semua item tampil & tidak bergeser
      ),
    );
  }
}