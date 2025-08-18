import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../donor/donor_homepage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  String? selectedBloodGroup;
  bool isLoading = false;
  String? errorMessage;
  bool isDonor = true;
  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  Future<void> register() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
            final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Save user type and blood group to Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'isDonor': isDonor,
        'bloodGroup': selectedBloodGroup ?? '',
      });
      if (mounted) {
        if (isDonor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DonorHomepage()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() { errorMessage = e.message; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bloodtype, color: Colors.red[700], size: 60),
                    const SizedBox(height: 12),
                    Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              prefixIcon: Icon(Icons.map),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Register as:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<bool>(
                          title: Row(
                            children: [
                              Icon(Icons.volunteer_activism, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('Blood Donor (I want to donate blood)', overflow: TextOverflow.ellipsis, maxLines: 2),
                              ),
                            ],
                          ),
                          value: true,
                          groupValue: isDonor,
                          onChanged: (val) {
                            setState(() { isDonor = val ?? true; });
                          },
                        ),
                        if (isDonor) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 40.0, right: 8.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedBloodGroup,
                                  decoration: const InputDecoration(
                                    labelText: 'Your Blood Group',
                                    prefixIcon: Icon(Icons.bloodtype),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: bloodGroups
                                      .map((bg) => DropdownMenuItem(
                                            value: bg,
                                            child: Text(bg),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedBloodGroup = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This will help recipients find you by blood group.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                        RadioListTile<bool>(
                          title: Row(
                            children: [
                              Icon(Icons.bloodtype, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('Recipient (I need blood)', overflow: TextOverflow.ellipsis, maxLines: 2),
                              ),
                            ],
                          ),
                          value: false,
                          groupValue: isDonor,
                          onChanged: (val) {
                            setState(() { isDonor = val ?? true; });
                          },
                        ),
                        if (!isDonor) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 40.0, right: 8.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedBloodGroup,
                                  decoration: const InputDecoration(
                                    labelText: 'Required Blood Group',
                                    prefixIcon: Icon(Icons.bloodtype),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: bloodGroups
                                      .map((bg) => DropdownMenuItem(
                                            value: bg,
                                            child: Text(bg),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedBloodGroup = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This will help us match you with the right donors.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Register', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
