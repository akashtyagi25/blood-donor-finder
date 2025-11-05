import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorsMapScreen extends StatefulWidget {
  const DonorsMapScreen({Key? key}) : super(key: key);

  @override
  State<DonorsMapScreen> createState() => _DonorsMapScreenState();
}

class _DonorsMapScreenState extends State<DonorsMapScreen> {
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  List<Marker> _donorMarkers = [];
  List<Marker> _bloodBankMarkers = [];
  String? _userBloodGroup;
  double _searchRadius = 10.0; // km
  bool _showDonors = true;
  bool _showBloodBanks = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      Position position = await _determinePosition();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        _userBloodGroup = doc.data()?['bloodGroup'];
      }

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _loadNearbyDonors();
      _loadBloodBanks();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _loadNearbyDonors() async {
    if (_currentLocation == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .get();

      List<Marker> markers = [];
      final currentUser = FirebaseAuth.instance.currentUser;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (doc.id == currentUser?.uid) continue;

        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final bloodGroup = data['bloodGroup'] as String?;
        final name = data['name'] as String? ?? 'Anonymous';
        final phone = data['phone'] as String? ?? '';

        if (lat != null && lng != null) {
          final donorLocation = LatLng(lat, lng);
          
          final distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            lat,
            lng,
          ) / 1000;

          // Show all donors (no distance limit)
          Color markerColor = Colors.blue;
          if (bloodGroup == _userBloodGroup) {
            markerColor = Colors.red;
          }

          markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: donorLocation,
                child: GestureDetector(
                  onTap: () => _showDonorInfo(name, bloodGroup, phone, distance),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_pin,
                        color: markerColor,
                        size: 40,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: markerColor, width: 1),
                        ),
                        child: Text(
                          bloodGroup ?? '?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: markerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      }

      setState(() {
        _donorMarkers = markers;
      });
    } catch (e) {
      print('Error loading donors: $e');
    }
  }

  void _loadBloodBanks() {
    if (_currentLocation == null) return;

    final bloodBanks = _getAllBloodBanks();
    List<Marker> markers = [];

    for (var bank in bloodBanks) {
      final lat = bank['latitude'] as double;
      final lng = bank['longitude'] as double;
      
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        lat,
        lng,
      ) / 1000;

      // Show all blood banks across India (no distance limit)
      markers.add(
          Marker(
            width: 90.0,
            height: 90.0,
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () => _showBloodBankInfo(bank, distance),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[700]!, width: 1),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(1)}km',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }

    setState(() {
      _bloodBankMarkers = markers;
    });
  }

  List<Map<String, dynamic>> _getAllBloodBanks() {
    // Return all blood banks from blood_bank_map_screen.dart
    return [
      // Delhi
      {
        'name': 'Red Cross Blood Bank',
        'latitude': 28.7041,
        'longitude': 77.1025,
        'phone': '011-23365446',
        'hours': '24/7',
        'address': 'Connaught Place, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'AIIMS Blood Bank',
        'latitude': 28.5672,
        'longitude': 77.2100,
        'phone': '011-26588500',
        'hours': '24/7',
        'address': 'Ansari Nagar, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Safdarjung Hospital',
        'latitude': 28.5677,
        'longitude': 77.2065,
        'phone': '011-26165060',
        'hours': '24/7',
        'address': 'Ring Road, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'RML Hospital Blood Bank',
        'latitude': 28.6289,
        'longitude': 77.2065,
        'phone': '011-23404056',
        'hours': '24/7',
        'address': 'Baba Kharak Singh Marg, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Lok Nayak Hospital',
        'latitude': 28.6405,
        'longitude': 77.2321,
        'phone': '011-23232461',
        'hours': '24/7',
        'address': 'Jawaharlal Nehru Marg, Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'GTB Hospital Blood Bank',
        'latitude': 28.6748,
        'longitude': 77.3026,
        'phone': '011-22582589',
        'hours': '24/7',
        'address': 'Dilshad Garden, Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Fortis Hospital Shalimar Bagh',
        'latitude': 28.7196,
        'longitude': 77.1644,
        'phone': '011-42777777',
        'hours': '24/7',
        'address': 'Shalimar Bagh, Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Max Hospital Saket',
        'latitude': 28.5244,
        'longitude': 77.2066,
        'phone': '011-26515050',
        'hours': '24/7',
        'address': 'Press Enclave Marg, Saket, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Apollo Hospital Sarita Vihar',
        'latitude': 28.5355,
        'longitude': 77.2910,
        'phone': '011-26825858',
        'hours': '24/7',
        'address': 'Mathura Road, Sarita Vihar, Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Manipal Hospital Dwarka',
        'latitude': 28.5921,
        'longitude': 77.0460,
        'phone': '011-45771000',
        'hours': '24/7',
        'address': 'Sector 6, Dwarka, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Sir Ganga Ram Hospital',
        'latitude': 28.6415,
        'longitude': 77.1925,
        'phone': '011-25750000',
        'hours': '24/7',
        'address': 'Rajinder Nagar, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'BLK Super Speciality Hospital',
        'latitude': 28.6486,
        'longitude': 77.1964,
        'phone': '011-30403040',
        'hours': '24/7',
        'address': 'Pusa Road, New Delhi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Mumbai
      {
        'name': 'Tata Memorial Hospital',
        'latitude': 19.0060,
        'longitude': 72.8397,
        'phone': '022-24177000',
        'hours': '24/7',
        'address': 'Parel, Mumbai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'KEM Hospital Blood Bank',
        'latitude': 18.9984,
        'longitude': 72.8408,
        'phone': '022-24107000',
        'hours': '24/7',
        'address': 'Acharya Donde Marg, Parel, Mumbai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Jaslok Hospital',
        'latitude': 18.9676,
        'longitude': 72.8090,
        'phone': '022-66573333',
        'hours': '24/7',
        'address': 'Dr. G Deshmukh Marg, Mumbai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Lilavati Hospital',
        'latitude': 19.0532,
        'longitude': 72.8311,
        'phone': '022-26567777',
        'hours': '24/7',
        'address': 'Bandra West, Mumbai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Bangalore
      {
        'name': 'Nimhans Blood Centre',
        'latitude': 12.9432,
        'longitude': 77.5961,
        'phone': '080-26995023',
        'hours': '24/7',
        'address': 'Hosur Road, Bangalore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Bangalore Medical College',
        'latitude': 12.9716,
        'longitude': 77.5946,
        'phone': '080-26701150',
        'hours': '24/7',
        'address': 'Fort, Bangalore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Rotary Blood Bank',
        'latitude': 12.9822,
        'longitude': 77.6025,
        'phone': '080-22212580',
        'hours': '10 AM - 6 PM',
        'address': 'Richmond Road, Bangalore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Hyderabad
      {
        'name': 'Gandhi Hospital Blood Bank',
        'latitude': 17.4510,
        'longitude': 78.4977,
        'phone': '040-27503396',
        'hours': '24/7',
        'address': 'Musheerabad, Hyderabad',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Osmania General Hospital',
        'latitude': 17.3850,
        'longitude': 78.4867,
        'phone': '040-24600146',
        'hours': '24/7',
        'address': 'Afzal Gunj, Hyderabad',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Chennai
      {
        'name': 'Rajiv Gandhi Govt. Hospital',
        'latitude': 13.0097,
        'longitude': 80.2209,
        'phone': '044-25281351',
        'hours': '24/7',
        'address': 'Park Town, Chennai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Stanley Medical College',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'phone': '044-25281478',
        'hours': '24/7',
        'address': 'Old Jail Road, Chennai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Kolkata
      {
        'name': 'SSKM Hospital Blood Bank',
        'latitude': 22.5511,
        'longitude': 88.3503,
        'phone': '033-22235347',
        'hours': '24/7',
        'address': 'Bhowanipore, Kolkata',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Medical College Kolkata',
        'latitude': 22.5818,
        'longitude': 88.3630,
        'phone': '033-22414323',
        'hours': '24/7',
        'address': '88, College Street, Kolkata',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Pune
      {
        'name': 'Sassoon General Hospital',
        'latitude': 18.5204,
        'longitude': 73.8567,
        'phone': '020-26126402',
        'hours': '24/7',
        'address': 'Near Railway Station, Pune',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Jehangir Hospital',
        'latitude': 18.5305,
        'longitude': 73.8567,
        'phone': '020-26331001',
        'hours': '24/7',
        'address': '32, Sassoon Road, Pune',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Ahmedabad
      {
        'name': 'Civil Hospital Blood Bank',
        'latitude': 23.0346,
        'longitude': 72.5685,
        'phone': '079-22689721',
        'hours': '24/7',
        'address': 'Asarwa, Ahmedabad',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Sola Civil Hospital',
        'latitude': 23.0885,
        'longitude': 72.5136,
        'phone': '079-23969191',
        'hours': '24/7',
        'address': 'Sola, Ahmedabad',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Jaipur
      {
        'name': 'SMS Hospital Blood Bank',
        'latitude': 26.9124,
        'longitude': 75.7873,
        'phone': '0141-2566251',
        'hours': '24/7',
        'address': 'JLN Marg, Jaipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Fortis Escorts Hospital',
        'latitude': 26.8467,
        'longitude': 75.8056,
        'phone': '0141-2547000',
        'hours': '24/7',
        'address': 'Malviya Nagar, Jaipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      // Dehradun
      {
        'name': 'Doon Hospital Blood Bank',
        'latitude': 30.3165,
        'longitude': 78.0322,
        'phone': '0135-2711303',
        'hours': '24/7',
        'address': 'Rajpur Road, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Max Super Speciality Hospital',
        'latitude': 30.3277,
        'longitude': 78.0454,
        'phone': '0135-6633333',
        'hours': '24/7',
        'address': 'Malsi, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Himalayan Hospital',
        'latitude': 30.3753,
        'longitude': 78.1209,
        'phone': '0135-2772008',
        'hours': '24/7',
        'address': 'Doiwala, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      {
        'name': 'Shri Mahant Indiresh Hospital',
        'latitude': 30.2500,
        'longitude': 78.0000,
        'phone': '0135-2525252',
        'hours': '24/7',
        'address': 'Patel Nagar, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      {
        'name': 'Synergy Hospital',
        'latitude': 30.3396,
        'longitude': 78.0466,
        'phone': '0135-6677777',
        'hours': '24/7',
        'address': 'Vikas Nagar, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
      },
      {
        'name': 'City Hospital Blood Bank',
        'latitude': 30.3215,
        'longitude': 78.0487,
        'phone': '0135-2711122',
        'hours': '10 AM - 8 PM',
        'address': 'Ballupur, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      {
        'name': 'Uttaranchal Ayurvedic Hospital',
        'latitude': 30.3165,
        'longitude': 78.0281,
        'phone': '0135-2740088',
        'hours': '9 AM - 7 PM',
        'address': 'Hathibarkala, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
      },
      {
        'name': 'Apollo Hospital Dehradun',
        'latitude': 30.3088,
        'longitude': 78.0234,
        'phone': '0135-6699999',
        'hours': '24/7',
        'address': 'Clement Town, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Government Doon Medical College',
        'latitude': 30.3427,
        'longitude': 78.0764,
        'phone': '0135-2533333',
        'hours': '24/7',
        'address': 'Patel Nagar, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Combined Hospital Dehradun',
        'latitude': 30.3250,
        'longitude': 78.0450,
        'phone': '0135-2653333',
        'hours': '24/7',
        'address': 'Race Course, Dehradun',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Uttar Pradesh - Lucknow
      {
        'name': 'King George\'s Medical University',
        'latitude': 26.8467,
        'longitude': 80.9462,
        'phone': '0522-2257450',
        'hours': '24/7',
        'address': 'Shah Mina Road, Lucknow',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Sanjay Gandhi PGIMS',
        'latitude': 26.8389,
        'longitude': 81.0042,
        'phone': '0522-2495555',
        'hours': '24/7',
        'address': 'Raebareli Road, Lucknow',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Balrampur Hospital',
        'latitude': 26.8627,
        'longitude': 80.9313,
        'phone': '0522-2740420',
        'hours': '24/7',
        'address': 'Lalbagh, Lucknow',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      {
        'name': 'Sahara Hospital Lucknow',
        'latitude': 26.8721,
        'longitude': 80.9987,
        'phone': '0522-3928888',
        'hours': '24/7',
        'address': 'Viraj Khand, Gomti Nagar, Lucknow',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Uttar Pradesh - Kanpur
      {
        'name': 'Ganesh Shankar Vidyarthi Memorial Medical College',
        'latitude': 26.4499,
        'longitude': 80.3319,
        'phone': '0512-2556300',
        'hours': '24/7',
        'address': 'Swaroop Nagar, Kanpur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Lala Lajpat Rai Hospital',
        'latitude': 26.4675,
        'longitude': 80.3498,
        'phone': '0512-2218181',
        'hours': '24/7',
        'address': 'Gumti No. 5, Kanpur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      {
        'name': 'Regency Hospital Kanpur',
        'latitude': 26.4671,
        'longitude': 80.3464,
        'phone': '0512-6677777',
        'hours': '24/7',
        'address': 'Kalyanpur, Kanpur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
      },
      // Uttar Pradesh - Varanasi
      {
        'name': 'BHU Trauma Centre Blood Bank',
        'latitude': 25.2677,
        'longitude': 82.9913,
        'phone': '0542-2369444',
        'hours': '24/7',
        'address': 'Lanka, Varanasi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Sir Sunderlal Hospital',
        'latitude': 25.2820,
        'longitude': 82.9869,
        'phone': '0542-2307516',
        'hours': '24/7',
        'address': 'BHU Campus, Varanasi',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Uttar Pradesh - Agra
      {
        'name': 'SN Medical College Blood Bank',
        'latitude': 27.1767,
        'longitude': 78.0081,
        'phone': '0562-2262219',
        'hours': '24/7',
        'address': 'Hospital Road, Agra',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'District Hospital Blood Bank',
        'latitude': 27.1833,
        'longitude': 78.0167,
        'phone': '0562-2520235',
        'hours': '8 AM - 8 PM',
        'address': 'MG Road, Agra',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      // Uttar Pradesh - Noida
      {
        'name': 'Jaypee Hospital Blood Bank',
        'latitude': 28.5677,
        'longitude': 77.3291,
        'phone': '0120-4234234',
        'hours': '24/7',
        'address': 'Sector 128, Noida',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Fortis Hospital Noida',
        'latitude': 28.5355,
        'longitude': 77.3910,
        'phone': '0120-3306666',
        'hours': '24/7',
        'address': 'Sector 62, Noida',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      // Madhya Pradesh - Bhopal
      {
        'name': 'Hamidia Hospital Blood Bank',
        'latitude': 23.2599,
        'longitude': 77.4126,
        'phone': '0755-2740772',
        'hours': '24/7',
        'address': 'Royal Market, Bhopal',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'AIIMS Bhopal Blood Bank',
        'latitude': 23.1229,
        'longitude': 77.5619,
        'phone': '0755-2672222',
        'hours': '24/7',
        'address': 'Saket Nagar, Bhopal',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Bansal Hospital Blood Bank',
        'latitude': 23.2156,
        'longitude': 77.4305,
        'phone': '0755-4008111',
        'hours': '24/7',
        'address': 'Shahpura, Bhopal',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      {
        'name': 'Chirayu Medical College',
        'latitude': 23.1815,
        'longitude': 77.4417,
        'phone': '0755-4925555',
        'hours': '24/7',
        'address': 'Bypass Road, Bhopal',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
      },
      // Madhya Pradesh - Indore
      {
        'name': 'MY Hospital Blood Bank',
        'latitude': 22.7196,
        'longitude': 75.8577,
        'phone': '0731-2431340',
        'hours': '24/7',
        'address': 'MG Road, Indore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Bombay Hospital Indore',
        'latitude': 22.7239,
        'longitude': 75.8861,
        'phone': '0731-4222222',
        'hours': '24/7',
        'address': 'Scheme No 94, Indore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      {
        'name': 'CHL Hospital Blood Bank',
        'latitude': 22.7533,
        'longitude': 75.8937,
        'phone': '0731-4044444',
        'hours': '24/7',
        'address': 'A.B. Road, Indore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      {
        'name': 'Medanta Hospital Indore',
        'latitude': 22.7279,
        'longitude': 75.9115,
        'phone': '0731-4777777',
        'hours': '24/7',
        'address': 'Sector A, Indore',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Madhya Pradesh - Jabalpur
      {
        'name': 'Netaji Subhash Chandra Bose Medical College',
        'latitude': 23.1815,
        'longitude': 79.9864,
        'phone': '0761-2672553',
        'hours': '24/7',
        'address': 'Nagpur Road, Jabalpur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Victoria Hospital Blood Bank',
        'latitude': 23.1685,
        'longitude': 79.9536,
        'phone': '0761-2621350',
        'hours': '8 AM - 8 PM',
        'address': 'Civil Lines, Jabalpur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      // Madhya Pradesh - Gwalior
      {
        'name': 'JA Group of Hospitals',
        'latitude': 26.2183,
        'longitude': 78.1828,
        'phone': '0751-4000000',
        'hours': '24/7',
        'address': 'Lashkar, Gwalior',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Birla Hospital Blood Bank',
        'latitude': 26.2124,
        'longitude': 78.1772,
        'phone': '0751-2423838',
        'hours': '24/7',
        'address': 'Jayendra Ganj, Gwalior',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
      },
      // Chhattisgarh - Raipur
      {
        'name': 'Dr. Bhimrao Ambedkar Memorial Hospital',
        'latitude': 21.2514,
        'longitude': 81.6296,
        'phone': '0771-2574970',
        'hours': '24/7',
        'address': 'GE Road, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'MMI Narayana Multispeciality Hospital',
        'latitude': 21.2379,
        'longitude': 81.6337,
        'phone': '0771-4082000',
        'hours': '24/7',
        'address': 'Shankar Nagar, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Shri Shankaracharya Institute',
        'latitude': 21.2285,
        'longitude': 81.6857,
        'phone': '0771-2221039',
        'hours': '24/7',
        'address': 'Junwani, Bhilai Road, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      {
        'name': 'Ramkrishna Care Hospital',
        'latitude': 21.2514,
        'longitude': 81.6050,
        'phone': '0771-4203500',
        'hours': '24/7',
        'address': 'Aurobindo Enclave, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      {
        'name': 'Apollo BSR Hospital Raipur',
        'latitude': 21.2287,
        'longitude': 81.6705,
        'phone': '0771-4466666',
        'hours': '24/7',
        'address': 'Sector 1, Devendra Nagar, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Central Hospital Red Cross',
        'latitude': 21.2379,
        'longitude': 81.6337,
        'phone': '0771-2535388',
        'hours': '10 AM - 6 PM',
        'address': 'Civil Lines, Raipur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      // Chhattisgarh - Bhilai
      {
        'name': 'Bhilai Steel Plant Hospital',
        'latitude': 21.2167,
        'longitude': 81.3833,
        'phone': '0788-2228844',
        'hours': '24/7',
        'address': 'Sector 9, Bhilai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Sankara Eye Hospital Blood Bank',
        'latitude': 21.2094,
        'longitude': 81.4289,
        'phone': '0788-2282020',
        'hours': '8 AM - 8 PM',
        'address': 'Nehru Nagar, Bhilai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      {
        'name': 'JLN Hospital & Research Centre',
        'latitude': 21.1938,
        'longitude': 81.3509,
        'phone': '0788-2284522',
        'hours': '24/7',
        'address': 'Supela, Bhilai',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Chhattisgarh - Durg
      {
        'name': 'Chandulal Chandrakar Memorial Hospital',
        'latitude': 21.1905,
        'longitude': 81.2849,
        'phone': '0788-2324555',
        'hours': '24/7',
        'address': 'Bhilai Road, Durg',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'District Hospital Durg',
        'latitude': 21.1871,
        'longitude': 81.2849,
        'phone': '0788-2322433',
        'hours': '24/7',
        'address': 'Purani Basti, Durg',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      // Chhattisgarh - Bilaspur
      {
        'name': 'CIMS Hospital Bilaspur',
        'latitude': 22.0797,
        'longitude': 82.1409,
        'phone': '07752-260000',
        'hours': '24/7',
        'address': 'Seepat Road, Bilaspur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'Apollo Hospital Bilaspur',
        'latitude': 22.0907,
        'longitude': 82.1511,
        'phone': '07752-352525',
        'hours': '24/7',
        'address': 'Seepat Road, Bilaspur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
      },
      {
        'name': 'Government Medical College',
        'latitude': 22.1014,
        'longitude': 82.1591,
        'phone': '07752-250770',
        'hours': '24/7',
        'address': 'Tikrapara, Bilaspur',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
      // Chhattisgarh - Korba
      {
        'name': 'NTPC Hospital Korba',
        'latitude': 22.3596,
        'longitude': 82.6897,
        'phone': '07759-255555',
        'hours': '24/7',
        'address': 'NTPC Township, Korba',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
      },
      {
        'name': 'District Hospital Korba',
        'latitude': 22.3520,
        'longitude': 82.7511,
        'phone': '07759-222350',
        'hours': '24/7',
        'address': 'Old Bus Stand, Korba',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
      },
      // Chhattisgarh - Rajnandgaon
      {
        'name': 'Late Baliram Kashyap Memorial Hospital',
        'latitude': 21.0974,
        'longitude': 81.0364,
        'phone': '07744-232244',
        'hours': '24/7',
        'address': 'Ward No. 22, Rajnandgaon',
        'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
      },
    ];
  }

  void _showDonorInfo(String name, String? bloodGroup, String phone, double distance) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.red, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Blood Group: ${bloodGroup ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${distance.toStringAsFixed(2)} km away'),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(phone),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.contact_phone),
                label: const Text('Contact Donor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBloodBankInfo(Map<String, dynamic> bank, double distance) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${distance.toStringAsFixed(2)} km away',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(bank['address'])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(bank['phone']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text('Hours: ${bank['hours']}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Blood Bank'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
          backgroundColor: Colors.red[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
          backgroundColor: Colors.red[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeMap();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Combine markers based on toggle
    List<Marker> activeMarkers = [];
    if (_showDonors) activeMarkers.addAll(_donorMarkers);
    if (_showBloodBanks) activeMarkers.addAll(_bloodBankMarkers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Donors & Blood Banks'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadNearbyDonors();
              _loadBloodBanks();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bloodbank',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _currentLocation!,
                    child: const Column(
                      children: [
                        Icon(Icons.my_location, color: Colors.green, size: 40),
                        Text('You', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
                      ],
                    ),
                  ),
                  ...activeMarkers,
                ],
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentLocation!,
                    radius: _searchRadius * 1000,
                    useRadiusInMeter: true,
                    color: Colors.red.withOpacity(0.1),
                    borderColor: Colors.red.withOpacity(0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      const Text('You'),
                    ],
                  ),
                  if (_showDonors) ...[
                    Row(
                      children: [
                        Icon(Icons.person_pin, color: Colors.red, size: 20),
                        const SizedBox(width: 4),
                        const Text('Same Blood'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.person_pin, color: Colors.blue, size: 20),
                        const SizedBox(width: 4),
                        const Text('Other Donors'),
                      ],
                    ),
                  ],
                  if (_showBloodBanks)
                    Row(
                      children: [
                        Icon(Icons.local_hospital, color: Colors.green[700], size: 20),
                        const SizedBox(width: 4),
                        const Text('Blood Bank'),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                ],
              ),
              child: Text(
                '${_donorMarkers.length} donors, ${_bloodBankMarkers.length} banks',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 13.0);
          }
        },
        backgroundColor: Colors.red[700],
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Filters'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Show Donors'),
                value: _showDonors,
                onChanged: (value) {
                  setState(() => _showDonors = value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Blood Banks'),
                value: _showBloodBanks,
                onChanged: (value) {
                  setState(() => _showBloodBanks = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
              _loadNearbyDonors();
              _loadBloodBanks();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
