class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? roomId;
  final String paymentStatus;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.roomId,
    required this.paymentStatus,
  });

  // Factory constructor to create a UserModel from a map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      roomId: data['roomId'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
    );
  }

  // Method to convert a UserModel to a map (e.g., for writing to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'role': role,
      'roomId': roomId,
      'paymentStatus': paymentStatus,
    };
  }
}
