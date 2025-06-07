import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Untuk tipe LatLng
import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart'; // Untuk enum JenisPenempatan
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/lowongan_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/common/map_picker_screen.dart';
import 'package:provider/provider.dart';

class FormLowonganScreen extends StatefulWidget {
  final LowonganModel? lowonganToEdit; // Untuk mode edit, opsional

  const FormLowonganScreen({super.key, this.lowonganToEdit});

  @override
  State<FormLowonganScreen> createState() => _FormLowonganScreenState();
}

class _FormLowonganScreenState extends State<FormLowonganScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk setiap field
  final _namaPerusahaanController = TextEditingController();
  final _alamatController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _rentangGajiController = TextEditingController();
  final _jumlahJamKerjaController = TextEditingController();
  final _contactEmailController = TextEditingController();

  JenisPenempatan _selectedJenisPenempatan = JenisPenempatan.WFO; // Default
  LatLng? _selectedLocation; // Untuk menyimpan LatLng dari map picker

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lowonganToEdit != null) {
      // Pre-fill form jika mode edit
      _namaPerusahaanController.text = widget.lowonganToEdit!.namaPerusahaan;
      _alamatController.text = widget.lowonganToEdit!.alamat;
      _deskripsiController.text = widget.lowonganToEdit!.deskripsiLowongan;
      _rentangGajiController.text = widget.lowonganToEdit!.rentangGaji;
      _jumlahJamKerjaController.text = widget.lowonganToEdit!.jumlahJamKerja;
      _contactEmailController.text = widget.lowonganToEdit!.contactEmail;
      _selectedJenisPenempatan = widget.lowonganToEdit!.jenisPenempatan;
      _selectedLocation = LatLng(
        widget.lowonganToEdit!.latitude,
        widget.lowonganToEdit!.longitude,
      );
    }
  }

  @override
  void dispose() {
    _namaPerusahaanController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _rentangGajiController.dispose();
    _jumlahJamKerjaController.dispose();
    _contactEmailController.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi lowongan di peta.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lowonganProvider = Provider.of<LowonganProvider>(
      context,
      listen: false,
    );

    final Map<String, dynamic> lowonganData = {
      'nama_perusahaan': _namaPerusahaanController.text,
      'alamat': _alamatController.text,
      'deskripsi_lowongan': _deskripsiController.text,
      'rentang_gaji': _rentangGajiController.text,
      'jenisPenempatan': _selectedJenisPenempatan.name, // Kirim sebagai string
      'jumlah_jam_kerja': _jumlahJamKerjaController.text,
      'contact_email': _contactEmailController.text,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      // hrd_yang_post_id akan dihandle backend dari token
    };

    bool success = false;
    try {
      if (widget.lowonganToEdit == null) {
        // Mode Create
        print("Mode create");
        success = await lowonganProvider.createLowongan(
          lowonganData,
          authProvider.token!,
          authProvider.userId!, // Untuk refresh favorit
        );
      } else {
        // Mode Edit
        print("Mode edit");
        success = await lowonganProvider.updateLowongan(
          widget.lowonganToEdit!.id,
          lowonganData,
          authProvider.token!,
          authProvider.userId!, // Untuk refresh favorit
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lowongan berhasil ${widget.lowonganToEdit == null ? "dibuat" : "diperbarui"}!',
              ),
            ),
          );
          Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lowonganProvider.errorMessage ?? 'Gagal menyimpan lowongan.',
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
          widget.lowonganToEdit == null
              ? 'Tambah Lowongan Baru'
              : 'Edit Lowongan',
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
                TextFormField(
                  controller: _namaPerusahaanController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perusahaan',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama perusahaan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap Perusahaan',
                  ),
                  maxLines: 2,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Alamat tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Lowongan',
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Deskripsi tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rentangGajiController,
                  decoration: const InputDecoration(
                    labelText: 'Rentang Gaji (misal: "1200-1800 EU /month")',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Rentang gaji tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<JenisPenempatan>(
                  value: _selectedJenisPenempatan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Penempatan',
                  ),
                  items: JenisPenempatan.values
                      .where(
                        (element) => element != JenisPenempatan.UNKNOWN,
                      ) // Jangan tampilkan UNKNOWN
                      .map((JenisPenempatan value) {
                        return DropdownMenuItem<JenisPenempatan>(
                          value: value,
                          child: Text(
                            value.name,
                          ), // Tampilkan nama enum (WFA, WFH, dll)
                        );
                      })
                      .toList(),
                  onChanged: (JenisPenempatan? newValue) {
                    setState(() {
                      _selectedJenisPenempatan = newValue!;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Pilih jenis penempatan' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jumlahJamKerjaController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Jam Kerja (misal: "8 hours/day")',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Jumlah jam kerja tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Kontak Rekrutmen',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email kontak tidak boleh kosong';
                    if (!value.contains('@') || !value.contains('.'))
                      return 'Masukkan format email yang valid';
                    return null;
                  },
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
                          widget.lowonganToEdit == null
                              ? Icons.add_circle_outline
                              : Icons.save_outlined,
                        ),
                        label: Text(
                          widget.lowonganToEdit == null
                              ? 'TAMBAH LOWONGAN'
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
