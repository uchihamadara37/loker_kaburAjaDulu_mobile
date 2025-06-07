import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart';

class LowonganListItem extends StatelessWidget {
  final LowonganModel lowongan;
  final VoidCallback onTap;
  final bool isFavorite; // Opsional jika ingin menampilkan status favorit di list
  final VoidCallback onFavoriteToggle; // Opsional

  const LowonganListItem({
    super.key,
    required this.lowongan,
    required this.onTap,
    this.isFavorite = false, 
    required this.onFavoriteToggle
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lowongan.namaPerusahaan,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // --- Tombol Favorit di List Item ---
                  InkResponse( // Gunakan InkResponse untuk area tap yang lebih besar dan feedback
                    onTap: onFavoriteToggle,
                    radius: 20, // Sesuaikan radius splash
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : Colors.grey,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lowongan.deskripsiLowongan,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lowongan.alamat,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    lowongan.rentangGaji,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Diposting: ${TimeOfDay.fromDateTime(lowongan.waktuPosting).format(context)} - ${lowongan.waktuPosting.day}/${lowongan.waktuPosting.month}/${lowongan.waktuPosting.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              ),
              // Tombol favorit bisa ditambahkan di sini jika diinginkan
              // IconButton(
              //   icon: Icon(
              //     isFavorite ? Icons.favorite : Icons.favorite_border,
              //     color: isFavorite ? Colors.red : Colors.grey,
              //   ),
              //   onPressed: onFavoriteToggle,
              // )
            ],
          ),
        ),
      ),
    );
  }
}