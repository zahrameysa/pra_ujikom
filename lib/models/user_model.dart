class UserModel {
  int? id;
  String name;
  String email;
  String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Konversi dari Map (SQLite) ke objek
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }

  // Konversi objek ke Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
