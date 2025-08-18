import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final TextEditingController descriptionController = TextEditingController();
  String? userLocation;
  String? userBloodGroup;
  String? userPhone;
  bool isLoading = true;
  String? statusMessage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() { isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Try donors first, then users
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('donors').doc(user.uid).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      }
      if (!doc.exists) throw Exception('User data not found');
      final data = doc.data() as Map<String, dynamic>?;
      setState(() {
        userLocation = data?["location"] ?? data?["city"] ?? "";
        userBloodGroup = data?["bloodGroup"] ?? "";
        userPhone = data?["phone"] ?? "";
        isLoading = false;
      });
    } catch (e) {
      setState(() { statusMessage = e.toString(); isLoading = false; });
    }
  }

  Future<void> sendAlert() async {
    setState(() { isLoading = true; statusMessage = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      await FirebaseFirestore.instance.collection('alerts').add({
        'uid': user.uid,
        'description': descriptionController.text.trim(),
        'location': userLocation ?? '',
        'bloodGroup': userBloodGroup ?? '',
        'phone': userPhone ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() { statusMessage = 'Alert sent to nearby users!'; });
    } catch (e) {
      setState(() { statusMessage = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Alert'), backgroundColor: Colors.red[700]),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe your emergency...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userLocation?.isNotEmpty == true ? userLocation! : 'No location found',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.bloodtype, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        userBloodGroup?.isNotEmpty == true ? userBloodGroup! : 'No blood group found',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        userPhone?.isNotEmpty == true ? userPhone! : 'No phone found',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: sendAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Send Alert', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Center(child: Text(statusMessage!, style: const TextStyle(color: Colors.blue))),
                  ],
                ],
              ),
            ),
    );
  }
}
