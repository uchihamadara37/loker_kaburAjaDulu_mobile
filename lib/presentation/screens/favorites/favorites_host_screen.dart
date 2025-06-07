import 'package:flutter/material.dart';
// import 'package:loker_kabur_aja_dulu/data/models/kos_disimpan_model.dart';
// import 'package:loker_kabur_aja_dulu/data/models/lowongan_disimpan_model.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/kos_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/lowongan_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/kos_detail_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/lowongan/lowongan_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class FavoritesHostScreen extends StatefulWidget {
  const FavoritesHostScreen({super.key});

  @override
  State<FavoritesHostScreen> createState() => _FavoritesHostScreenState();
}

class _FavoritesHostScreenState extends State<FavoritesHostScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Panggil fetch data saat initState atau saat tab dipilih jika perlu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
    _tabController?.addListener(() {
      if (_tabController!.indexIsChanging) {
        // Bisa juga load data di sini jika mau load per tab
      }
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.userId != null) {
      Provider.of<LowonganProvider>(context, listen: false).fetchSavedLowongan(authProvider.userId!);
      Provider.of<KosProvider>(context, listen: false).fetchSavedKos(authProvider.userId!);
    } else {
      // Kosongkan list jika user tidak login
      Provider.of<LowonganProvider>(context, listen: false).fetchSavedLowongan('');
      Provider.of<KosProvider>(context, listen: false).fetchSavedKos('');
    }
  }


  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated || authProvider.userId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Silakan login untuk melihat item yang Anda simpan.', textAlign: TextAlign.center),
        ),
      );
    }

    return Scaffold(
      appBar: TabBar( // TabBar bisa diletakkan di AppBar Scaffold atau sebagai widget sendiri
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.work_history_outlined), text: 'Lowongan'),
          Tab(icon: Icon(Icons.holiday_village_outlined), text: 'Tempat Kos'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedLowonganList(authProvider.userId!),
          _buildSavedKosList(authProvider.userId!),
        ],
      ),
    );
  }

  Widget _buildSavedLowonganList(String userId) {
    return Consumer<LowonganProvider>(
      builder: (context, lowonganProvider, child) {
        if (lowonganProvider.isLoading && lowonganProvider.savedLowonganList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (lowonganProvider.errorMessage != null && lowonganProvider.savedLowonganList.isEmpty) {
           return Center(child: Text("Error: ${lowonganProvider.errorMessage}"));
        }
        if (lowonganProvider.savedLowonganList.isEmpty) {
          return const Center(child: Text('Belum ada lowongan yang Anda simpan.'));
        }
        return ListView.builder(
          itemCount: lowonganProvider.savedLowonganList.length,
          itemBuilder: (ctx, index) {
            final savedLowongan = lowonganProvider.savedLowonganList[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(savedLowongan.namaPerusahaan ?? 'Nama Perusahaan Tidak Ada'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(savedLowongan.deskripsiLowongan?.substring(0, (savedLowongan.deskripsiLowongan?.length ?? 0) > 50 ? 50 : (savedLowongan.deskripsiLowongan?.length ?? 0)) ?? 'Tidak ada deskripsi', overflow: TextOverflow.ellipsis,),
                    Text('Disimpan: ${DateFormat('dd MMM yyyy, HH:mm').format(savedLowongan.waktuSimpan)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Hapus dari favorit',
                  onPressed: () {
                    // Panggil metode unfavorite dari provider
                    lowonganProvider.unfavoriteLowonganById(savedLowongan.id, userId, () {
                        // Callback opsional setelah selesai, misal tampilkan snackbar
                        if(mounted && lowonganProvider.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lowongan dihapus dari favorit'), duration: Duration(seconds: 1),)
                            );
                        }
                    });
                  },
                ),
                onTap: () {
                  // Navigasi ke LowonganDetailScreen.
                  // LowonganDetailScreen akan mem-fetch detail dari API menggunakan ID.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LowonganDetailScreen(lowonganId: savedLowongan.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedKosList(String userId) {
    return Consumer<KosProvider>(
      builder: (context, kosProvider, child) {
        if (kosProvider.isLoading && kosProvider.savedKosList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
         if (kosProvider.errorMessage != null && kosProvider.savedKosList.isEmpty) {
           return Center(child: Text("Error: ${kosProvider.errorMessage}"));
        }
        if (kosProvider.savedKosList.isEmpty) {
          return const Center(child: Text('Belum ada info kos yang Anda simpan.'));
        }
        return ListView.builder(
          itemCount: kosProvider.savedKosList.length,
          itemBuilder: (ctx, index) {
            final savedKos = kosProvider.savedKosList[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: (savedKos.fotoKos != null && savedKos.fotoKos!.isNotEmpty)
                    ? SizedBox(width: 60, height: 60, child: Image.network(savedKos.fotoKos!, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.apartment)))
                    : const SizedBox(width: 60, height: 60, child: Icon(Icons.apartment, size: 40)),
                title: Text(savedKos.namaKos ?? 'Nama Kos Tidak Ada'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(savedKos.alamat ?? 'Alamat tidak ada', maxLines: 1, overflow: TextOverflow.ellipsis,),
                    Text('Disimpan: ${DateFormat('dd MMM yyyy, HH:mm').format(savedKos.waktuSimpan)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                   tooltip: 'Hapus dari favorit',
                  onPressed: () {
                    kosProvider.unfavoriteKosById(savedKos.id, userId, () {
                        if(mounted && kosProvider.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kos dihapus dari favorit'), duration: Duration(seconds: 1),)
                            );
                        }
                    });
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KosDetailScreen(kosId: savedKos.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}