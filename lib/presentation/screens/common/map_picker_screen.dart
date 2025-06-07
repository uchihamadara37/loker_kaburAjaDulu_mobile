import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:loker_kabur_aja_dulu/core/constants/google_constants.dart'; // Pastikan ini ada API Key Anda
import 'package:uuid/uuid.dart'; // Untuk session token

// Model sederhana untuk hasil prediksi Places Autocomplete
class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({required this.placeId, required this.description});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  LatLng _initialCameraPosition = const LatLng(-6.200000, 106.816666); // Default Jakarta

  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _placePredictions = [];
  String? _sessionToken; // Session token untuk Places API
  final Uuid _uuid = const Uuid();
  bool _isSearchingPlaces = false;

  @override
  void initState() {
    super.initState();
    // Buat session token baru setiap kali layar ini dibuat
    _sessionToken = _uuid.v4();

    if (widget.initialPosition != null) {
      _pickedLocation = widget.initialPosition;
      _initialCameraPosition = widget.initialPosition!;
    } else {
      _determineInitialPosition();
    }
  }

  Future<void> _determineInitialPosition() async {
    // ... (Fungsi _determineInitialPosition tetap sama seperti sebelumnya) ...
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { return; }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { return; }
    }
    
    if (permission == LocationPermission.deniedForever) { return; } 

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _initialCameraPosition = LatLng(position.latitude, position.longitude);
        _pickedLocation ??= _initialCameraPosition; 
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialCameraPosition, 15.0));
    } catch(e) {
      print("Error getting current location for map picker: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickedLocation != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_pickedLocation!, 15.0));
    } else {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0));
    }
  }

  void _selectLocationOnMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
      // Kosongkan hasil pencarian dan field search jika lokasi dipilih dari peta
      _searchController.clear();
      _placePredictions = [];
    });
    // Animasikan kamera ke lokasi yang baru dipilih di peta
    // _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }
  
  // --- FUNGSI UNTUK PENCARIAN LOKASI ---
  Future<void> _onSearchChanged(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    if (_sessionToken == null) _sessionToken = _uuid.v4(); // Buat token baru jika belum ada

    setState(() {
      _isSearchingPlaces = true;
    });

    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${google_api_key}&sessiontoken=$_sessionToken"; // Batasi ke Indonesia (opsional)
    
    print("Places Autocomplete URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          setState(() {
            _placePredictions = (result['predictions'] as List)
                .map((p) => PlacePrediction.fromJson(p))
                .toList();
          });
        } else {
          print("Places API Autocomplete Error: ${result['error_message'] ?? result['status']}");
          setState(() { _placePredictions = []; });
        }
      } else {
        print("HTTP Error Places Autocomplete: ${response.statusCode}");
        setState(() { _placePredictions = []; });
      }
    } catch (e) {
      print("Error searching places: $e");
      setState(() { _placePredictions = []; });
    } finally {
       setState(() {
        _isSearchingPlaces = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    // Setelah mendapatkan detail, session token ini selesai dan harus dibuat baru untuk autocomplete berikutnya
    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,name,formatted_address&key=${google_api_key}&sessiontoken=$_sessionToken";
    
    print("Places Details URL: $url");
    
    setState(() { _isSearchingPlaces = true; }); // Gunakan flag yang sama untuk loading

    try {
      final response = await http.get(Uri.parse(url));
      // Buat session token baru untuk set pencarian berikutnya
      _sessionToken = _uuid.v4(); 

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final placeDetails = result['result'];
          if (placeDetails != null && placeDetails['geometry'] != null) {
            final location = placeDetails['geometry']['location'];
            final newPickedLocation = LatLng(location['lat'], location['lng']);
            setState(() {
              _pickedLocation = newPickedLocation;
              _searchController.text = placeDetails['name'] ?? placeDetails['formatted_address'] ?? _searchController.text;
              _placePredictions = []; // Bersihkan prediksi
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(newPickedLocation, 16.0), // Zoom lebih dekat
            );
          }
        } else {
          print("Places API Details Error: ${result['error_message'] ?? result['status']}");
        }
      } else {
         print("HTTP Error Places Details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getting place details: $e");
    } finally {
      setState(() { _isSearchingPlaces = false; });
    }
  }
  // --- AKHIR FUNGSI PENCARIAN ---


  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_pickedLocation);
              },
            ),
        ],
      ),
      body: Column( // Ubah Stack menjadi Column untuk menempatkan TextField di atas peta
        children: [
          // --- BAGIAN INPUT PENCARIAN ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari alamat atau nama tempat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _placePredictions = []; });
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // --- DAFTAR HASIL PREDIKSI ---
          if (_isSearchingPlaces && _placePredictions.isEmpty) // Tampilkan loading jika sedang mencari dan belum ada hasil
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 10.0),
               child: Center(child: CircularProgressIndicator(strokeWidth: 2,)),
             ),
          if (_placePredictions.isNotEmpty)
            Expanded( // Expanded agar ListView bisa mengambil sisa ruang di Column sementara
              flex: 0, // Atur flex agar tidak terlalu mendominasi jika hasil sedikit
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3), // Batasi tinggi list
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _placePredictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_pin),
                      title: Text(prediction.description),
                      onTap: () {
                        _getPlaceDetails(prediction.placeId);
                      },
                    );
                  },
                ),
              ),
            ),
          // --- PETA ---
          Expanded( // Peta mengambil sisa ruang yang tersedia
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialCameraPosition,
                    zoom: 14.0,
                  ),
                  onTap: _selectLocationOnMapTap, // Menggunakan fungsi baru
                  markers: _pickedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('pickedLocation'),
                            position: _pickedLocation!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              _selectLocationOnMapTap(newPosition); // Update saat drag
                            },
                          ),
                        },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true, // Aktifkan tombol zoom bawaan peta
                ),
                if (_pickedLocation == null && !_isSearchingPlaces && _placePredictions.isEmpty) // Tampilkan pesan jika belum ada lokasi dan tidak sedang mencari
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Ketuk pada peta untuk memilih lokasi\natau cari alamat di atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(backgroundColor: Colors.black54, color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Tombol konfirmasi tetap di bawah
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Lokasi Terpilih'),
              onPressed: _pickedLocation == null ? null : () {
                Navigator.of(context).pop(_pickedLocation);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Lebar penuh
              ),
            ),
          )
        ],
      ),
    );
  }
}