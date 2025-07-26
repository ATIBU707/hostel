import 'package:flutter/material.dart';
import 'package:hostel/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oqluvwbcltmasmqtuvbm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xbHV2d2JjbHRtYXNtcXR1dmJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM1MDU5MzUsImV4cCI6MjA2OTA4MTkzNX0.L-V1hromigxU7VHS-Lezav_Vg6ct0S2ts5s0HxopXx4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hostel Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

