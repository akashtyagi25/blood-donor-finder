import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DonorProfilePage extends StatefulWidget {
  const DonorProfilePage({Key? key}) : super(key: key);

  @override
  State<DonorProfilePage> createState() => _DonorProfilePageState();
}

class _DonorProfilePageState extends State<DonorProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Try donors collection first, fallback to users
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('donors').doc(user.uid).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      }
      if (!doc.exists) throw Exception('User data not found');
      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Profile'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUserData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text(errorMessage ?? 'No data found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.red[100],
                        child: Icon(Icons.person, size: 48, color: Colors.red[700]),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData!["name"] ?? "No Name",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData!["email"] ?? "",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (userData!["phone"] != null && userData!["phone"].toString().isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(userData!["phone"] ?? ""),
                          ],
                        ),
                      if (userData!["bloodGroup"] != null && userData!["bloodGroup"].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Chip(
                            label: Text(
                              userData!["bloodGroup"],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: Colors.red[700],
                          ),
                        ),
                      if (userData!["isDonor"] == true || userData!["isAvailable"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Chip(
                            label: Text(
                              userData!["isAvailable"] == false
                                  ? "Not Available to Donate"
                                  : "Available to Donate",
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: userData!["isAvailable"] == false ? Colors.grey : Colors.green,
                          ),
                        ),
                      if (userData!["city"] != null && userData!["city"].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_city, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(userData!["city"] ?? ""),
                            ],
                          ),
                        ),
                      if (userData!["location"] != null && userData!["location"].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Flexible(child: Text(userData!["location"])),
                            ],
                          ),
                        ),
                      if (userData!["latitude"] != null && userData!["longitude"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Text("Lat: \\${userData!["latitude"]}, Lng: \\${userData!["longitude"]}"),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit profile coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
