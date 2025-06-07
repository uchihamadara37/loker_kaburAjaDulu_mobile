import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';

class KosListItem extends StatelessWidget {
  final KosModel kos;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const KosListItem({
    super.key,
    required this.kos,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias, // Untuk memastikan gambar di dalam Card terpotong sesuai shape
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tampilan Gambar Kos ---
            (kos.fotoKos != null && kos.fotoKos!.isNotEmpty)
                ? Hero( // Animasi transisi gambar
                    tag: 'kosImage_${kos.id}',
                    child: Image.network(
                      kos.fotoKos!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                        );
                      },
                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.apartment_outlined, size: 60, color: Colors.grey[700]))
                  ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          kos.namaKos,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkResponse(
                        onTap: onFavoriteToggle,
                        radius: 20,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.grey,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kos.alamat,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${kos.hargaPerbulan.toStringAsFixed(0)} ${kos.mataUangYangDipakai} / month', // Asumsi harga dalam IDR atau mata uang lain
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  if (kos.fasilitas.isNotEmpty)
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: kos.fasilitas.split(',').map((fasilitas) => Chip(
                        label: Text(fasilitas.trim(), style: const TextStyle(fontSize: 10)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        backgroundColor: Colors.teal[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.teal.withOpacity(0.5))
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}