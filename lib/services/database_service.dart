import 'package:hostel/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      // Handle error
      print('Error getting user profile: $e');
      return null;
    }
  }
}
