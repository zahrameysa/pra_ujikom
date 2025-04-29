import 'package:flutter/material.dart';
import 'package:pra_ujikom/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final dbHelper = DatabaseHelper();
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _nameController.addListener(
      () => setState(() {}),
    ); // update tombol Save aktif
  }

  // 🔥 Fungsi untuk mengambil data user yang sedang login
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('idUser'); // id disimpan saat login

    if (userId != null) {
      final user = await dbHelper.getUserById(userId);
      if (user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name; // isi otomatis name
          _emailController.text = user.email; // isi otomatis email
          _isLoading = false;
        });
      }
    } else {
      // Kalau tidak ada id user di SharedPrefs
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔥 Fungsi untuk update nama di SQLite + SharedPreferences
  Future<void> _updateProfile() async {
    if (_user == null) return;
    final newName = _nameController.text.trim();

    if (newName.isNotEmpty) {
      final updatedUser = UserModel(
        id: _user!.id,
        name: newName,
        email: _user!.email,
        password: _user!.password,
      );

      await dbHelper.updateUser(updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', newName); // Update SharedPrefs

      setState(() {
        _user = updatedUser;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context); // kembali ke dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B66),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔥 Bagian atas - foto profile
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D3B66),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: const AssetImage(
                              'assets/images/profile.png',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🔥 Bagian form edit
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            readOnly: true, // 🔥 Email tidak boleh diedit
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 🔥 Tombol Save
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isNameFilled ? _updateProfile : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D3B66),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 🔥 Validasi apakah nama sudah diisi
  bool get _isNameFilled => _nameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
