class Room {
  final String id;
  final String number;
  final int capacity;
  final bool isOccupied;
  final List<String> occupants;

  Room({
    required this.id,
    required this.number,
    required this.capacity,
    required this.isOccupied,
    required this.occupants,
  });

  factory Room.fromMap(Map<String, dynamic> data, String documentId) {
    return Room(
      id: documentId,
      number: data['number'] ?? '',
      capacity: data['capacity'] ?? 0,
      isOccupied: data['isOccupied'] ?? false,
      occupants: List<String>.from(data['occupants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'capacity': capacity,
      'isOccupied': isOccupied,
      'occupants': occupants,
    };
  }
}
