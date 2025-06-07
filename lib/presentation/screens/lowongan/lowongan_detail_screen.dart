import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loker_kabur_aja_dulu/core/constants/google_constants.dart'; // Pastikan path ini benar
import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/lowongan_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/lowongan/form_lowongan_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;

class LowonganDetailScreen extends StatefulWidget {
  final String lowonganId;

  const LowonganDetailScreen({super.key, required this.lowonganId});

  @override
  State<LowonganDetailScreen> createState() => _LowonganDetailScreenState();
}

class _LowonganDetailScreenState extends State<LowonganDetailScreen> {
  GoogleMapController? _mapController;

  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // State untuk menyimpan rute
  bool _isFetchingLocation = false;
  bool _isFetchingDirections = false; // State untuk loading rute

  String? _routeDistance; // State untuk jarak rute
  String? _routeDuration; // State untuk durasi rute

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Jadikan async untuk await
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lowonganProvider = Provider.of<LowonganProvider>(
        context,
        listen: false,
      );

      // Fetch detail lowongan
      await lowonganProvider.fetchLowonganById(
        widget.lowonganId,
        userIdForFavorites: authProvider.isAuthenticated
            ? authProvider.userId
            : null,
      );

      // Setelah data lowongan ada, update marker dan coba dapatkan lokasi perangkat
      if (mounted) {
        _updateMarkers(); // Update marker untuk lowongan (jika lowongan sudah ada)
        await _getCurrentLocation(); // Ini akan memanggil _updateMarkers() lagi setelah lokasi didapat
      }
    });
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Permohonan Lowongan Kerja - [Nama Anda]',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa membuka aplikasi email untuk $email'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // --- FUNGSI UNTUK MENDAPATKAN LOKASI SAAT INI ---
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi mati. Silakan aktifkan.'),
          ),
        );
      }
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen, kami tidak dapat meminta izin.',
            ),
          ),
        );
      }
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        // locationSettings adalah untuk stream, untuk getCurrentPosition cukup desiredAccuracy
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _updateMarkers();
        _isFetchingLocation = false;
      });
    } catch (e) {
      print("Error mendapatkan lokasi: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  // --- FUNGSI UNTUK MEMPERBARUI MARKER DI PETA ---
  void _updateMarkers() {
    final lowongan = Provider.of<LowonganProvider>(
      context,
      listen: false,
    ).selectedLowongan;
    Set<Marker> tempMarkers = {};

    if (lowongan != null) {
      tempMarkers.add(
        Marker(
          markerId: MarkerId("lowongan_${lowongan.id}"), // Pastikan ID unik
          position: LatLng(lowongan.latitude, lowongan.longitude),
          infoWindow: InfoWindow(
            title: lowongan.namaPerusahaan,
            snippet: lowongan.alamat,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Lokasi Saya'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ), // Warna berbeda
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = tempMarkers;
      });
    }
  }

  // --- FUNGSI BARU UNTUK MENDAPATKAN DAN MENGGAMBAR RUTE ---
  Future<void> _getDirections() async {
    final lowongan = Provider.of<LowonganProvider>(
      context,
      listen: false,
    ).selectedLowongan;
    if (_currentPosition == null || lowongan == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi Anda atau lokasi tujuan belum tersedia.'),
          ),
        );
      }
      return;
    }

    // Pastikan Anda sudah mengganti GoogleConstants.googleApiKey dengan API Key yang valid
    if (google_api_key.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'API Key Google Maps belum dikonfigurasi untuk Directions API.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isFetchingDirections = true;
      _polylines.clear();
      _routeDistance = null;
      _routeDuration = null;
    });

    PolylinePoints polylinePoints = PolylinePoints();
    PointLatLng origin = PointLatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    PointLatLng destination = PointLatLng(
      lowongan.latitude,
      lowongan.longitude,
    );

    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=${google_api_key}";

      print("Directions API URL: $url");

      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          List<PointLatLng> result = polylinePoints.decodePolyline(
            data['routes'][0]['overview_polyline']['points'],
          );
          List<LatLng> polylineCoordinates = [];
          if (result.isNotEmpty) {
            for (var point in result) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          }

          String distance = data['routes'][0]['legs'][0]['distance']['text'];
          String duration = data['routes'][0]['legs'][0]['duration']['text'];

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue.shade500, // Warna rute
                width: 6, // Lebar garis rute
              ),
            );
            _routeDistance = distance;
            _routeDuration = duration;

            if (_mapController != null && polylineCoordinates.isNotEmpty) {
              double minLat = origin.latitude;
              double maxLat = origin.latitude;
              double minLng = origin.longitude;
              double maxLng = origin.longitude;

              void updateBounds(LatLng point) {
                if (point.latitude < minLat) minLat = point.latitude;
                if (point.latitude > maxLat) maxLat = point.latitude;
                if (point.longitude < minLng) minLng = point.longitude;
                if (point.longitude > maxLng) maxLng = point.longitude;
              }

              updateBounds(LatLng(destination.latitude, destination.longitude));
              for (var point in polylineCoordinates) {
                updateBounds(point);
              }

              _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(minLat, minLng),
                    northeast: LatLng(maxLat, maxLng),
                  ),
                  70.0, // Padding
                ),
              );
            }
          });
        } else {
          print(
            "Directions API Error: ${data['status']} - ${data['error_message'] ?? 'No route found'}",
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal mendapatkan rute: ${data['error_message'] ?? data['status'] ?? 'Tidak ada rute ditemukan'}',
                ),
              ),
            );
          }
        }
      } else {
        print(
          "HTTP Error fetching directions: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghubungi layanan rute.')),
          );
        }
      }
    } catch (e) {
      print("Error in _getDirections: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mengambil rute: $e')),
        );
      }
    } finally {
      setState(() {
        _isFetchingDirections = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowonganProvider = context.watch<LowonganProvider>();
    final authProvider = context.watch<AuthProvider>();
    final LowonganModel? lowongan = lowonganProvider.selectedLowongan;

    if (lowonganProvider.isLoading && lowongan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Detail...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (lowongan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Lowongan')),
        body: Center(
          child: Text(
            lowonganProvider.errorMessage ??
                'Lowongan tidak ditemukan atau gagal dimuat.',
          ),
        ),
      );
    }

    final isFavorite = lowonganProvider.isFavorite(lowongan.id);
    final LatLng jobLocation = LatLng(lowongan.latitude, lowongan.longitude);
    // print("Job lokasi : ${jobLocation}"); // Anda sudah punya ini, bagus untuk debug

    void onMapCreated(GoogleMapController controller) {
      // Pindahkan definisi ini ke scope yang benar
      _mapController = controller;
      // Anda tidak perlu memanggil updateCamera() di sini lagi jika initialCameraPosition sudah diatur
      // dan _updateMarkers() akan mengatur marker.
      // updateCamera(); // Komentari atau hapus jika tidak diperlukan
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Lowongan ${isFavorite ? '(Favorite)' : ""}",
          style: TextStyle(
            fontSize: 18
          ),
        ),
        actions: [
          if (authProvider.isAuthenticated && authProvider.userId != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.bookmark_add_outlined,
                color: isFavorite ? Colors.red : Colors.orange,
                size: 40,
              ),
              onPressed: () {
                // lowonganProvider.toggleFavorite(lowongan, authProvider.userId!);
                if (authProvider.userId != null) {
                   lowonganProvider.toggleFavorite(lowongan, authProvider.userId!);
                } else {
                   // Seharusnya tidak terjadi jika sudah isAuthenticated, tapi sebagai fallback
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Silakan login untuk menggunakan fitur favorit.'))
                   );
                }
              },
            ),
          if (authProvider.isAuthenticated &&
              authProvider.userRole == 'HRD' &&
              authProvider.userId == lowongan.hrdYangPostId) // Hanya HRD yang post bisa edit/delete
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // --- NAVIGASI KE FORM EDIT ---
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FormLowonganScreen(lowonganToEdit: lowongan),
                    ),
                  ).then((_) {
                    // Refresh detail jika ada perubahan setelah kembali dari form edit
                    // Provider sudah handle fetchLowonganById di update, tapi ini untuk memastikan UI detail update
                    final String? currentUserId = authProvider.isAuthenticated ? authProvider.userId : null;
                    lowonganProvider.fetchLowonganById(widget.lowonganId, userIdForFavorites: currentUserId);
                  });
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(context, lowonganProvider, lowongan.id, authProvider.token!);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit Lowongan')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Lowongan')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lowongan.namaPerusahaan,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.business_outlined,
              'Deskripsi',
              lowongan.deskripsiLowongan,
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Alamat',
              lowongan.alamat,
            ),
            _buildInfoRow(
              Icons.attach_money_outlined,
              'Rentang Gaji',
              lowongan.rentangGaji,
            ),
            _buildInfoRow(
              Icons.work_history_outlined,
              'Jenis Penempatan',
              lowongan.jenisPenempatan.name,
            ),
            _buildInfoRow(
              Icons.timer_outlined,
              'Jam Kerja',
              lowongan.jumlahJamKerja,
            ),
            _buildInfoRow(
              Icons.email_outlined,
              'Kontak Email',
              lowongan.contactEmail,
              isEmail: true,
              onTap: () => _launchEmail(lowongan.contactEmail),
            ),
            _buildInfoRow(
              Icons.person_pin_circle_outlined,
              'HRD Pemosting',
              // Menampilkan info HRD dengan lebih baik
              'Nama: ${lowongan.hrd?.nama ?? "N/A"}\nEmail: ${lowongan.hrd?.email ?? "N/A"}\nLinkedIn: ${lowongan.hrd?.linkLinkedIn ?? "N/A"}',
            ),
            _buildInfoRow(
              Icons.access_time_filled_outlined,
              'Diposting',
              '${TimeOfDay.fromDateTime(lowongan.waktuPosting).format(context)} - ${lowongan.waktuPosting.day}/${lowongan.waktuPosting.month}/${lowongan.waktuPosting.year}',
            ),

            const SizedBox(height: 20),
            // --- UI UNTUK TOMBOL RUTE DAN INFO JARAK ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peta & Rute:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isFetchingLocation ||
                    _isFetchingDirections) // Tampilkan loading jika salah satu proses berjalan
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        // Tombol refresh lokasi pengguna
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Dapatkan Lokasi Saya',
                      ),
                      IconButton(
                        // Tombol untuk menampilkan rute
                        icon: const Icon(
                          Icons.directions,
                          color: Colors.blueAccent,
                        ),
                        onPressed: _getDirections,
                        tooltip: 'Tampilkan Rute',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Tampilkan info jarak dan durasi jika ada
            if (_routeDistance != null && _routeDuration != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Jarak: $_routeDistance\nEstimasi Waktu: $_routeDuration',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            // --- AKHIR UI UNTUK RUTE ---
            SizedBox(
              height: 450,
              child: GoogleMap(
                onMapCreated:
                    onMapCreated, // Gunakan onMapCreated yang sudah didefinisikan
                initialCameraPosition: CameraPosition(
                  target: jobLocation,
                  zoom: 4.0,
                ),
                markers: _markers, // Gunakan state _markers
                polylines: _polylines, // Tambahkan state _polylines
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isEmail = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: isEmail ? onTap : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEmail ? Colors.blue : Colors.black87,
                      decoration: isEmail
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    LowonganProvider provider,
    String lowonganId,
    String token,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus lowongan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authP = Provider.of<AuthProvider>(context, listen: false);
              final success = await provider.deleteLowongan(
                lowonganId,
                token,
                authP.userId!,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lowongan berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Gagal menghapus lowongan.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
