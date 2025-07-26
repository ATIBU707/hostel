class Payment {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String status;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory Payment.fromMap(Map<String, dynamic> data, String documentId) {
    return Payment(
      id: documentId,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: DateTime.parse(data['date']),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'date': date,
      'status': status,
    };
  }
}
