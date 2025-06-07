import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/lowongan_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/lowongan/lowongan_detail_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/widgets/lowongan_list_item.dart'; 
import 'package:provider/provider.dart';
// --- PENAMBAHAN IMPORT ---
import 'package:loker_kabur_aja_dulu/presentation/screens/lowongan/form_lowongan_screen.dart'; 

class LowonganScreen extends StatefulWidget {
  const LowonganScreen({super.key});

  @override
  State<LowonganScreen> createState() => _LowonganScreenState();
}

class _LowonganScreenState extends State<LowonganScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.userId != null) {
        Provider.of<LowonganProvider>(context, listen: false)
            .fetchAllLowongan(userIdForFavorites: authProvider.userId!);
      } else {
         Provider.of<LowonganProvider>(context, listen: false).fetchAllLowongan();
      }
    });
    _searchController.addListener(() {
      Provider.of<LowonganProvider>(context, listen: false)
          .searchLowongan(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowonganProvider = context.watch<LowonganProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      floatingActionButton: authProvider.isAuthenticated && authProvider.userRole == 'HRD'
          ? FloatingActionButton(
              onPressed: () {
                // --- NAVIGASI KE FORM LOWONGAN ---
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FormLowonganScreen())
                ).then((_) {
                  // Refresh list setelah kembali dari form (jika ada penambahan/perubahan)
                  // Provider sudah handle refresh list setelah create/update berhasil
                  // jadi ini mungkin tidak selalu diperlukan, tapi bisa untuk kasus edge.
                  // final String? userId = authProvider.isAuthenticated ? authProvider.userId : null;
                  // lowonganProvider.fetchAllLowongan(userIdForFavorites: userId);
                });
              },
              backgroundColor: Theme.of(context).primaryColor,
              tooltip: 'Tambah Lowongan Baru',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari lowongan (judul, deskripsi, alamat)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: lowonganProvider.isLoading && lowonganProvider.allLowongan.isEmpty 
                ? const Center(child: CircularProgressIndicator())
                : lowonganProvider.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              'Gagal memuat data: ${lowonganProvider.errorMessage}\nSilakan coba lagi nanti.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
                    : lowonganProvider.filteredLowongan.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty 
                                ? 'Belum ada lowongan tersedia.'
                                : 'Lowongan tidak ditemukan untuk "${_searchController.text}".'
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                               final String? userId = authProvider.isAuthenticated ? authProvider.userId : null;
                               await lowonganProvider.fetchAllLowongan(userIdForFavorites: userId);
                            },
                            child: ListView.builder(
                              itemCount: lowonganProvider.filteredLowongan.length,
                              itemBuilder: (ctx, i) {
                                final lowongan = lowonganProvider.filteredLowongan[i];
                                return LowonganListItem(
                                  lowongan: lowongan,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => LowonganDetailScreen(lowonganId: lowongan.id),
                                      ),
                                    );
                                  },
                                  isFavorite: lowonganProvider.isFavorite(lowongan.id), // Dapatkan status favorit
                                  onFavoriteToggle: () {
                                    if (authProvider.isAuthenticated && authProvider.userId != null) {
                                      lowonganProvider.toggleFavorite(lowongan, authProvider.userId!);
                                    } else {
                                      // Arahkan ke login atau tampilkan pesan
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Silakan login untuk menyimpan favorit.')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}