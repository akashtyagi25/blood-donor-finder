import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/donor.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // No GoogleMapController needed for flutter_map
  String? selectedBloodGroup;
  bool isLoading = false;
  List<Donor> results = [];
  String? errorMessage;
  double? userLat;
  double? userLng;
  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  Future<void> searchDonors() async {
    setState(() { isLoading = true; errorMessage = null; results = []; });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoading = false;
            errorMessage = 'Location permission denied. Please enable location to search nearby donors.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoading = false;
          errorMessage = 'Location permission permanently denied. Please enable it from app settings.';
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      userLat = position.latitude;
      userLng = position.longitude;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('donors')
          .where('bloodGroup', isEqualTo: selectedBloodGroup)
          .where('isAvailable', isEqualTo: true)
          .get();
      // Filter by distance (e.g., 10km radius)
      const double radiusKm = 10.0;
      results = querySnapshot.docs.map((doc) => Donor.fromMap(doc.data())).where((donor) {
        final double distance = Geolocator.distanceBetween(
          userLat!, userLng!, donor.latitude, donor.longitude) / 1000.0;
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      setState(() { errorMessage = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Find Nearby Blood Donors',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              decoration: const InputDecoration(
                labelText: 'Select Blood Group',
                border: OutlineInputBorder(),
              ),
              items: bloodGroups.map((bg) => DropdownMenuItem(
                value: bg,
                child: Text(bg),
              )).toList(),
              onChanged: (val) => setState(() => selectedBloodGroup = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: selectedBloodGroup == null || isLoading ? null : searchDonors,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            if (!isLoading && results.isEmpty && selectedBloodGroup != null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No donors found nearby.', style: TextStyle(fontSize: 16)),
              ),
            if (userLat != null && userLng != null)
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(userLat!, userLng!),
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.bloodbank',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(userLat!, userLng!),
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
                          ),
                          ...results.map((donor) => Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(donor.latitude, donor.longitude),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final donor = results[index];
                    final double distance = userLat != null && userLng != null
                        ? (Geolocator.distanceBetween(userLat!, userLng!, donor.latitude, donor.longitude) / 1000.0)
                        : 0.0;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: Text(donor.bloodGroup, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${donor.email}'),
                            Text('Distance: ${distance.toStringAsFixed(2)} km'),
                          ],
                        ),
                        trailing: donor.isAvailable
                            ? const Text('Available', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
