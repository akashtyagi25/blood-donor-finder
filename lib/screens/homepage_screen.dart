import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_screen.dart';
import 'donor_profile_screen.dart';
import 'emergency_alert_screen.dart';
import 'donors_map_screen.dart';
import 'blood_bank_map_screen.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  int _selectedIndex = 0;

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  String userName = 'User'; // Default value to avoid null
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userName = doc.data()?['name'] ?? user.email ?? 'User'; // Keep this line for fetching username
        isLoading = false;
      });
    } else {
      setState(() {
        userName = 'User';
        isLoading = false;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      // Home page (emergency button) with AppBar
      Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Blood Donor Finder'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: logout,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWebOrTablet = constraints.maxWidth > 600;
                  final buttonMaxWidth = isWebOrTablet ? 450.0 : double.infinity;
                  final horizontalPadding = isWebOrTablet ? 64.0 : 32.0;
                  final verticalPadding = isWebOrTablet ? 48.0 : 32.0;
                  final fontSize = isWebOrTablet ? 32.0 : 24.0;
                  final iconSize = isWebOrTablet ? 40.0 : 32.0;
                  
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(isWebOrTablet ? 48.0 : 24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isWebOrTablet) ...[
                              Icon(
                                Icons.emergency,
                                size: 80,
                                color: Colors.red[700],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Need Blood?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send emergency alert to nearby donors',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const EmergencyAlertScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(
                                    vertical: verticalPadding,
                                    horizontal: horizontalPadding,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  elevation: 8,
                                ),
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'EMERGENCY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      // Map page - Find Donors
      const DonorsMapScreen(),
      // Profile page (no AppBar)
      const DonorProfileScreen(),
    ];
    return Scaffold(
      body: _pages[_selectedIndex],
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
            icon: Icon(Icons.map),
            label: 'Find Donors',
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

