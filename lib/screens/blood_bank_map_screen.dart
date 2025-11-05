import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class BloodBankMapScreen extends StatefulWidget {
  const BloodBankMapScreen({Key? key}) : super(key: key);

  @override
  State<BloodBankMapScreen> createState() => _BloodBankMapScreenState();
}

class _BloodBankMapScreenState extends State<BloodBankMapScreen> {
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  List<Marker> _bloodBankMarkers = [];
  
  // Sample blood bank data (you can move this to Firebase later)
  final List<Map<String, dynamic>> _bloodBanks = [
    // Delhi Blood Banks
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
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'O-'],
    },
    {
      'name': 'Safdarjung Hospital Blood Bank',
      'latitude': 28.5711,
      'longitude': 77.2072,
      'phone': '011-26165060',
      'hours': '9 AM - 5 PM',
      'address': 'Safdarjung, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    {
      'name': 'Apollo Hospital Blood Bank',
      'latitude': 28.5429,
      'longitude': 77.2827,
      'phone': '011-26925858',
      'hours': '24/7',
      'address': 'Sarita Vihar, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Max Hospital Blood Bank',
      'latitude': 28.5494,
      'longitude': 77.2637,
      'phone': '011-26925050',
      'hours': '24/7',
      'address': 'Saket, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    {
      'name': 'Fortis Hospital Blood Bank',
      'latitude': 28.5355,
      'longitude': 77.2515,
      'phone': '011-42776222',
      'hours': '24/7',
      'address': 'Vasant Kunj, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    {
      'name': 'Sir Ganga Ram Hospital',
      'latitude': 28.6414,
      'longitude': 77.1952,
      'phone': '011-25750000',
      'hours': '24/7',
      'address': 'Rajinder Nagar, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Ram Manohar Lohia Hospital',
      'latitude': 28.6329,
      'longitude': 77.2065,
      'phone': '011-23365525',
      'hours': '24/7',
      'address': 'Connaught Place, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'O-'],
    },
    {
      'name': 'GTB Hospital Blood Bank',
      'latitude': 28.6747,
      'longitude': 77.3068,
      'phone': '011-22582525',
      'hours': '24/7',
      'address': 'Dilshad Garden, Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Lok Nayak Hospital',
      'latitude': 28.6414,
      'longitude': 77.2296,
      'phone': '011-23230008',
      'hours': '24/7',
      'address': 'Jawaharlal Nehru Marg, Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    {
      'name': 'Batra Hospital Blood Bank',
      'latitude': 28.5321,
      'longitude': 77.2630,
      'phone': '011-29958747',
      'hours': '8 AM - 8 PM',
      'address': 'Tughlakabad, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
    },
    {
      'name': 'Indraprastha Apollo Hospital',
      'latitude': 28.5355,
      'longitude': 77.2828,
      'phone': '011-29871070',
      'hours': '24/7',
      'address': 'Sarita Vihar, New Delhi',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    // Mumbai Blood Banks
    {
      'name': 'Tata Memorial Hospital Blood Bank',
      'latitude': 19.0110,
      'longitude': 72.8442,
      'phone': '022-24177000',
      'hours': '24/7',
      'address': 'Parel, Mumbai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'KEM Hospital Blood Bank',
      'latitude': 19.0060,
      'longitude': 72.8397,
      'phone': '022-24107000',
      'hours': '24/7',
      'address': 'Parel, Mumbai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'O-'],
    },
    {
      'name': 'Lilavati Hospital',
      'latitude': 19.0521,
      'longitude': 72.8284,
      'phone': '022-26567777',
      'hours': '24/7',
      'address': 'Bandra West, Mumbai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Hinduja Hospital Blood Bank',
      'latitude': 19.0548,
      'longitude': 72.8339,
      'phone': '022-24447000',
      'hours': '24/7',
      'address': 'Mahim, Mumbai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    // Bangalore Blood Banks
    {
      'name': 'Rotary Blood Bank Bangalore',
      'latitude': 12.9716,
      'longitude': 77.5946,
      'phone': '080-22210041',
      'hours': '24/7',
      'address': 'Richmond Road, Bangalore',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Nimhans Blood Bank',
      'latitude': 12.9431,
      'longitude': 77.5972,
      'phone': '080-26995000',
      'hours': '8 AM - 6 PM',
      'address': 'Hosur Road, Bangalore',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    {
      'name': 'Sankalp Blood Bank',
      'latitude': 12.9698,
      'longitude': 77.6040,
      'phone': '080-25599000',
      'hours': '24/7',
      'address': 'Koramangala, Bangalore',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    // Hyderabad Blood Banks
    {
      'name': 'Red Cross Blood Bank Hyderabad',
      'latitude': 17.4065,
      'longitude': 78.4772,
      'phone': '040-23395248',
      'hours': '24/7',
      'address': 'Red Hills, Hyderabad',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Apollo Hospital Hyderabad',
      'latitude': 17.4399,
      'longitude': 78.3489,
      'phone': '040-23607777',
      'hours': '24/7',
      'address': 'Jubilee Hills, Hyderabad',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    // Chennai Blood Banks
    {
      'name': 'Rajiv Gandhi Govt Hospital',
      'latitude': 13.0086,
      'longitude': 80.2095,
      'phone': '044-25261350',
      'hours': '24/7',
      'address': 'Park Town, Chennai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Apollo Hospital Chennai',
      'latitude': 13.0569,
      'longitude': 80.2574,
      'phone': '044-28293333',
      'hours': '24/7',
      'address': 'Greams Road, Chennai',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    // Kolkata Blood Banks
    {
      'name': 'SSKM Hospital Blood Bank',
      'latitude': 22.5448,
      'longitude': 88.3426,
      'phone': '033-22041101',
      'hours': '24/7',
      'address': 'College Street, Kolkata',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Nightingale Blood Bank Kolkata',
      'latitude': 22.5726,
      'longitude': 88.3639,
      'phone': '033-22275548',
      'hours': '24/7',
      'address': 'Salt Lake, Kolkata',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'O-'],
    },
    // Pune Blood Banks
    {
      'name': 'Ruby Hall Clinic Blood Bank',
      'latitude': 18.5204,
      'longitude': 73.8567,
      'phone': '020-26163405',
      'hours': '24/7',
      'address': 'Grant Road, Pune',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Sassoon Hospital Blood Bank',
      'latitude': 18.5314,
      'longitude': 73.8446,
      'phone': '020-26053990',
      'hours': '24/7',
      'address': 'Near Railway Station, Pune',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    // Ahmedabad Blood Banks
    {
      'name': 'Prathama Blood Centre',
      'latitude': 23.0225,
      'longitude': 72.5714,
      'phone': '079-40004000',
      'hours': '24/7',
      'address': 'Satellite, Ahmedabad',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Civil Hospital Ahmedabad',
      'latitude': 23.0330,
      'longitude': 72.5698,
      'phone': '079-22688311',
      'hours': '24/7',
      'address': 'Asarwa, Ahmedabad',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    // Jaipur Blood Banks
    {
      'name': 'SMS Hospital Blood Bank',
      'latitude': 26.9124,
      'longitude': 75.7873,
      'phone': '0141-2516295',
      'hours': '24/7',
      'address': 'JLN Marg, Jaipur',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Eternal Hospital Jaipur',
      'latitude': 26.8467,
      'longitude': 75.8056,
      'phone': '0141-6666999',
      'hours': '24/7',
      'address': 'Jagatpura, Jaipur',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
    },
    // Dehradun Blood Banks
    {
      'name': 'Doon Hospital Blood Bank',
      'latitude': 30.3165,
      'longitude': 78.0322,
      'phone': '0135-2711101',
      'hours': '24/7',
      'address': 'Rajpur Road, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Coronation Hospital Blood Bank',
      'latitude': 30.3165,
      'longitude': 78.0450,
      'phone': '0135-2652524',
      'hours': '8 AM - 8 PM',
      'address': 'Chakrata Road, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    {
      'name': 'Max Super Speciality Hospital',
      'latitude': 30.3398,
      'longitude': 77.9981,
      'phone': '0135-6693000',
      'hours': '24/7',
      'address': 'Malsi, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Synergy Hospital Blood Bank',
      'latitude': 30.3255,
      'longitude': 78.0436,
      'phone': '0135-2773737',
      'hours': '24/7',
      'address': 'Vasant Vihar, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    {
      'name': 'SGRR Institute of Medical Sciences',
      'latitude': 30.2809,
      'longitude': 78.0492,
      'phone': '0135-2471000',
      'hours': '24/7',
      'address': 'Patel Nagar, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Himalayan Institute Hospital',
      'latitude': 30.2429,
      'longitude': 78.0707,
      'phone': '0135-2471133',
      'hours': '24/7',
      'address': 'Jolly Grant, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'],
    },
    {
      'name': 'City Hospital Blood Bank',
      'latitude': 30.3252,
      'longitude': 78.0457,
      'phone': '0135-2714433',
      'hours': '9 AM - 9 PM',
      'address': 'Rajpur Road, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
    },
    {
      'name': 'Red Cross Blood Bank Dehradun',
      'latitude': 30.3237,
      'longitude': 78.0376,
      'phone': '0135-2653363',
      'hours': '10 AM - 6 PM',
      'address': 'Rajpur Road, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Graphic Era Hospital',
      'latitude': 30.2673,
      'longitude': 78.0449,
      'phone': '0135-2809090',
      'hours': '24/7',
      'address': 'Clement Town, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Shri Mahant Indiresh Hospital',
      'latitude': 30.3185,
      'longitude': 78.0566,
      'phone': '0135-2525101',
      'hours': '24/7',
      'address': 'Patel Nagar, Dehradun',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+'],
    },
    // Uttar Pradesh - Lucknow
    {
      'name': 'King George Medical University',
      'latitude': 26.8467,
      'longitude': 80.9462,
      'phone': '0522-2257450',
      'hours': '24/7',
      'address': 'Shah Mina Road, Lucknow',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Sanjay Gandhi PGIMS Blood Bank',
      'latitude': 26.9124,
      'longitude': 80.9462,
      'phone': '0522-2668700',
      'hours': '24/7',
      'address': 'Raebareli Road, Lucknow',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-'],
    },
    {
      'name': 'Balrampur Hospital Blood Bank',
      'latitude': 26.8467,
      'longitude': 80.9100,
      'phone': '0522-2235749',
      'hours': '24/7',
      'address': 'Gopalganj, Lucknow',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'O-'],
    },
    {
      'name': 'Sahara Hospital Lucknow',
      'latitude': 26.8550,
      'longitude': 80.9800,
      'phone': '0522-6707070',
      'hours': '24/7',
      'address': 'Viraj Khand, Gomti Nagar, Lucknow',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-'],
    },
    // Uttar Pradesh - Kanpur
    {
      'name': 'Ganesh Shankar Vidyarthi Memorial',
      'latitude': 26.4499,
      'longitude': 80.3319,
      'phone': '0512-2556262',
      'hours': '24/7',
      'address': 'Swaroop Nagar, Kanpur',
      'bloodTypes': ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'],
    },
    {
      'name': 'Regency Hospital Blood Bank',
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

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      Position position = await _determinePosition();
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

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

  void _loadBloodBanks() {
    if (_currentLocation == null) return;

    List<Marker> markers = [];

    for (var bank in _bloodBanks) {
      final lat = bank['latitude'] as double;
      final lng = bank['longitude'] as double;
      
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        lat,
        lng,
      ) / 1000; // Convert to km

      markers.add(
        Marker(
          width: 100.0,
          height: 100.0,
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () => _showBloodBankInfo(bank, distance),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[700]!, width: 1),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
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

  void _showBloodBankInfo(Map<String, dynamic> bank, double distance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
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
            const SizedBox(height: 20),
            _buildInfoRow(Icons.location_on, bank['address']),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, bank['phone']),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, 'Hours: ${bank['hours']}'),
            const SizedBox(height: 16),
            const Text(
              'Available Blood Types:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (bank['bloodTypes'] as List<String>).map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red[700]!),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement call functionality
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${bank['phone']}...')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement navigation
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening navigation...')),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Blood Banks'),
          backgroundColor: Colors.red[700],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Blood Banks'),
          backgroundColor: Colors.red[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Blood Banks'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBloodBanks,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 12.0,
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
                  // Current location marker
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _currentLocation!,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.my_location,
                          color: Colors.green,
                          size: 40,
                        ),
                        Text(
                          'You',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Blood bank markers
                  ..._bloodBankMarkers,
                ],
              ),
            ],
          ),
          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      const Text('You'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.local_hospital, color: Colors.red[700], size: 20),
                      const SizedBox(width: 4),
                      const Text('Blood Bank'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Blood bank count
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${_bloodBankMarkers.length} blood banks found',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 12.0);
          }
        },
        backgroundColor: Colors.red[700],
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
