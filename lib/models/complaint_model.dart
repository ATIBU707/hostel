class Complaint {
  final String id;
  final String userId;
  final String description;
  final String? roomId;
  final String status;
  final DateTime date;

  Complaint({
    required this.id,
    required this.userId,
    required this.description,
    this.roomId,
    required this.status,
    required this.date,
  });

  factory Complaint.fromMap(Map<String, dynamic> data, String documentId) {
    return Complaint(
      id: documentId,
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      roomId: data['roomId'],
      status: data['status'] ?? 'open',
      date: DateTime.parse(data['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'roomId': roomId,
      'status': status,
      'date': date,
    };
  }
}
