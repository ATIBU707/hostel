import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/resident_service.dart';
import '../services/staff_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AuthProvider extends ChangeNotifier {
  // Internal state
  User? _user;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _activeBooking;
  List<Map<String, dynamic>>? _payments;
  List<Map<String, dynamic>>? _maintenanceRequests;
  List<Map<String, dynamic>>? _announcements;
  List<Map<String, dynamic>>? _availableRooms;
  List<Map<String, dynamic>>? _staffMembers;
  List<Map<String, dynamic>>? _staffMaintenanceRequests;
  List<Map<String, dynamic>> _residentBookings = [];
  List<Map<String, dynamic>> _allBookings = [];
  bool _hasApprovedBooking = false;
  List<Map<String, dynamic>> _staffBookings = [];
  List<Map<String, dynamic>> get staffBookings => _staffBookings;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for UI binding
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  // Map<String, dynamic>? get activeBooking => _activeBooking;
  List<Map<String, dynamic>>? get payments => _payments;
  List<Map<String, dynamic>>? get maintenanceRequests => _maintenanceRequests;
  List<Map<String, dynamic>>? get announcements => _announcements;
  List<Map<String, dynamic>>? get availableRooms => _availableRooms;
  List<Map<String, dynamic>>? get staffMembers => _staffMembers;
  List<Map<String, dynamic>>? get staffMaintenanceRequests => _staffMaintenanceRequests;
  List<Map<String, dynamic>> get residentBookings => _residentBookings;
  List<Map<String, dynamic>> get allBookings => _allBookings;
  bool get hasApprovedBooking => _hasApprovedBooking;

  Map<String, dynamic>? get activeBooking {
    try {
      return _residentBookings.firstWhere((booking) => booking['status'] == 'approved');
    } catch (e) {
      return null;
    }
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userRole => _userProfile?['role'];

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  // Initialization
  void _initializeAuth() {
    _user = AuthService.currentUser;
    if (_user != null) {
      _loadUserProfile().then((_) => _loadInitialData());
    }

    AuthService.authStateChanges.listen((AuthState data) {
      final session = data.session;
      if (session != null && _user?.id != session.user.id) {
        _user = session.user;
        _loadUserProfile().then((_) => _loadInitialData());
      } else if (session == null && _user != null) {
        _clearAllData();
      }
    });
  }

  // Core Data Loading
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getUserProfile();
    } catch (e) {
      _setError('Failed to load user profile: ${_getErrorMessage(e)}');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    if (_userProfile == null) return;
    _setLoading(true);
    final role = _userProfile!['role'];
    if (role == 'resident') {
      await _loadResidentData();
    } else if (role == 'staff' || role == 'admin') {
      await _loadStaffData();
    }
    _setLoading(false);
  }

  Future<void> _loadResidentData() async {
    try {
      await fetchResidentBookings();
      // Set the active booking for other parts of the app that need it.
      final activeBookings = _residentBookings.where((b) => b['status'] == 'active');
      _activeBooking = activeBookings.isNotEmpty ? activeBookings.first : null;

      // Find the first relevant booking to load maintenance requests.
      final relevantBookings = _residentBookings.where((b) => b['status'] == 'approved' || b['status'] == 'active');
      if (relevantBookings.isNotEmpty) {
        final relevantBookingId = relevantBookings.first['id'];
        await _loadMaintenanceRequests(bookingId: relevantBookingId);
      }

      // Load payments only if there is a truly active booking.
      if (_activeBooking != null) {
        await _loadPayments();
      }
      
      await fetchAllBookings();
    } catch (e) {
      _setError('Failed to load resident data: ${_getErrorMessage(e)}');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadStaffData() async {
    await fetchStaffMaintenanceRequests();
  }

  // Authentication Methods
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        return true;
      } else {
        _setError('Registration failed. Please try again.');
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await AuthService.signIn(email: email, password: password);
      await _loadUserProfile();
      if (_userProfile == null) {
        throw Exception('User profile not found.');
      }
      final role = _userProfile!['role'];
      await _loadInitialData();

      if (role == 'staff' || role == 'admin') {
        return '/staff-dashboard';
      } else if (role == 'resident') {
        return '/resident-dashboard';
      } else {
        throw Exception('Unknown user role.');
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
      _clearAllData();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resident-Specific Methods
  Future<void> createMaintenanceRequest({
    required String category,
    required String description,
  }) async {
    final approvedOrActive = _residentBookings
        .where((b) => b['status'] == 'approved' || b['status'] == 'active');

    final relevantBooking = approvedOrActive.isNotEmpty ? approvedOrActive.first : _activeBooking;

    if (relevantBooking == null) {
      _setError('You must have an approved or active booking to create a request.');
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    try {
      await ResidentService.createMaintenanceRequest(
        bookingId: relevantBooking['id'],
        category: category,
        description: description,
      );
      await _loadMaintenanceRequests(bookingId: relevantBooking['id']);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadPayments() async {
    if (_activeBooking == null) return;
    try {
      final bookingId = _activeBooking!['id'];
      _payments = await ResidentService.getPaymentsForBooking(bookingId);
    } catch (e) {
      _setError('Failed to load payments: ${_getErrorMessage(e)}');
    }
  }

  Future<void> _loadMaintenanceRequests({required String bookingId}) async {
    try {
      _maintenanceRequests = await ResidentService.getMaintenanceRequests(bookingId);
    } catch (e) {
      _setError('Failed to load maintenance requests: ${_getErrorMessage(e)}');
    }
  }

  Future<void> _loadAnnouncements() async {
    // try {
    //   _announcements = await ResidentService.getAnnouncements();
    // } catch (e) {
    //   _setError('Failed to load announcements: ${_getErrorMessage(e)}');
    // }
  }

  Future<void> fetchAvailableRooms() async {
    _setLoading(true);
    _clearError();
    try {
      _availableRooms = await ResidentService.getAvailableRooms();
    } catch (e) {
      _setError('Failed to load available rooms: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchResidentBookings() async {
    if (userRole != 'resident') return;
    _setLoading(true);
    try {
      _residentBookings = await Supabase.instance.client
          .from('bookings')
          .select('*, rooms(*), beds(*)')
          .eq('resident_id', _user!.id)
          .order('created_at', ascending: false);
      _hasApprovedBooking = _residentBookings.any((b) => b['status'] == 'approved');
    } catch (e) {
      _setError('Failed to load your bookings: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllBookings() async {
    _setLoading(true);
    _clearError();
    try {
      final response = await Supabase.instance.client.from('bookings').select('bed_id, status');
      _allBookings = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load all bookings: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> bookRoom({required String roomId, required String bedId}) async {
    if (_user == null) return;
    _setLoading(true);
    _clearError();
    try {
      print('Creating booking for user ${_user!.id}, room $roomId, bed $bedId');
      
      await ResidentService.createBooking(
        residentId: _user!.id,
        roomId: roomId,
        bedId: bedId,
      );
      
      print('Booking created successfully');
      
      // Refresh all relevant data
      await _loadInitialData();
      await fetchAvailableRooms(); // Refresh available rooms
      
      print('Data refreshed after booking');
    } catch (e) {
      print('Error in bookRoom: $e');
      _setError('Failed to book room: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelBooking({required String bookingId}) async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      await fetchResidentBookings(); // Refresh the list
    } catch (e) {
      _setError('Failed to cancel booking: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> requestUnbook({required String bookingId}) async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'unbooking_requested'})
          .eq('id', bookingId);
      await fetchResidentBookings(); // Refresh the list
    } catch (e) {
      _setError('Failed to request unbooking: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchStaffMembers() async {
    _setLoading(true);
    try {
      _staffMembers = await ResidentService.getStaffMembers();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      await ResidentService.sendMessage(
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Staff-Specific Methods

  Future<void> fetchUnbookingRequests() async {
    _setLoading(true);
    _clearError();
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, rooms(*, hostels(*)), beds(*), profiles(*)')
          .eq('status', 'unbooking_requested')
          .order('created_at', ascending: true);
      _staffBookings = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _setError('Failed to fetch unbooking requests: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> approveUnbooking({required String bookingId, required String bedId}) async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId);
      await Supabase.instance.client.from('beds').update({'is_available': true}).eq('id', bedId);
      await fetchUnbookingRequests(); // Refresh the list
    } catch (e) {
      _setError('Failed to approve unbooking: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> denyUnbooking({required String bookingId}) async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client.from('bookings').update({'status': 'approved'}).eq('id', bookingId);
      await fetchUnbookingRequests(); // Refresh the list
    } catch (e) {
      _setError('Failed to deny unbooking: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateMaintenanceRequestStatus({required String requestId, required String newStatus}) async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client
          .from('maintenance_requests')
          .update({'status': newStatus})
          .eq('id', requestId);
      await fetchStaffMaintenanceRequests(); // Refresh the list
    } catch (e) {
      _setError('Failed to update maintenance request: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchStaffMaintenanceRequests() async {
    _setLoading(true);
    try {
      final response = await Supabase.instance.client
          .from('maintenance_requests')
          .select('*, bookings(*, profiles(*), rooms(*))')
          .order('created_at', ascending: false);
      _staffMaintenanceRequests = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _setError('Failed to load staff maintenance requests: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Room Management (Staff Only)
  Future<void> addRoom({
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double rentAmount,
    String? description,
    required String hostelName,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    if (_user == null || userRole != 'staff') {
      throw Exception('Only staff members can add rooms');
    }

    _setLoading(true);
    _clearError();

    try {
      // 1. Compress image if not on web
      Uint8List finalImageBytes = imageBytes;
      if (!kIsWeb) {
        final compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 800,
          minWidth: 800,
          quality: 85,
        );
        finalImageBytes = Uint8List.fromList(compressedBytes);
      }

      // 2. Upload image to Supabase Storage
      final imagePath = '/${_user!.id}/${DateTime.now().toIso8601String()}_$imageName';
      await Supabase.instance.client.storage.from('room-images').uploadBinary(
            imagePath,
            finalImageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 3. Get the public URL of the uploaded image
      final imageUrl = Supabase.instance.client.storage
          .from('room-images')
          .getPublicUrl(imagePath);

      // 4. Insert room into Supabase
      final response = await Supabase.instance.client
          .from('rooms')
          .insert({
            'room_number': roomNumber,
            'room_type': roomType,
            'capacity': capacity,
            'rent_amount': rentAmount,
            'description': description,
            'staff_id': _user!.id,
            'status': 'available',
            'created_at': DateTime.now().toIso8601String(),
            'hostel_name': hostelName,
            'image_url': imageUrl,
          })
          .select()
          .single();

      // 5. Create beds for the room based on capacity
      final roomId = response['id'];
      final List<Map<String, dynamic>> beds = [];

      for (int i = 1; i <= capacity; i++) {
        beds.add({
          'room_id': roomId,
          'bed_number': i.toString(),
          'is_available': true,
        });
      }

      // 6. Insert beds into Supabase
      if (beds.isNotEmpty) {
        await Supabase.instance.client.from('beds').insert(beds);
      }

      // 7. Refresh available rooms data
      await fetchAvailableRooms();

    } catch (e) {
      _setError('Failed to add room: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> fetchStaffBookings() async {
    if (_user == null || userRole != 'staff') return;
    _setLoading(true);
    _clearError();
    try {
      _staffBookings = await StaffService.getStaffBookings(_user!.id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load staff bookings: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch rooms managed by current staff member
  Future<List<Map<String, dynamic>>> fetchStaffRooms() async {
    if (_user == null || userRole != 'staff') {
      throw Exception('Only staff members can access this data');
    }
    
    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .select('''
            *,
            beds(
              id,
              bed_number,
              is_available
            ),
            bookings(
              id,
              resident_id,
              check_in_date,
              check_out_date,
              status,
              profiles!bookings_resident_id_fkey(
                full_name,
                phone
              )
            )
          ''')
          .eq('staff_id', _user!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _setError('Failed to load staff rooms: ${_getErrorMessage(e)}');
      rethrow;
    }
  }

  // Profile Management


  // State Management Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearAllData() {
    _user = null;
    _userProfile = null;
    _activeBooking = null;
    _payments = null;
    _maintenanceRequests = null;
    _announcements = null;
    _availableRooms = null;
    _staffMembers = null;
    _staffMaintenanceRequests = null;
    _allBookings = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Room Management Methods

  Future<List<Map<String, dynamic>>> getStaffRooms() async {
    if (_user == null) throw Exception('User not authenticated');
    
    return await StaffService.getStaffRooms(_user!.id);
  }

  Future<void> updateProfile({
    required String email,
    required String fullName,
    required String phone,
    Uint8List? imageBytes,
    String? imageFileExtension,
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    try {
      _setLoading(true);
      String? imageUrl;

      if (imageBytes != null && imageFileExtension != null) {
        final imageName = '${DateTime.now().millisecondsSinceEpoch}.$imageFileExtension';
        final imagePath = '${_user!.id}/$imageName';

        await Supabase.instance.client.storage.from('avatars').uploadBinary(
              imagePath,
              imageBytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
        imageUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(imagePath);
      }

      final updates = {
        'id': _user!.id,
        'full_name': fullName,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (imageUrl != null) {
        updates['avatar_url'] = imageUrl;
      }

      // Update email if it has changed
      if (email != _user!.email) {
        await Supabase.instance.client.auth.updateUser(UserAttributes(email: email));
      }

      await Supabase.instance.client.from('profiles').upsert(updates);
      await _loadUserProfile(); // Refresh profile data
    } catch (e) {
      _setError('Failed to update profile: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeProfilePicture() async {
    if (_user == null) throw Exception('User not authenticated');
    try {
      _setLoading(true);
      // We can't easily delete the folder or find the exact file name from here.
      // A better approach would be to use a Supabase function or handle this differently.
      // For now, we will just nullify the URL in the profile.
      await Supabase.instance.client.from('profiles').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _user!.id);

      await _loadUserProfile(); // Refresh profile data
    } catch (e) {
      _setError('Failed to remove profile picture: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRoom({
    required String roomId,
    required String hostelName,
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double rentAmount,
    Uint8List? imageBytes,
    String? imageFileExtension,
  }) async {
    if (_user == null) throw Exception('User not authenticated');

    try {
      _setLoading(true);
      String? imageUrl;

      if (imageBytes != null && imageFileExtension != null) {
        final imageName = '${DateTime.now().millisecondsSinceEpoch}.$imageFileExtension';
        final imagePath = '/room_images/${_user!.id}/$imageName';

        await Supabase.instance.client.storage.from('room-images').uploadBinary(
              imagePath,
              imageBytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
        imageUrl = Supabase.instance.client.storage.from('room-images').getPublicUrl(imagePath);
      }

      await StaffService.updateRoom(
        roomId: roomId,
        hostelName: hostelName,
        roomNumber: roomNumber,
        roomType: roomType,
        capacity: capacity,
        rentAmount: rentAmount,
        imageUrl: imageUrl,
      );
    } catch (e) {
      _setError('Failed to update room: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await StaffService.deleteRoom(roomId);
  }

  Future<List<Map<String, dynamic>>> fetchChatContacts() async {
    if (_user == null) throw Exception('User not authenticated');

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, avatar_url, bookings!inner(rooms(room_number))')
          .eq('role', 'resident');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Failed to fetch chat contacts: ${_getErrorMessage(e)}');
      rethrow;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is PostgrestException) {
      return error.message;
    } else {
      return error.toString();
    }
  }

}
