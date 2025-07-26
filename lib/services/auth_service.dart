import 'package:hostel/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final AuthResponse res = await _auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final newUser = UserModel(
          uid: res.user!.id,
          name: name,
          email: email,
          role: 'student',
          paymentStatus: 'pending',
        );

        await _client.from('users').insert(newUser.toMap());
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
