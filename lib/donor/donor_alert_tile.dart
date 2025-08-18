import 'package:flutter/material.dart';

class DonorAlertTile extends StatelessWidget {
  final String description;
  final String location;
  final String phone;
  final String bloodGroup;
  final String recipientName;

  const DonorAlertTile({
    Key? key,
    required this.description,
    required this.location,
    required this.phone,
    required this.bloodGroup,
    required this.recipientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: $recipientName'),
            Text('Location: $location'),
            Text('Phone: $phone'),
            Text('Blood Group: $bloodGroup'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
