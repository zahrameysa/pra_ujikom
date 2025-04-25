import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static SharedPrefService? _instance;
  late SharedPreferences _prefs;

  static const String _id = 'idUser';
  static const String _name = 'name';
  static const String _email = 'email';

  SharedPrefService._();

  static Future<SharedPrefService> getInstance() async {
    if (_instance == null) {
      _instance = SharedPrefService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveUser({
    required int id,
    required String name,
    required String email,
  }) async {
    await _prefs.setInt(_id, id);
    await _prefs.setString(_name, name);
    await _prefs.setString(_email, email);
  }

  int? getUserId() {
    return _prefs.getInt(_id);
  }

  String? getName() {
    return _prefs.getString(_name);
  }

  String? getEmail() {
    return _prefs.getString(_email);
  }
}
