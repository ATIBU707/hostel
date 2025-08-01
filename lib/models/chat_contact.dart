class ChatContact {
  final String id;
  final String name;
  final String? avatarUrl;
  final String roomNumber;

  ChatContact({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.roomNumber,
  });

  factory ChatContact.fromMap(Map<String, dynamic> map) {
    String roomNumber = 'N/A';
    if (map['bookings'] != null && (map['bookings'] as List).isNotEmpty) {
      final booking = (map['bookings'] as List).first;
      if (booking['rooms'] != null) {
        roomNumber = booking['rooms']['room_number'] ?? 'N/A';
      }
    }

    return ChatContact(
      id: map['id'] ?? '',
      name: map['full_name'] ?? 'Unnamed Resident',
      avatarUrl: map['avatar_url'],
      roomNumber: roomNumber,
    );
  }
}
