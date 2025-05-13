import 'package:flutter/material.dart';
import 'sos_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  static const String routeName = "EmergencyContacts";
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جهات الاتصال الطارئة"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // حقل إدخال رقم الهاتف
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: "أدخل رقم هاتف الطوارئ",
                hintText: "مثال: 1234567890",
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            // زر إضافة جهة اتصال
            ElevatedButton(
              onPressed: () {
                String contact = _contactController.text.trim();
                if (contact.isNotEmpty) {
                  setState(() {
                    SOSService.addEmergencyContact(contact);
                    _contactController.clear();
                  });
                }
              },
              child: const Text("إضافة جهة اتصال"),
            ),
            const SizedBox(height: 20),
            // عرض جهات الاتصال المضافة
            Expanded(
              child: ListView.builder(
                itemCount: SOSService.emergencyContacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(SOSService.emergencyContacts[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          SOSService.removeEmergencyContact(index);
                        });
                      },
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
