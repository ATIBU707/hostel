import 'package:flutter/material.dart';
import 'package:hostel/services/auth_service.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Student!'),
      ),
    );
  }
}
