import 'dart:io';
import 'package:flutter/material.dart'; // Pastikan Material diimport untuk showModalBottomSheet
import 'package:flutter/cupertino.dart'; // Untuk CupertinoActionSheet jika preferensi iOS look
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/kos_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/common/map_picker_screen.dart';
import 'package:provider/provider.dart';

class FormKosScreen extends StatefulWidget {
  final KosModel? kosToEdit;

  const FormKosScreen({super.key, this.kosToEdit});

  @override
  State<FormKosScreen> createState() => _FormKosScreenState();
}

class _FormKosScreenState extends State<FormKosScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaKosController = TextEditingController();
  final _alamatController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaPerBulanController = TextEditingController();
  final _hargaDpController = TextEditingController();
  // final _mataUangController = TextEditingController(text: 'IDR');
  String? _selectedCurrency;
  final _jumlahKamarController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _kontakController = TextEditingController();
  final _emailPemilikController = TextEditingController();

  LatLng? _selectedLocation;
  File? _selectedImageFile;
  String? _existingImageUrl;

  bool _isLoading = false;

  final List<String> _supportedCurrencies = ['IDR', 'USD', 'EUR', 'JPY', 'GBP', 'SGD', 'MYR', 'AUD'];

  @override
  void initState() {
    super.initState();
    if (widget.kosToEdit != null) {
      final kos = widget.kosToEdit!;
      _namaKosController.text = kos.namaKos;
      _alamatController.text = kos.alamat;
      _deskripsiController.text = kos.deskripsi;
      _hargaPerBulanController.text = kos.hargaPerbulan.toStringAsFixed(0);
      _hargaDpController.text = kos.hargaDp?.toStringAsFixed(0) ?? '';
      _selectedCurrency = kos.mataUangYangDipakai;
      _jumlahKamarController.text = kos.jumlahKamarTersedia.toString();
      _fasilitasController.text = kos.fasilitas;
      _kontakController.text = kos.kontak ?? '';
      _emailPemilikController.text = kos.email ?? '';
      _selectedLocation = LatLng(kos.latitude, kos.longitude);
      _existingImageUrl = kos.fotoKos;
    }else{
      _selectedCurrency = "IDR";
    }
  }

  @override
  void dispose() {
    _namaKosController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _hargaPerBulanController.dispose();
    _hargaDpController.dispose();
    // _mataUangController.dispose();
    _jumlahKamarController.dispose();
    _fasilitasController.dispose();
    _kontakController.dispose();
    _emailPemilikController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialPosition: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  // --- FUNGSI BARU UNTUK MEMILIH SUMBER GAMBAR ---
  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    // Untuk tampilan iOS-style, bisa gunakan CupertinoActionSheet
    // if (Platform.isIOS) {
    //   return showCupertinoModalPopup(
    //     context: context,
    //     builder: (BuildContext context) => CupertinoActionSheet(
    //       title: const Text('Pilih Sumber Gambar'),
    //       actions: <CupertinoActionSheetAction>[
    //         CupertinoActionSheetAction(
    //           child: const Text('Kamera'),
    //           onPressed: () {
    //             Navigator.pop(context);
    //             _getImage(ImageSource.camera);
    //           },
    //         ),
    //         CupertinoActionSheetAction(
    //           child: const Text('Galeri'),
    //           onPressed: () {
    //             Navigator.pop(context);
    //             _getImage(ImageSource.gallery);
    //           },
    //         )
    //       ],
    //       cancelButton: CupertinoActionSheetAction(
    //         isDefaultAction: true,
    //         onPressed: () {
    //           Navigator.pop(context);
    //         },
    //         child: const Text('Batal'),
    //       ),
    //     ),
    //   );
    // } else {
    // Untuk tampilan Material Design
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          // Untuk menghindari notch atau area sistem lainnya
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih Foto dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
    // }
  }

  // --- FUNGSI UNTUK MENGAMBIL GAMBAR (setelah sumber dipilih) ---
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70, // Kompresi kualitas gambar (0-100)
      maxWidth: 1024, // Batasi lebar maksimum gambar
      maxHeight: 1024, // Batasi tinggi maksimum gambar
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }
  // --- AKHIR MODIFIKASI FUNGSI GAMBAR ---

  Future<void> _submitForm() async {
    // ... (Fungsi _submitForm tetap sama seperti sebelumnya) ...
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi kos di peta.')),
      );
      return;
    }
    if (widget.kosToEdit == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto untuk kos.')),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final kosProvider = Provider.of<KosProvider>(context, listen: false);
    // List<String> fasilitasList = _fasilitasController.text
    //     .split(',')
    //     .map((s) => s.trim())
    //     .where((s) => s.isNotEmpty)
    //     .toList();
    final Map<String, dynamic> kosData = {
      'nama_kos': _namaKosController.text,
      'alamat': _alamatController.text,
      'deskripsi': _deskripsiController.text,
      'harga_perbulan': double.tryParse(_hargaPerBulanController.text) ?? 0.0,
      'harga_dp': _hargaDpController.text.isEmpty
          ? null
          : double.tryParse(_hargaDpController.text),
      'mata_uang_yang_dipakai': _selectedCurrency!,
      'jumlah_kamar_tersedia': int.tryParse(_jumlahKamarController.text) ?? 0,
      'fasilitas': _fasilitasController.text,
      'kontak': _kontakController.text.isEmpty ? null : _kontakController.text,
      'email': _emailPemilikController.text.isEmpty
          ? null
          : _emailPemilikController.text,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    };
    bool success = false;
    try {
      if (widget.kosToEdit == null) {
        success = await kosProvider.createKos(
          kosData,
          _selectedImageFile,
          authProvider.token!,
          authProvider.userId!,
        );
      } else {
        success = await kosProvider.updateKos(
          widget.kosToEdit!.id,
          kosData,
          _selectedImageFile,
          authProvider.token!,
          authProvider.userId!,
        );
      }
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Info Kos berhasil ${widget.kosToEdit == null ? "ditambahkan" : "diperbarui"}!',
              ),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                kosProvider.errorMessage ?? 'Gagal menyimpan info Kos.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kosToEdit == null ? 'Tambah Info Kos' : 'Edit Info Kos',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ... (Field form lainnya tetap sama) ...
                TextFormField(
                  controller: _namaKosController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kos/Properti',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Nama Kos tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap Kos',
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(labelText: 'Deskripsi Kos'),
                  maxLines: 5,
                  validator: (v) =>
                      v!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hargaPerBulanController,
                        decoration: const InputDecoration(
                          labelText: 'Harga/bulan',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v!.isEmpty ? 'Harga tidak boleh kosong' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Mata Uang',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        ),
                        items: _supportedCurrencies.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Pilih mata uang' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hargaDpController,
                  decoration: const InputDecoration(
                    labelText: 'Harga DP (Opsional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jumlahKamarController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Kamar Tersedia',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v!.isEmpty ? 'Jumlah kamar tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fasilitasController,
                  decoration: const InputDecoration(
                    labelText: 'Fasilitas (pisahkan dengan koma)',
                    hintText: 'WiFi, AC, Kamar Mandi Dalam',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Fasilitas tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kontakController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Kontak Pemilik (Opsional)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailPemilikController,
                  decoration: const InputDecoration(
                    labelText: 'Email Pemilik (Opsional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                Text(
                  'Foto Kos:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : (_existingImageUrl != null &&
                            _existingImageUrl!.isNotEmpty)
                      ? Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Center(
                            child: Text('Gagal memuat gambar lama'),
                          ),
                        )
                      : const Center(child: Text('Belum ada foto dipilih')),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _selectedImageFile != null ||
                            (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty)
                        ? 'Ganti Foto Kos'
                        : 'Pilih Foto Kos',
                  ),
                  // --- PANGGIL FUNGSI BARU DI SINI ---
                  onPressed: () => _showImageSourceActionSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Lokasi Peta:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLocation == null
                            ? 'Belum ada lokasi dipilih.'
                            : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          _selectedLocation == null
                              ? 'Pilih Lokasi di Peta'
                              : 'Ubah Lokasi di Peta',
                        ),
                        onPressed: _pickLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: Icon(
                          widget.kosToEdit == null
                              ? Icons.add_circle_outline
                              : Icons.save_outlined,
                        ),
                        label: Text(
                          widget.kosToEdit == null
                              ? 'TAMBAH INFO KOS'
                              : 'SIMPAN PERUBAHAN',
                        ),
                        onPressed: _submitForm,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
