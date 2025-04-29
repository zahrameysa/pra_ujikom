import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pra_ujikom/db/database_helper.dart';
import 'package:pra_ujikom/models/check_model.dart';
import 'package:pra_ujikom/models/user_model.dart';
import 'package:pra_ujikom/services/shared_pref_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import 'history_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String formattedTime = '';
  String formattedDate = '';
  Position? currentPosition;
  String currentAddress = '';
  int _selectedIndex = 0;
  String _userName = '';
  late UserModel currentUser;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _loadUserData();
    initializeDateFormatting('id_ID', null).then((_) => _getCurrentTime());
    _getCurrentLocation();
  }

  Future<UserModel> _loadUserData() async {
    // Get preference handler instance
    final prefs = await SharedPrefService.getInstance();

    final fetchedName = prefs.getName();
    final fetchedId = prefs.getUserId();
    final fetchedEmail = prefs.getEmail();

    // Buat dan return objek UserModel
    return UserModel(id: fetchedId, name: fetchedName!, email: fetchedEmail!);
  }

  void _getCurrentTime() {
    final now = DateTime.now();
    formattedTime = DateFormat('hh:mm a').format(now);
    formattedDate = DateFormat('EEE, dd MMMM yyyy', 'id_ID').format(now);
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;
    currentAddress =
        "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}";

    setState(() {
      currentPosition = position;
    });
  }

  void _navigateToRequest(String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Open $type request form')));
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) {
        _loadUserData();
        setState(() => _selectedIndex = 0);
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> handleCheckIn(BuildContext context, int userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Cek apakah user sudah check-in hari ini
      final existingCheckIn = await dbHelper.getTodayCheckIn(userId, today);
      if (existingCheckIn != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan check-in hari ini'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 1. Minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen')),
        );
        return;
      }

      // 2. Ambil posisi sekarang
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lng = position.longitude;

      // 3. Konversi jadi alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      String address =
          "${placemarks.first.street}, ${placemarks.first.locality}";
      String location =
          placemarks.first.subAdministrativeArea ?? "Tidak diketahui";

      // 4. Format waktu
      final now = DateTime.now();
      final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // 5. Buat model dan simpan ke DB
      final checkModel = CheckModel(
        userId: userId,
        checkIn: formattedNow,
        checkInLocation: location,
        checkInAddress: address,
        createdAt: formattedNow,
        updatedAt: formattedNow,
        checkInLat: lat,
        checkInLng: lng,
      );
      final result = await dbHelper.insertCheckIn(checkModel);

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-In berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan Check-In'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleCheckOut(BuildContext context, int userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final checkInRecord = await dbHelper.getTodayCheckIn(userId, today);

      if (checkInRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda belum melakukan check-in hari ini'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (checkInRecord.checkOut != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan check-out'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ambil lokasi saat check-out
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lng = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      String address =
          "${placemarks.first.street}, ${placemarks.first.locality}";
      String location =
          placemarks.first.subAdministrativeArea ?? "Tidak diketahui";

      final now = DateTime.now();
      final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // Update data check-out lengkap (waktu, lokasi, lat, lng)
      final db = await dbHelper.database;
      await db.update(
        'check_model',
        {
          'check_out': formattedNow,
          'check_out_location': location,
          'check_out_address': address,
          'check_out_lat': lat,
          'check_out_lng': lng,
          'updated_at': formattedNow,
        },
        where: 'id = ?',
        whereArgs: [checkInRecord.id],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat check-out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_dashboard.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(
                            'assets/images/profile.png',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Mobile Developer',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.logout, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Live Attendance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A72C1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(formattedDate),
                        const Divider(height: 24),
                        const Text(
                          'Office Hours',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '08:00 AM - 05:00 PM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  currentUser = await _loadUserData();
                                  //ini buat funsgi db insert checkin
                                  // notes:
                                  // - ambil userid dari shared_pref
                                  // - location dll dari maps
                                  handleCheckIn(context, currentUser.id!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D3B66),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Check In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  currentUser = await _loadUserData();
                                  handleCheckOut(context, currentUser.id!);
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D3B66),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Check Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (currentPosition != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Anda Saat Ini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    currentPosition!.latitude,
                                    currentPosition!.longitude,
                                  ),
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId(
                                      'current_location',
                                    ),
                                    position: LatLng(
                                      currentPosition!.latitude,
                                      currentPosition!.longitude,
                                    ),
                                  ),
                                },
                                myLocationEnabled: true,
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                onMapCreated: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: const Color(0xFF0D3B66),
        unselectedItemColor: Colors.black45,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'History',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _requestItem(String title, String imagePath) {
    return InkWell(
      onTap: () => _navigateToRequest(title),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(imagePath, width: 40, height: 40),
          ),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}
