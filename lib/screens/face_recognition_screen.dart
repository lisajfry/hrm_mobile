import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hrm/api/absensi_service.dart'; // Sesuaikan dengan path yang sesuai
import 'package:image_picker/image_picker.dart';


class FaceRecognitionScreen extends StatefulWidget {
  final String action;
  final String time;
  final String date;

  const FaceRecognitionScreen({
    Key? key,
    required this.action,
    required this.time,
    required this.date,
  }) : super(key: key);

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  late GoogleMapController mapController;
  LatLng _initialPosition = LatLng(-6.200000, 106.816666);
  LatLng? _currentPosition;
  LatLng _officeLocation = LatLng(-7.636785618907347, 111.54259407880777); // Lokasi kantor default
  double _radius = 400.0;
  StreamSubscription<Position>? _positionStream;
 bool _isLoading = false; // Variabel untuk menandakan status loading
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _startLocationUpdates();
    _initializeCamera();
    _fetchOfficeLocation(); // Panggil untuk mendapatkan lokasi kantor dari API
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

 
  // Fungsi untuk mengambil lokasi kantor
  Future<void> _fetchOfficeLocation() async {
    setState(() {
      _isLoading = true; // Mulai loading
    });
    try {
      AbsensiService absensiService = AbsensiService();
      LatLng officeLocation = await absensiService.getOfficeLocation();
      setState(() {
        _officeLocation = officeLocation;
         _isLoading = false; // Selesai loading
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Selesai loading meskipun gagal
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi kantor: $e')),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _initialPosition = _currentPosition!;
        mapController.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final XFile photo = await _cameraController.takePicture();
      setState(() {
        _capturedImage = photo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto berhasil diambil')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto')),
      );
    }
  }

  Future<void> handleAbsenMasuk() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
    );
    return;
  }

  final bool confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Absensi akan disimpan. Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Batal
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Ok
            child: Text('Ok'),
          ),
        ],
      );
    },
  );

  if (!confirm) {
    return; // Batalkan proses absensi
  }

  final DateTime now = DateTime.now();
  final String formattedTime = DateFormat('HH:mm:ss').format(now);
  final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
    );
    return;
  }

  double distance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    _officeLocation.latitude,
    _officeLocation.longitude,
  );

  if (distance > _radius) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Anda berada di luar jangkauan kantor. Absensi gagal.')),
    );
    return;
  }

  if (_capturedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Foto tidak tersedia. Ambil foto terlebih dahulu.')),
    );
    return;
  }

  final Map<String, dynamic> absensiData = {
    'tanggal': formattedDate,
    'jam_masuk': formattedTime,
    'foto_masuk': await getFileAsBase64(_capturedImage?.path),
    'latitude_masuk': position.latitude,
    'longitude_masuk': position.longitude,
  };

  // Tampilkan indikator proses
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    final absensiService = AbsensiService();
    final absensi = await absensiService.absenMasuk(absensiData);

    Navigator.of(context).pop(); // Tutup dialog loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Absensi berhasil dicatat: ${absensi.tanggal}')),
    );

    Navigator.pop(context, true); // Mengirim flag bahwa data diperbarui


  } catch (e) {
    Navigator.of(context).pop(); // Tutup dialog loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mencatat absensi: $e')),
    );
  }
}



  Future<void> handleAbsenKeluar() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
    );
    return;
  }

  final bool confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Anda akan mencatat absensi keluar. Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Batal
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Ok
            child: Text('Ok'),
          ),
        ],
      );
    },
  );

  if (!confirm) {
    return; // Batalkan proses absensi keluar
  }

  final DateTime now = DateTime.now();
  final String formattedTime = DateFormat('HH:mm:ss').format(now);
  final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
    );
    return;
  }

  double distance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    _officeLocation.latitude,
    _officeLocation.longitude,
  );

  if (distance > _radius) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Anda berada di luar jangkauan kantor. Absensi keluar gagal.')),
    );
    return;
  }

  if (_capturedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Foto tidak tersedia. Ambil foto terlebih dahulu.')),
    );
    return;
  }

  final Map<String, dynamic> absensiData = {
    'tanggal': formattedDate,
    'jam_keluar': formattedTime,
    'foto_keluar': await getFileAsBase64(_capturedImage?.path),
    'latitude_keluar': position.latitude,
    'longitude_keluar': position.longitude,
  };

  // Tampilkan indikator proses
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    final absensiService = AbsensiService();
    final absensi = await absensiService.absenKeluar(absensiData);

    Navigator.of(context).pop(); // Tutup dialog loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Absensi keluar berhasil dicatat: ${absensi.tanggal}')),
    );

    Navigator.pop(context, true); // Mengirim flag bahwa data diperbarui
  } catch (e) {
    Navigator.of(context).pop(); // Tutup dialog loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mencatat absensi keluar: $e')),
    );
  }
}

  // Widget untuk menampilkan indikator loading
  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SizedBox.shrink(); // Menyembunyikan jika tidak sedang loading
  }

  Future<String?> getFileAsBase64(String? filePath) async {
    if (filePath == null) return null;
    final bytes = await File(filePath).readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catat Kehadiran'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
           Stack(
  children: [
    _buildGoogleMap(), // GoogleMap tetap di bawah
    if (_currentPosition == null) // Menampilkan indikator loading jika posisi belum ditemukan
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // Indikator loading
            SizedBox(height: 10), // Memberikan jarak antara indikator loading dan teks
            Text(
              'Mencari lokasi Anda...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white, // Menyesuaikan warna teks dengan latar belakang
              ),
            ),
          ],
        ),
      ),
  ],
),

            SizedBox(height: 20),
            _buildCameraPreview(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _capturePhoto(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: Colors.orangeAccent,
                  ),
                  child: Text('Ambil Foto'),
                ),
                ElevatedButton(
  onPressed: widget.action == 'Absen Masuk' ? handleAbsenMasuk : handleAbsenKeluar,
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: Colors.blueAccent,
  ),
  child: Text(widget.action),
),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return Container(
      height: 250,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15,
        ),
        markers: _currentPosition != null
            ? {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(title: 'Lokasi Anda'),
                ),
                Marker(
                  markerId: MarkerId('officeLocation'),
                  position: _officeLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(title: 'Kantor'),
                ),
              }
            : {},
        circles: {
          Circle(
            circleId: CircleId("radius"),
            center: _officeLocation,
            radius: _radius,
            fillColor: Colors.blueAccent.withOpacity(0.5),
            strokeColor: Colors.blueAccent,
            strokeWidth: 2,
          ),
        },
      ),
    );
  }


  // Fungsi untuk membangun tombol aksi
Widget buildActionButtons(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.camera);
            if (pickedFile != null) {
              String currentTime = DateFormat('HH:mm').format(DateTime.now());
              String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRecognitionScreen(
                    action: 'Clock In',
                    time: currentTime,
                    date: currentDate,
                  ),
                ),
              );
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Clock In'),
              Icon(Icons.arrow_right),
            ],
          ),
        ),
      ),
      SizedBox(width: 10),
        ],
  );
}
  

  Widget _buildCameraPreview() {
  return Container(
    width: double.infinity,
    height: 300,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(10),
    ),
    child: _capturedImage != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.cover, // Gambar akan sesuai dengan ukuran fitbox
              alignment: Alignment.center,
            ),
          )
        : FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 300, // Ukuran fitbox
                      height: 300, // Ukuran fitbox
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
  );
}
}
