import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'donor_alert_tile.dart';
import 'donor_profile_page.dart';

class DonorHomepage extends StatefulWidget {
  const DonorHomepage({Key? key}) : super(key: key);

  @override
  State<DonorHomepage> createState() => _DonorHomepageState();
}

class _DonorHomepageState extends State<DonorHomepage> {
  int _selectedIndex = 0;
  String? donorBloodGroup;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDonorBloodGroup();
  }

  Future<void> fetchDonorBloodGroup() async {
    setState(() { isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      donorBloodGroup = doc.data()?['bloodGroup'];
      setState(() { isLoading = false; });
    } catch (e) {
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Home (alerts)
      Scaffold(
        appBar: AppBar(
          title: const Text('Donor Home'),
          backgroundColor: Colors.red[700],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : donorBloodGroup == null
                ? Center(child: Text(errorMessage ?? 'No blood group found'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('alerts')
                        .where('bloodGroup', isEqualTo: donorBloodGroup)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: \\${snapshot.error}'));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('No matching alerts found.'));
                      }
                      return ListView(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(data['uid'] ?? '').get(),
                            builder: (context, snapshot) {
                              String recipientName = '';
                              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                                recipientName = (snapshot.data!.data() as Map<String, dynamic>?)?['name'] ?? '';
                              }
                              return DonorAlertTile(
                                description: data['description'] ?? '',
                                location: data['location'] ?? '',
                                phone: data['phone'] ?? '',
                                bloodGroup: data['bloodGroup'] ?? '',
                                recipientName: recipientName,
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
      ),
      // Profile
      const DonorProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        selectedItemColor: Colors.red[700],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
