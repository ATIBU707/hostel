import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchResidentBookings();
    });
  }

  Future<void> _handleCancelBooking(AuthProvider authProvider, String bookingId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Cancel Booking',
      content: 'Are you sure you want to cancel this booking? This action cannot be undone.',
    );
    if (confirmed) {
      await authProvider.cancelBooking(bookingId: bookingId);
    }
  }

  Future<void> _handleRequestUnbook(AuthProvider authProvider, String bookingId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Request Unbooking',
      content: 'Are you sure you want to request to unbook? A notification will be sent to the staff for approval.',
    );
    if (confirmed) {
      await authProvider.requestUnbook(bookingId: bookingId);
    }
  }

  Future<bool> _showConfirmationDialog({required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.residentBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.residentBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No bookings yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Your active and past bookings will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: authProvider.fetchResidentBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: authProvider.residentBookings.length,
              itemBuilder: (context, index) {
                final booking = authProvider.residentBookings[index];
                return _buildBookingCard(authProvider, booking);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(AuthProvider authProvider, Map<String, dynamic> booking) {
    final room = booking['rooms'];
    final bed = booking['beds'];
    final status = booking['status'];
    final bookingDate = DateTime.parse(booking['created_at']);

    final bool canCancel = status == 'pending';
    final bool canRequestUnbook = status == 'approved';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room ${room?['room_number'] ?? 'N/A'} - Bed ${bed?['bed_number'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Booked on: ${DateFormat.yMMMd().format(bookingDate)}'),
            const SizedBox(height: 8),
            Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: _getStatusColor(status),
              labelStyle: const TextStyle(color: Colors.white),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  ElevatedButton.icon(
                    onPressed: () => _handleCancelBooking(authProvider, booking['id']),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Booking'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                if (canRequestUnbook)
                  ElevatedButton.icon(
                    onPressed: () => _handleRequestUnbook(authProvider, booking['id']),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Request Unbook'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                if (!canCancel && !canRequestUnbook)
                  Text('No actions available', style: TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'unbooking_requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
