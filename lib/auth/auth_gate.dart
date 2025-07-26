import 'package:flutter/material.dart';
import 'package:hostel/auth/login_screen.dart';
import 'package:hostel/screens/admin_home_screen.dart';
import 'package:hostel/screens/student_home_screen.dart';
import 'package:hostel/services/auth_service.dart';
import 'package:hostel/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>( 
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final session = snapshot.data!.session;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder(
          future: DatabaseService().getUserProfile(session.user.id),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              // Handle case where user profile doesn't exist yet
              // or there was an error. You might want to log out here.
              return const LoginScreen(); 
            }

            final userRole = userSnapshot.data!.role;

            if (userRole == 'admin') {
              return const AdminHomeScreen();
            } else {
              return const StudentHomeScreen();
            }
          },
        );
      },
    );
  }
}
