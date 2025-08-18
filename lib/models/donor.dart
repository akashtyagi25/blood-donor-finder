class Donor {
  final String uid;
  final String name;
  final String email;
  final String bloodGroup;
  final double latitude;
  final double longitude;
  final bool isAvailable;

  Donor({
    required this.uid,
    required this.name,
    required this.email,
    required this.bloodGroup,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'bloodGroup': bloodGroup,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
    };
  }

  factory Donor.fromMap(Map<String, dynamic> map) {
    return Donor(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      bloodGroup: map['bloodGroup'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isAvailable: map['isAvailable'],
    );
  }
}
