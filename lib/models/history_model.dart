class HistoryModel {
  final int? id;
  final int userId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String location;

  HistoryModel({
    this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'check_in': checkIn ?? '',
      'check_out': checkOut ?? '',
      'location': location,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      checkIn:
          map['check_in'] != null && map['check_in'] != ''
              ? map['check_in']
              : null,
      checkOut:
          map['check_out'] != null && map['check_out'] != ''
              ? map['check_out']
              : null,
      location: map['location'],
    );
  }
}
