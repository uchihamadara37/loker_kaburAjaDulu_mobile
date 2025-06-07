import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/account_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/kos_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/kos/form_kos_screen.dart';
import 'package:loker_kabur_aja_dulu/services/currency_service.dart';
// import 'package:loker_kabur_aja_dulu/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/google_constants.dart';
// import 'package:kabur_aja_dulu/presentation/screens/kos/form_kos_screen.dart'; // Untuk HRD nanti

class BookingDialogResult {
  final bool confirmed;
  final int?
  delayMinutes; // Nullable jika tidak ada pilihan / tidak ingin notif

  BookingDialogResult({required this.confirmed, this.delayMinutes});
}

class KosDetailScreen extends StatefulWidget {
  final String kosId;

  const KosDetailScreen({super.key, required this.kosId});

  @override
  State<KosDetailScreen> createState() => _KosDetailScreenState();
}

class _KosDetailScreenState extends State<KosDetailScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isFetchingLocation = false;
  bool _isFetchingDirections = false;
  String? _routeDistance;
  String? _routeDuration;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final kosProvider = Provider.of<KosProvider>(context, listen: false);
      final String? currentUserId = authProvider.isAuthenticated
          ? authProvider.userId
          : null;

      await kosProvider.fetchKosById(
        widget.kosId,
        userIdForFavorites: currentUserId,
      );

      if (mounted) {
        _updateMarkers();
        await _getCurrentLocation();
      }
    });
  }

  Future<void> _loadAccountData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    if (authProvider.isAuthenticated && authProvider.userId != null) {
      await accountProvider.fetchCurrentUserSaldo(authProvider.userId!);
      await accountProvider.fetchBookedKos(authProvider.userId!);
    }
  }

  void _onMapCreated(GoogleMapController controller) =>
      _mapController = controller;

  Future<void> _launchCaller(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor kontak tidak tersedia.')),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa melakukan panggilan ke $phoneNumber'),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat email tidak tersedia.')),
      );
      return;
    }
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Pertanyaan tentang Kos - [Nama Anda]',
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

  Future<void> _getCurrentLocation() async {
    /* ... Sama seperti di LowonganDetailScreen ... */
    setState(() {
      _isFetchingLocation = true;
    });
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Layanan lokasi mati.')));
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
          const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
        );
      }
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _updateMarkers();
        _isFetchingLocation = false;
      });
    } catch (e) {
      print("Error lokasi: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal dapat lokasi: $e')));
      }
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  void _updateMarkers() {
    /* ... Sama seperti di LowonganDetailScreen, tapi gunakan kosProvider.selectedKos ... */
    final kos = Provider.of<KosProvider>(context, listen: false).selectedKos;
    Set<Marker> tempMarkers = {};
    if (kos != null) {
      tempMarkers.add(
        Marker(
          markerId: MarkerId("kos_${kos.id}"),
          position: LatLng(kos.latitude, kos.longitude),
          infoWindow: InfoWindow(title: kos.namaKos, snippet: kos.alamat),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    } // Warna beda untuk kos
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
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = tempMarkers;
      });
    }
  }

  Future<void> _getDirections() async {
    /* ... Sama seperti di LowonganDetailScreen, tapi gunakan kosProvider.selectedKos ... */
    final kos = Provider.of<KosProvider>(context, listen: false).selectedKos;
    if (_currentPosition == null || kos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi Anda atau tujuan belum tersedia.'),
          ),
        );
      }
      return;
    }
    if (google_api_key.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key belum dikonfigurasi.')),
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
    PointLatLng destination = PointLatLng(kos.latitude, kos.longitude);
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=${google_api_key}";
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          List<PointLatLng> result = polylinePoints.decodePolyline(
            data['routes'][0]['overview_polyline']['points'],
          );
          List<LatLng> polylineCoordinates = result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          String distance = data['routes'][0]['legs'][0]['distance']['text'];
          String duration = data['routes'][0]['legs'][0]['duration']['text'];
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('routeKos'),
                points: polylineCoordinates,
                color: Colors.lightBlueAccent,
                width: 6,
              ),
            );
            _routeDistance = distance;
            _routeDuration = duration;
            if (_mapController != null && polylineCoordinates.isNotEmpty) {
              /* ... Logika newLatLngBounds ... */
              double minLat = origin.latitude,
                  maxLat = origin.latitude,
                  minLng = origin.longitude,
                  maxLng = origin.longitude;
              void updateBounds(LatLng point) {
                minLat = point.latitude < minLat ? point.latitude : minLat;
                maxLat = point.latitude > maxLat ? point.latitude : maxLat;
                minLng = point.longitude < minLng ? point.longitude : minLng;
                maxLng = point.longitude > maxLng ? point.longitude : maxLng;
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
                  70.0,
                ),
              );
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Rute Error: ${data['error_message'] ?? data['status'] ?? 'Tidak ada rute'}',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal hubungi layanan rute.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ambil rute: $e')));
      }
    } finally {
      setState(() {
        _isFetchingDirections = false;
      });
    }
  }

  Future<void> _handleBooking(
    KosModel kos,
    AuthProvider authProvider,
    AccountProvider accountProvider,
  ) async {
    if (!authProvider.isAuthenticated || authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk memesan.')),
      );
      return;
    }
    if (kos.hargaDp == null || kos.hargaDp! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Info DP untuk kos ini tidak tersedia.')),
      );
      return;
    }

    final currencyService = CurrencyService();
    // Daftar mata uang yang bisa dipilih pengguna
    final List<String> availableCurrencies = [
      'IDR',
      'USD',
      'EUR',
      'JPY',
      'GBP',
      'SGD',
      'MYR',
      'AUD',
    ];

    final bool? confirmBooking = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Jangan tutup dialog saat klik di luar
      builder: (ctxDialog) {
        // Gunakan StatefulBuilder untuk mengelola state di dalam dialog
        String selectedPaymentCurrency = kos.mataUangYangDipakai;
        bool isLoadingConversion = false; // Mulai dengan false
        String? conversionError;
        Map<String, dynamic>? conversionRates;
        bool isInitialFetchDone =
            false; // Flag untuk memastikan fetch hanya sekali saat awal

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            // Fungsi helper untuk memanggil API
            void fetchRates() {
              setStateDialog(() {
                isLoadingConversion = true;
                conversionError = null;
                conversionRates = null; // Kosongkan rate sebelumnya
              });

              currencyService
                  .getConversionRates(
                    baseCurrency: kos.mataUangYangDipakai,
                    targetCurrencies: [selectedPaymentCurrency, 'IDR'],
                  )
                  .then((rates) {
                    if (mounted) {
                      setStateDialog(() {
                        conversionRates = rates;
                        isLoadingConversion = false;
                      });
                    }
                  })
                  .catchError((e) {
                    if (mounted) {
                      setStateDialog(() {
                        conversionError = e.toString();
                        isLoadingConversion = false;
                      });
                    }
                  });
            }

            // --- PERBAIKAN: Panggil fetchRates hanya sekali saat awal ---
            if (!isInitialFetchDone) {
              isInitialFetchDone = true; // Set flag agar tidak dijalankan lagi
              // Gunakan post-frame callback untuk aman dari error "setState during build"
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchRates();
              });
            }

            double finalAmountInSelectedCurrency = 0;
            double finalAmountInIDR = 0;

            if (conversionRates != null) {
              final rateToSelected = conversionRates![selectedPaymentCurrency];
              final rateToIDR = conversionRates!['IDR'];
              if (rateToSelected != null) {
                finalAmountInSelectedCurrency =
                    (kos.hargaDp ?? 0) * rateToSelected;
              }
              if (rateToIDR != null) {
                finalAmountInIDR = (kos.hargaDp ?? 0) * rateToIDR;
              }
            }

            final currencyFormatterIDR = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );
            final currencyFormatterGeneral = NumberFormat.currency(
              symbol: '',
              decimalDigits: 2,
            );

            return AlertDialog(
              title: const Text('Konfirmasi Pembayaran DP'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anda akan membayar DP untuk "${kos.namaKos}" senilai ${kos.hargaDp} ${kos.mataUangYangDipakai}.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Mata Uang Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedPaymentCurrency,
                      items: availableCurrencies
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null &&
                            newValue != selectedPaymentCurrency) {
                          // Tidak perlu setStateDialog di sini karena fetchRates sudah melakukannya
                          selectedPaymentCurrency =
                              newValue; // Update variabelnya saja
                          fetchRates(); // Panggil fetchRates saat user mengganti mata uang
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isLoadingConversion)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (conversionError != null)
                      Text(
                        'Gagal memuat kurs: $conversionError',
                        style: const TextStyle(color: Colors.redAccent),
                      )
                    else if (conversionRates != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurs: 1 ${kos.mataUangYangDipakai} = ${currencyFormatterGeneral.format(conversionRates![selectedPaymentCurrency] ?? 0)} $selectedPaymentCurrency',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total DP: ${kos.hargaDp} ${kos.mataUangYangDipakai} = ${currencyFormatterGeneral.format(finalAmountInSelectedCurrency)} $selectedPaymentCurrency',
                            ),
                            const Divider(height: 16),
                            Text(
                              'Total yang akan dipotong dari saldo (IDR):',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              currencyFormatterIDR.format(finalAmountInIDR),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text('Data kurs tidak tersedia.'),

                    const SizedBox(height: 16),
                    accountProvider.isLoadingSaldo
                        ? const SizedBox(
                            height: 16,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Saldo Anda saat ini: ${currencyFormatterIDR.format(accountProvider.currentUserSaldo?.saldo)}',
                          ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(ctxDialog).pop(false),
                ),
                ElevatedButton(
                  onPressed: (isLoadingConversion || conversionRates == null)
                      ? null
                      : () {
                          Navigator.of(ctxDialog).pop(true);
                        },
                  child: accountProvider.isProcessingBooking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Konfirmasi & Bayar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmBooking == true) {
      // Hitung ulang final amount in IDR untuk memastikan konsistensi
      // Ini penting jika state di dialog tidak di-pass keluar
      final rates = await currencyService.getConversionRates(
        baseCurrency: kos.mataUangYangDipakai,
        targetCurrencies: ['IDR'],
      );
      final rateToIDR = rates['IDR'];

      if (rateToIDR == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal mendapatkan kurs IDR. Pembayaran dibatalkan.',
              ),
            ),
          );
        return;
      }

      final double finalAmountToDeductInIDR = (kos.hargaDp ?? 0) * rateToIDR;

      final result = await accountProvider.processBookingAndPayDp(
        authProvider.userId!,
        kos,
        finalAmountToDeductInIDR, // Gunakan jumlah IDR yang sudah dikonversi
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: result['success'] == true
                ? Colors.green
                : Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kosProvider = context.watch<KosProvider>();
    final authProvider = context.watch<AuthProvider>();

    final accountProvider = context.watch<AccountProvider>();
    final KosModel? kos = kosProvider.selectedKos;

    if (kosProvider.isLoading && kos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Detail Kos...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (kos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kos')),
        body: Center(
          child: Text(kosProvider.errorMessage ?? 'Info Kos tidak ditemukan.'),
        ),
      );
    }

    final isFavorite = kosProvider.isKosFavorite(kos.id);
    final LatLng kosLocation = LatLng(kos.latitude, kos.longitude);
    print(
      "autentikasi : ${authProvider.isAuthenticated} role:${authProvider.userRole} userid:${authProvider.userId} kospId:${kos.pemilik?.id}",
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(kos.namaKos),
        actions: [
          if (authProvider.isAuthenticated && authProvider.userId != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.bookmark_add_outlined,
                color: isFavorite ? Colors.redAccent : Colors.orange,
                size: 40,
              ),
              tooltip: isFavorite ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
              onPressed: () {
                if (authProvider.userId != null) {
                  kosProvider.toggleKosFavorite(kos, authProvider.userId!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login untuk simpan favorit.'),
                    ),
                  );
                }
              },
            ),
          if (authProvider.isAuthenticated &&
              authProvider.userRole == 'HRD' &&
              authProvider.userId == kos.pemilikId)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => FormKosScreen(
                            kosToEdit: kos,
                          ), // Kirim data kos untuk diedit
                        ),
                      )
                      .then((_) {
                        // Optional: Refresh detail
                        final String? currentUserId =
                            authProvider.isAuthenticated
                            ? authProvider.userId
                            : null;
                        Provider.of<KosProvider>(
                          context,
                          listen: false,
                        ).fetchKosById(
                          widget.kosId,
                          userIdForFavorites: currentUserId,
                        );
                      });
                } else if (value == 'delete') {
                  _showDeleteKosConfirmationDialog(
                    context,
                    kosProvider,
                    kos.id,
                    authProvider.token!,
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Kos')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus Kos')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kos.fotoKos != null && kos.fotoKos!.isNotEmpty)
              Hero(
                tag: 'kosImage_${kos.id}',
                child: Image.network(
                  kos.fotoKos!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.apartment, size: 100, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kos.namaKos,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${kos.hargaPerbulan.toStringAsFixed(0)} / ${kos.mataUangYangDipakai} per bulan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (kos.hargaDp != null && kos.hargaDp! > 0)
                    Text(
                      'DP: Rp ${kos.hargaDp!.toStringAsFixed(0)} ${kos.mataUangYangDipakai}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 12),
                  _buildDetailInfoRow(
                    Icons.location_city_outlined,
                    'Alamat',
                    kos.alamat,
                  ),
                  _buildDetailInfoRow(
                    Icons.description_outlined,
                    'Deskripsi',
                    kos.deskripsi,
                  ),
                  _buildDetailInfoRow(
                    Icons.king_bed_outlined,
                    'Kamar Tersedia',
                    '${kos.jumlahKamarTersedia} kamar',
                  ),
                  if (kos.kontak != null && kos.kontak!.isNotEmpty)
                    _buildDetailInfoRow(
                      Icons.phone_outlined,
                      'Kontak Pemilik',
                      kos.kontak!,
                      isPhone: true,
                      onTap: () => _launchCaller(kos.kontak),
                    ),
                  if (kos.email != null && kos.email!.isNotEmpty)
                    _buildDetailInfoRow(
                      Icons.email_outlined,
                      'Email Pemilik',
                      kos.email!,
                      isEmail: true,
                      onTap: () => _launchEmail(kos.email),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Fasilitas:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (kos.fasilitas.isEmpty)
                    const Text('- Tidak ada data fasilitas -')
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: kos.fasilitas
                          .split(',')
                          .map(
                            (fasilitas) => Chip(
                              label: Text(fasilitas.trim()),
                              backgroundColor: Colors.teal[50],
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    /* ... Tombol Peta & Rute ... */
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Peta & Rute:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (_isFetchingLocation || _isFetchingDirections)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                              tooltip: 'Lokasi Saya',
                            ),
                            IconButton(
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
                  if (_routeDistance != null && _routeDuration != null)
                    Padding(
                      /* ... Info Rute ... */
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
                  SizedBox(
                    height: 300,
                    child: GoogleMap(
                      /* ... Konfigurasi Peta ... */
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: kosLocation,
                        zoom: 15.0,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child:
                        accountProvider
                            .isProcessingBooking // Gunakan state dari AccountProvider
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.payment_outlined),
                            label: const Text('Pesan & Bayar DP (Simulasi)'),
                            onPressed:
                                (kos.hargaDp == null || kos.hargaDp! <= 0)
                                ? null // Disable tombol jika tidak ada DP atau DP <= 0
                                : () => _handleBooking(
                                    kos,
                                    authProvider,
                                    accountProvider,
                                  ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              backgroundColor:
                                  (kos.hargaDp == null || kos.hargaDp! <= 0)
                                  ? Colors.grey
                                  : null, // Warna disabled
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isPhone = false,
    bool isEmail = false,
    VoidCallback? onTap,
  }) {
    Color valueColor = Colors.black87;
    TextDecoration textDecoration = TextDecoration.none;
    if (isPhone || isEmail) {
      valueColor = Colors.blue;
      textDecoration = TextDecoration.underline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ),
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
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: valueColor,
                      decoration: textDecoration,
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

  void _showDeleteKosConfirmationDialog(
    BuildContext context,
    KosProvider provider,
    String kosId,
    String token,
  ) {
    /* Mirip _showDeleteConfirmationDialog di LowonganDetailScreen, tapi panggil provider.deleteKos */
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Kos'),
        content: const Text('Yakin ingin menghapus info kos ini?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authP = Provider.of<AuthProvider>(context, listen: false);
              final success = await provider.deleteKos(
                kosId,
                token,
                authP.userId!,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Info Kos berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Gagal hapus Kos.',
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
