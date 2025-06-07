import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_dipesan_model.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/account_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/account/fullmap_booked_kos_screen.dart'; // --- IMPORT HALAMAN PETA BARU ---
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/kos_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BookedKosListScreen extends StatefulWidget {
  const BookedKosListScreen({super.key});

  @override
  State<BookedKosListScreen> createState() => _BookedKosListScreenState();
}

class _BookedKosListScreenState extends State<BookedKosListScreen> {
  @override
  void initState() {
    super.initState();
    // Data sudah di-fetch oleh AccountScreen atau bisa di-fetch lagi di sini jika diperlukan
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
    //   if (authProvider.isAuthenticated && authProvider.userId != null) {
    //     Provider.of<AccountProvider>(context, listen: false).fetchBookedKos(authProvider.userId!);
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    // final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kos Dipesan'),
        actions: [
          if (accountProvider.bookedKosList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Lihat Semua di Peta',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullMapBookedKosScreen(
                      bookedKosList: accountProvider.bookedKosList,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Builder( // Gunakan Builder untuk memastikan context yang benar untuk RefreshIndicator
        builder: (context) {
          if (accountProvider.isLoadingBookedKos && accountProvider.bookedKosList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accountProvider.errorMessage != null && accountProvider.bookedKosList.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${accountProvider.errorMessage}")));
          }
          if (accountProvider.bookedKosList.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Anda belum memesan kos.')));
          }

          return RefreshIndicator(
            onRefresh: () async {
               final authProvider = Provider.of<AuthProvider>(context, listen: false);
               if (authProvider.isAuthenticated && authProvider.userId != null) {
                 await Provider.of<AccountProvider>(context, listen: false).fetchBookedKos(authProvider.userId!);
               }
            },
            child: ListView.builder(
              itemCount: accountProvider.bookedKosList.length,
              itemBuilder: (context, index) {
                final bookedKos = accountProvider.bookedKosList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: (bookedKos.fotoKos != null && bookedKos.fotoKos!.isNotEmpty)
                        ? SizedBox(width: 80, height: 80, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(bookedKos.fotoKos!, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.apartment, size:40))))
                        : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.apartment, size: 40, color: Colors.grey)),
                    title: Text(bookedKos.namaKos ?? 'Nama Kos Tidak Diketahui', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bookedKos.alamat ?? 'Alamat tidak diketahui', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('DP Dibayar: ${currencyFormatter.format(bookedKos.hargaDpDibayar ?? 0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                        // Text('Tgl Pesan: ${dateFormatter.format(bookedKos.tanggalPesan)}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => KosDetailScreen(kosId: bookedKos.kosId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}