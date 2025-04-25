class CheckModel {
  final int? id;
  final int userId;
  final String? checkIn;
  final String? checkInLocation;
  final String? checkInAddress;
  final String? checkOut;
  final String? checkOutLocation;
  final String? checkOutAddress;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;

  CheckModel({
    this.id,
    required this.userId,
    this.checkIn,
    this.checkInLocation,
    this.checkInAddress,
    this.checkOut,
    this.checkOutLocation,
    this.checkOutAddress,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'check_in': checkIn,
      'check_in_location': checkInLocation,
      'check_in_address': checkInAddress,
      'check_out': checkOut,
      'check_out_location': checkOutLocation,
      'check_out_address': checkOutAddress,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
    };
  }

  factory CheckModel.fromMap(Map<String, dynamic> map) {
    return CheckModel(
      id: map['id'],
      userId: map['user_id'],
      checkIn: map['check_in'],
      checkInLocation: map['check_in_location'],
      checkInAddress: map['check_in_address'],
      checkOut: map['check_out'],
      checkOutLocation: map['check_out_location'],
      checkOutAddress: map['check_out_address'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      checkInLat: map['check_in_lat']?.toDouble(),
      checkInLng: map['check_in_lng']?.toDouble(),
      checkOutLat: map['check_out_lat']?.toDouble(),
      checkOutLng: map['check_out_lng']?.toDouble(),
    );
  }
}
