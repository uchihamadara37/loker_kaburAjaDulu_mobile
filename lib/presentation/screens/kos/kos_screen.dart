import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/kos_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/form_kos_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/kos_detail_screen.dart'; // Akan dibuat
import 'package:loker_kabur_aja_dulu/presentation/widgets/kos_list_item.dart'; // Akan dibuat
import 'package:provider/provider.dart';
// import 'package:kabur_aja_dulu/presentation/screens/kos/form_kos_screen.dart'; // Untuk HRD nanti

class KosScreen extends StatefulWidget {
  const KosScreen({super.key});

  @override
  State<KosScreen> createState() => _KosScreenState();
}

class _KosScreenState extends State<KosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String? currentUserId = authProvider.isAuthenticated
          ? authProvider.userId
          : null;
      Provider.of<KosProvider>(
        context,
        listen: false,
      ).fetchAllKos(userIdForFavorites: currentUserId);
    });
    _searchController.addListener(() {
      Provider.of<KosProvider>(
        context,
        listen: false,
      ).searchKos(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kosProvider = context.watch<KosProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      floatingActionButton:
          authProvider.isAuthenticated && authProvider.userRole == 'HRD'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const FormKosScreen(),
                      ), // Navigasi ke form
                    )
                    .then((_) {
                      // Optional: Refresh list jika kembali dari form
                      final String? currentUserId = authProvider.isAuthenticated ? authProvider.userId : null;
                      Provider.of<KosProvider>(context, listen: false).fetchAllKos(userIdForFavorites: currentUserId);
                    });
              },
              backgroundColor: Theme.of(context).primaryColor,
              tooltip: 'Tambah Info Kos',
              child: const Icon(Icons.add_home_outlined, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama kos, alamat, deskripsi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: kosProvider.isLoading && kosProvider.allKos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : kosProvider.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Gagal memuat data: ${kosProvider.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  )
                : kosProvider.filteredKos.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Belum ada info kos tersedia.'
                          : 'Kos tidak ditemukan untuk "${_searchController.text}".',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      final String? userId = authProvider.isAuthenticated
                          ? authProvider.userId
                          : null;
                      await kosProvider.fetchAllKos(userIdForFavorites: userId);
                    },
                    child: ListView.builder(
                      itemCount: kosProvider.filteredKos.length,
                      itemBuilder: (ctx, i) {
                        final kos = kosProvider.filteredKos[i];
                        return KosListItem(
                          kos: kos,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    KosDetailScreen(kosId: kos.id),
                              ),
                            );
                          },
                          isFavorite: kosProvider.isKosFavorite(kos.id),
                          onFavoriteToggle: () {
                            if (authProvider.isAuthenticated &&
                                authProvider.userId != null) {
                              kosProvider.toggleKosFavorite(
                                kos,
                                authProvider.userId!,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Silakan login untuk menyimpan favorit.',
                                  ),
                                ),
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
