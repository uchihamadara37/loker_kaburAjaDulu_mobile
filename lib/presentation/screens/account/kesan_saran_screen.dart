import 'package:flutter/material.dart';

class KesanSaranScreen extends StatelessWidget {
  const KesanSaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan dan Saran'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Profil Anda ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    // Ganti dengan URL foto Anda atau gunakan asset lokal
                    backgroundImage: AssetImage(
                      "assets/andre.jpg",
                    ),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Andrea Alfian Sah Putra',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: 123220078', // Ganti dengan NIM Anda
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // --- Bagian Kesan ---
            Text(
              'Kesan Selama Perkuliahan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Mata kuliah Teknologi Mobile ini memberikan pengalaman yang sangat berharga di mana kita dituntut untuk tetap bugar, meski banyak tugas dan urusan menumpuk. Saya belajar banyak hal mengenai pengembangan aplikasi mobile, khususnya menggunakan Flutter. Dari mata kuliah ini saya menjadi mengerti akan pentingnya manajemen waktu dan manajemen team. \n\nProyek akhir ini menjadi puncak kami menyalurkan hasil kemampuan problem solfing dan prompting yang selama ini kami lakukan, yang pada akhirnya menjadi sebuah aplikasi yang fungsional, meskipun masih dalam skala simulasi.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // --- Bagian Saran ---
             Text(
              'Saran untuk Perkuliahan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
             Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Untuk pembelajaran Teknologi Pemrograman Mobile ke depannya, lebih baik tugas kelompok ditiadakan, dan hanya tersisa 3 tugas dev_individu, agar setiap orang mampu mengembangkan dirinya secara lebih optimal, sehingga jika salah satu mahasiswa ingin menggunakan React Native atau C#, dia bisa langsung mempelajarinya. \n\nKemudian hendaklah Pak Bagus selaku dosen berkoordinasi dengan dosen lain terkait mata kuliah ADBO dan UKPL apabila ingin menyertakan isi tugas yang berkaitan dengan mata kuliah tersebut, sehingga kami tidak kehabisan waktu mengerjakan dua kali.',
                   textAlign: TextAlign.justify,
                   style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}