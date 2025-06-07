import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_dipesan_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/google_constants.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/common/map_picker_screen.dart'
    show PlacePrediction;
import 'package:intl/intl.dart'; // Pastikan import ini ada
import 'package:timezone/timezone.dart' as tz;

class FullMapBookedKosScreen extends StatefulWidget {
  final List<KosDipesanModel> bookedKosList;

  const FullMapBookedKosScreen({super.key, required this.bookedKosList});

  @override
  State<FullMapBookedKosScreen> createState() => _FullMapBookedKosScreenState();
}

class _FullMapBookedKosScreenState extends State<FullMapBookedKosScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  Position? _currentDevicePosition;
  bool _isFetchingDeviceLocation = false;

  MapType _currentMapType = MapType.normal;

  final TextEditingController _searchMapController = TextEditingController();
  List<PlacePrediction> _mapPlacePredictions = [];
  String? _mapSearchSessionToken;
  final Uuid _uuid = const Uuid();
  bool _isSearchingMapPlaces = false;
  LatLng? _searchedLocationLatLng;

  // KosDipesanModel? _selectedKosForRoute; // Akan kita generalisir
  // --- PENAMBAHAN/MODIFIKASI STATE UNTUK RUTE DINAMIS ---
  LatLng? _routeDestinationLatLng; // Menyimpan LatLng tujuan rute saat ini
  String _routeDestinationName = "Tujuan"; // Nama tujuan untuk ditampilkan

  bool _isFetchingMapDirections = false;
  String? _mapRouteDistance;
  String? _mapRouteDuration;

  Timer? _clockTimer;
  Timer? _debounceTimer; // Untuk menunda panggilan API timezone
  DateTime _currentTime = DateTime.now();
  String? _mapCenterTimezoneName;
  int? _mapCenterTimezoneOffsetInSeconds;
  bool _isFetchingTimezone = false;

  // --- PENAMBAHAN: State untuk marker titik yang diketuk pengguna ---
  LatLng? _tappedPointLatLng;
  static const String _tappedPointMarkerId = 'tappedPointLocation';

  bool _isGyroCameraActive = false;
  StreamSubscription? _gyroscopeSubscription;
  LatLng? _currentMapCenter; // Untuk menyimpan pusat peta saat ini
  static const double GYRO_SENSITIVITY =
      5; // Sensitivitas pergerakan peta berdasarkan gyro
  static const double GYRO_THRESHOLD =
      0.3; // Ambang batas gyro untuk mulai bergerak (rad/s)

  // --- PENAMBAHAN: Listener untuk pergerakan kamera peta ---
  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      _getTimezoneForCoordinates(position.target);
    });
  }

  // --- PENAMBAHAN: FUNGSI UNTUK GYRO CAMERA ---
  void _toggleGyroCamera() {
    setState(() {
      // _mapController!.moveCamera(CameraUpdate.newLatLng(LatLng(100, 100)));

      _isGyroCameraActive = !_isGyroCameraActive;
      if (_isGyroCameraActive) {
        _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
          if (!_isGyroCameraActive ||
              _mapController == null ||
              _currentMapCenter == null) {
            return;
          }

          // event.x: rotasi pitch (depan/belakang)
          // event.y: rotasi roll (kiri/kanan)
          // event.z: rotasi yaw (putar) - bisa untuk bearing peta

          print("event gyro : ${event}");
          double dx = 0; // Perubahan longitude
          double dy = 0; // Perubahan latitude

          // Mapping kasar: Roll ke Longitude, Pitch ke Latitude
          // Perlu penyesuaian tanda tergantung orientasi alami perangkat dan keinginan
          // if (event.y.abs() > GYRO_THRESHOLD) {
          //   // Roll (kiri/kanan)
          //   dx =
          //       -event.y *
          //       GYRO_SENSITIVITY; // Tanda minus mungkin perlu disesuaikan
          // }
          // if (event.x.abs() > GYRO_THRESHOLD) {
          //   // Pitch (depan/belakang)
          //   dy =
          //       event.x *
          //       GYRO_SENSITIVITY; // Tanda minus mungkin perlu disesuaikan
          // }

          dx = -event.y * GYRO_SENSITIVITY;
          dy = event.x * GYRO_SENSITIVITY;

          if (dx != 0 || dy != 0) {
            print("currentMapCenter: ${_currentMapCenter}");
            print("peta harusnya gerak ${dx} ${dy}");
            LatLng newTarget = LatLng(
              (_currentMapCenter!.latitude + dy).clamp(
                -90.0,
                90.0,
              ), // Batasi latitude
              _currentMapCenter!.longitude + dx, // Longitude akan wrap around
            );
            // Update _currentMapCenter agar pergerakan berikutnya relatif terhadap posisi baru
            print("target ${newTarget}");
            _currentMapCenter = newTarget;
            if (_mapController != null) {
              print("jangkrik moveCamera");
              _mapController!.moveCamera(CameraUpdate.newLatLng(newTarget));
            } else {
              print("jangkrik");
            }
            // Tidak perlu setState() di sini karena moveCamera sudah update UI peta
            // Kecuali ada widget lain yang bergantung pada _currentMapCenter.
          }
        });
      } else {
        _gyroscopeSubscription?.cancel();
        _gyroscopeSubscription = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _mapSearchSessionToken = _uuid.v4();
    _prepareMarkers(); // Dipanggil setelah _getCurrentDeviceLocation atau jika _currentDevicePosition sudah ada
    _getCurrentDeviceLocation(moveToLocation: widget.bookedKosList.isEmpty);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  // --- PENAMBAHAN: Fungsi untuk mengambil Timezone dari API ---
  Future<void> _getTimezoneForCoordinates(LatLng coordinates) async {
    if (!mounted) return;
    setState(() {
      _isFetchingTimezone = true;
    });

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final url =
        "https://maps.googleapis.com/maps/api/timezone/json?location=${coordinates.latitude},${coordinates.longitude}&timestamp=$timestamp&key=${google_api_key}";

    try {
      print("url timezone : $url");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Timezone mase: ${data}");
        if (data['status'] == 'OK') {
          if (mounted) {
            setState(() {
              _mapCenterTimezoneName = data['timeZoneId'];
              final int rawOffset = data['rawOffset'] ?? 0;
              final int dstOffset = data['dstOffset'] ?? 0;
              _mapCenterTimezoneOffsetInSeconds = rawOffset + dstOffset;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _mapCenterTimezoneName =
                  'Pastikan tengah map itu daratan!';
            });
          }
          print(
            "Timezone API Error: ${data['errorMessage'] ?? data['status']}",
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _mapCenterTimezoneName = 'API Error';
          });
        }
        print("HTTP Error fetching timezone: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mapCenterTimezoneName = 'Network Error';
        });
      }
      print("Error fetching timezone: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingTimezone = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    final initialTarget =
        widget.bookedKosList.isNotEmpty &&
            widget.bookedKosList.first.latitude != null
        ? LatLng(
            widget.bookedKosList.first.latitude!,
            widget.bookedKosList.first.longitude!,
          )
        : (_currentDevicePosition != null
              ? LatLng(
                  _currentDevicePosition!.latitude,
                  _currentDevicePosition!.longitude,
                )
              : const LatLng(-6.200000, 106.816666));

    _currentMapCenter = initialTarget;
    _getTimezoneForCoordinates(initialTarget);

    _prepareMarkers(); // Panggil di sini setelah map siap dan _currentDevicePosition mungkin sudah ada
    if (widget.bookedKosList.isNotEmpty && _mapController != null) {
      _fitAllBookedKosMarkers();

      // _mapController!.animateCamera(
      //   CameraUpdate.newLatLngZoom(
      //     LatLng(
      //       _currentDevicePosition!.latitude,
      //       _currentDevicePosition!.longitude,
      //     ),
      //     14,
      //   ),
      // );
    } else if (_currentDevicePosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _currentDevicePosition!.latitude,
            _currentDevicePosition!.longitude,
          ),
          14,
        ),
      );
    }
  }

  void _prepareMarkers() {
    Set<Marker> tempMarkers = {};
    // 1. Marker Kos Dipesan
    for (var kos in widget.bookedKosList) {
      if (kos.latitude != null && kos.longitude != null) {
        tempMarkers.add(
          Marker(
            markerId: MarkerId('bookedKos_${kos.kosId}'),
            position: LatLng(kos.latitude!, kos.longitude!),
            infoWindow: InfoWindow(
              title: kos.namaKos ?? 'Kos Dipesan',
              snippet: 'Tap untuk rute ke ${kos.namaKos ?? "sini"}',
              onTap: () {
                setState(() {
                  // _selectedKosForRoute = kos; // Tidak digunakan lagi secara langsung
                  _routeDestinationLatLng = LatLng(
                    kos.latitude!,
                    kos.longitude!,
                  );
                  _routeDestinationName = kos.namaKos ?? 'Kos Dipesan';
                });
                _getMapDirections();
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ), // Warna berbeda untuk kos dipesan
          ),
        );
      }
    }
    // 2. Marker Lokasi Perangkat Saat Ini
    if (_currentDevicePosition != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId('currentDeviceLocation'),
          position: LatLng(
            _currentDevicePosition!.latitude,
            _currentDevicePosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Lokasi Saya Saat Ini'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ), // Warna beda
        ),
      );
    }
    // 3. Marker Lokasi Hasil Pencarian (jika ada)
    if (_searchedLocationLatLng != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId('searchedLocation'),
          position: _searchedLocationLatLng!,
          infoWindow: InfoWindow(
            title: _searchMapController.text.isNotEmpty
                ? _searchMapController.text
                : 'Lokasi Dicari',
            snippet: 'Tap untuk rute ke sini',
            onTap: () {
              setState(() {
                _routeDestinationLatLng = _searchedLocationLatLng;
                _routeDestinationName = _searchMapController.text.isNotEmpty
                    ? _searchMapController.text
                    : 'Lokasi Dicari';
              });
              _getMapDirections();
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ), // Warna beda
        ),
      );
    }
    // --- PENAMBAHAN: 4. Marker untuk Titik yang Diketuk Pengguna ---
    if (_tappedPointLatLng != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId(_tappedPointMarkerId), // Gunakan ID statis
          position: _tappedPointLatLng!,
          infoWindow: InfoWindow(
            title: 'Titik Dipilih',
            snippet: 'Tap untuk rute ke sini',
            onTap: () {
              setState(() {
                _routeDestinationLatLng = _tappedPointLatLng;
                _routeDestinationName = 'Titik Dipilih';
              });
              _getMapDirections();
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = tempMarkers;
      });
    }
  }

  void _fitAllBookedKosMarkers() {
    if (_mapController == null) return;

    List<LatLng> points = [];
    // Hanya ambil posisi dari marker kos dipesan untuk zoom awal ke area tersebut
    points.addAll(
      widget.bookedKosList
          .where((kos) => kos.latitude != null && kos.longitude != null)
          .map((kos) => LatLng(kos.latitude!, kos.longitude!)),
    );

    if (points.isEmpty) {
      if (_currentDevicePosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              _currentDevicePosition!.latitude,
              _currentDevicePosition!.longitude,
            ),
            12,
          ),
        );
      } else {
        // print("list kos tidak kosong");
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(const LatLng(-6.200000, 106.816666), 10),
        );
      }
      return;
    }
    if (points.length == 1) {
      print("list kos tidak kosong, ada 1");
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }
    double minLat = points.first.latitude,
        maxLat = points.first.latitude,
        minLng = points.first.longitude,
        maxLng = points.first.longitude;
    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    print("ealah jabang");
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        5.0,
      ),
    );
  }

  Future<void> _getCurrentDeviceLocation({bool moveToLocation = false}) async {
    setState(() {
      _isFetchingDeviceLocation = true;
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
        _isFetchingDeviceLocation = false;
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
          _isFetchingDeviceLocation = false;
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
        _isFetchingDeviceLocation = false;
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentDevicePosition = position;
      });
      _prepareMarkers();
      if (moveToLocation && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            8.0,
          ),
        );
      }
    } catch (e) {
      print("Error get current device location for map: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDeviceLocation = false;
        });
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  Future<void> _onMapSearchChanged(String input) async {
    if (input.trim().isEmpty) {
      setState(() {
        _mapPlacePredictions = [];
      });
      return;
    }
    _mapSearchSessionToken ??= _uuid.v4();
    setState(() {
      _isSearchingMapPlaces = true;
    });
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input.trim())}&key=${google_api_key}&sessiontoken=$_mapSearchSessionToken";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          if (mounted) {
            setState(() {
              _mapPlacePredictions = (result['predictions'] as List)
                  .map((p) => PlacePrediction.fromJson(p))
                  .toList();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _mapPlacePredictions = [];
            });
          }
          print(
            "Places API Autocomplete Error: ${result['error_message'] ?? result['status']}",
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _mapPlacePredictions = [];
          });
        }
        print("HTTP Error Places Autocomplete: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mapPlacePredictions = [];
        });
      }
      print("Error searching places: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingMapPlaces = false;
        });
      }
    }
  }

  Future<void> _getSearchedPlaceDetails(String placeId) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,name,formatted_address&key=${google_api_key}&sessiontoken=$_mapSearchSessionToken";
    _mapSearchSessionToken = _uuid.v4();
    setState(() {
      _isSearchingMapPlaces = true;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final placeDetails = result['result'];
          if (placeDetails != null && placeDetails['geometry'] != null) {
            final location = placeDetails['geometry']['location'];
            final newSearchedLocation = LatLng(
              location['lat'],
              location['lng'],
            );
            setState(() {
              _searchedLocationLatLng = newSearchedLocation;
              // Hapus marker tapped point jika ada, karena sekarang fokus ke hasil search
              _tappedPointLatLng = null;
              _searchMapController.text =
                  placeDetails['formatted_address'] ??
                  placeDetails['name'] ??
                  _searchMapController.text;
              _mapPlacePredictions = [];
            });
            _prepareMarkers();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(newSearchedLocation, 16.0),
            );
          }
        } else {
          print(
            "Places API Details Error: ${result['error_message'] ?? result['status']}",
          );
        }
      } else {
        print("HTTP Error Places Details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error get searched place details: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingMapPlaces = false;
        });
      }
    }
  }

  // --- FUNGSI RUTE DI PETA UMUM (MENGGUNAKAN _routeDestinationLatLng) ---
  Future<void> _getMapDirections() async {
    if (_currentDevicePosition == null || _routeDestinationLatLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi Anda atau tujuan rute belum ditentukan.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _isFetchingMapDirections = true;
      _polylines.clear();
      _mapRouteDistance = null;
      _mapRouteDuration = null;
    });

    PolylinePoints polylinePoints = PolylinePoints();
    PointLatLng origin = PointLatLng(
      _currentDevicePosition!.latitude,
      _currentDevicePosition!.longitude,
    );
    PointLatLng destination = PointLatLng(
      _routeDestinationLatLng!.latitude,
      _routeDestinationLatLng!.longitude,
    );

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
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
          String distance = data['routes'][0]['legs'][0]['distance']['text'];
          String duration = data['routes'][0]['legs'][0]['duration']['text'];
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('mapRouteToDestination'),
                points: polylineCoordinates,
                color: Colors.blueAccent.withOpacity(0.9),
                width: 7,
              ),
            );
            _mapRouteDistance = distance;
            _mapRouteDuration = duration;
            if (_mapController != null && polylineCoordinates.isNotEmpty) {
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
                  'Rute Error: ${data['error_message'] ?? data['status']}',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal hubungi layanan rute peta.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ambil rute peta: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMapDirections = false;
        });
      }
    }
  }

  // --- PENAMBAHAN: Fungsi untuk menangani tap di peta ---
  void _onMapTap(LatLng tappedPoint) {
    setState(() {
      _tappedPointLatLng = tappedPoint;
      // Saat peta di-tap, kita set tapped point sebagai tujuan rute potensial berikutnya
      // _routeDestinationLatLng = tappedPoint; // Komentari ini jika ingin InfoWindow yang trigger
      // _routeDestinationName = "Titik Dipilih";

      // Bersihkan rute dan info rute sebelumnya jika ada, karena tujuan mungkin berubah
      _polylines.clear();
      _mapRouteDistance = null;
      _mapRouteDuration = null;
    });
    _prepareMarkers(); // Panggil untuk menambahkan/memperbarui marker di _tappedPointLatLng
    // Ini akan menampilkan marker baru, InfoWindow-nya yang akan memicu rute.
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchMapController.dispose();
    _gyroscopeSubscription?.cancel(); // --- PENAMBAHAN: Batalkan langganan ---
    _clockTimer?.cancel(); // --- PENAMBAHAN: Batalkan timer jam
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kos Dipesan', style: TextStyle(fontSize: 18),),
        actions: [
          IconButton(
            icon: Icon(
              _isGyroCameraActive ? Icons.explore : Icons.explore_off_outlined,
              color: _isGyroCameraActive
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            ),
            tooltip: _isGyroCameraActive
                ? 'Matikan Gyro Camera'
                : 'Aktifkan Gyro Camera',
            onPressed: _toggleGyroCamera,
          ),
          IconButton(
            icon: Icon(
              _currentMapType == MapType.normal
                  ? Icons.satellite_alt
                  : Icons.map_outlined,
            ),
            tooltip: 'Ganti Tipe Peta',
            onPressed: _toggleMapType,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lokasi Saya Saat Ini',
            onPressed: () => _getCurrentDeviceLocation(moveToLocation: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchMapController,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat atau nama tempat...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchMapController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchMapController.clear();
                                setState(() {
                                  _mapPlacePredictions = [];
                                  _searchedLocationLatLng = null;
                                  _tappedPointLatLng = null;
                                  _prepareMarkers();
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                    ),
                    onChanged: _onMapSearchChanged,
                  ),
                  if (_isSearchingMapPlaces && _mapPlacePredictions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  if (_mapPlacePredictions.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.25,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mapPlacePredictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _mapPlacePredictions[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.pin_drop_outlined,
                              color: Colors.grey,
                            ),
                            title: Text(prediction.description),
                            dense: true,
                            onTap: () =>
                                _getSearchedPlaceDetails(prediction.placeId),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTimeDisplay(tz.UTC),
                _buildMapCenterTimezoneDisplay(),
                _buildTimeDisplay(tz.local),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target:
                        widget.bookedKosList.isNotEmpty &&
                            widget.bookedKosList.first.latitude != null
                        ? LatLng(
                            widget.bookedKosList.first.latitude!,
                            widget.bookedKosList.first.longitude!,
                          )
                        : (_currentDevicePosition != null
                              ? LatLng(
                                  _currentDevicePosition!.latitude,
                                  _currentDevicePosition!.longitude,
                                )
                              : const LatLng(-6.200000, 106.816666)),
                    zoom: 12,
                  ),
                  mapType: _currentMapType,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  onTap: _onMapTap, // --- PENAMBAHAN HANDLE TAP ---
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
                if (_isFetchingMapDirections)
                  const Center(child: CircularProgressIndicator()),
                if (_mapRouteDistance != null && _mapRouteDuration != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Rute ke $_routeDestinationName: Jarak $_mapRouteDistance, Waktu $_mapRouteDuration',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
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

  // @override
  // void dispose() {
  //   _mapController?.dispose();
  //   _searchMapController.dispose();
  //   super.dispose();
  // }

  // --- PENAMBAHAN: HELPER WIDGET UNTUK TAMPILAN WAKTU ---
  Widget _buildTimeDisplay(tz.Location location) {
    final nowInLocation = tz.TZDateTime.now(location);
    final timeFormat = DateFormat('HH:mm'); // Format jam dan menit

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeFormat.format(nowInLocation),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          location.name, // Nama timezone (misal: UTC atau Asia/Jakarta)
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMapCenterTimezoneDisplay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFetchingTimezone)
          // Tampilkan loading jika sedang fetch
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
        // Tampilkan ikon jika tidak sedang fetch
        // const SizedBox(height: 2),
        // Icon(Icons.public, color: Theme.of(context).primaryColor, size: 20),
        // Jika offset sudah ada, hitung dan tampilkan jamnya
        if (_mapCenterTimezoneOffsetInSeconds != null && !_isFetchingTimezone)
          Column(
            children: [
              Text(
                // Hitung waktu saat ini di timezone tersebut dari UTC + offset
                "${DateFormat('HH:mm').format(DateTime.now().toUtc().add(Duration(seconds: _mapCenterTimezoneOffsetInSeconds!)))} ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                _mapCenterTimezoneName ?? 'Unknown Zone',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
        else if (!_isFetchingTimezone)
          // Tampilkan teks default jika tidak ada data/error
          Text(
            _mapCenterTimezoneName ??
                'Geser Peta...', // Tampilkan 'Unknown' atau 'API Error' jika ada
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
