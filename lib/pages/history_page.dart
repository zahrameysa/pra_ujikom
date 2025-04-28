import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pra_ujikom/db/database_helper.dart';
import 'package:pra_ujikom/models/check_model.dart';
import 'package:pra_ujikom/services/shared_pref_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DatabaseHelper _dbHelper;
  List<CheckModel> _historyList = [];
  int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadUserAndHistory();
  }

  Future<void> _loadUserAndHistory() async {
    final prefs = await SharedPrefService.getInstance();
    final userId = prefs.getUserId();

    if (userId != null) {
      final history = await _dbHelper.getChecksByUserId(userId.toString());
      setState(() {
        _userId = userId;
        _historyList = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHistory(int id) async {
    await _dbHelper.deleteCheckById(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil dihapus.'),
        backgroundColor: Colors.red,
      ),
    );
    _loadUserAndHistory(); // refresh list
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    final date = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    final time = DateTime.parse(dateTime);
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D3B66),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _historyList.isEmpty
              ? const Center(child: Text('Belum ada data absensi.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  final check = _historyList[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        _formatDate(check.checkIn),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(check.id!);
                        },
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.login,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "In: ${_formatTime(check.checkIn)}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.logout,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Out: ${_formatTime(check.checkOut)}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  check.checkInAddress ?? '-',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteHistory(id);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
