import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UnbookingRequestsScreen extends StatefulWidget {
  const UnbookingRequestsScreen({super.key});

  @override
  State<UnbookingRequestsScreen> createState() => _UnbookingRequestsScreenState();
}

class _UnbookingRequestsScreenState extends State<UnbookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUnbookingRequests();
    });
  }

  Future<void> _handleApprove(AuthProvider authProvider, String bookingId, String bedId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Approve Unbooking',
      content: 'Are you sure you want to approve this unbooking request? The booking will be cancelled and the bed will become available.',
      confirmText: 'Approve',
      confirmColor: Colors.green,
    );
    if (confirmed) {
      await authProvider.approveUnbooking(bookingId: bookingId, bedId: bedId);
    }
  }

  Future<void> _handleDeny(AuthProvider authProvider, String bookingId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Deny Unbooking',
      content: 'Are you sure you want to deny this unbooking request? The resident will be notified.',
      confirmText: 'Deny',
      confirmColor: Colors.red,
    );
    if (confirmed) {
      await authProvider.denyUnbooking(bookingId: bookingId);
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
                style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
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
        title: const Text('Unbooking Requests'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.staffBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.staffBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No pending requests.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: authProvider.fetchUnbookingRequests,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: authProvider.staffBookings.length,
              itemBuilder: (context, index) {
                final booking = authProvider.staffBookings[index];
                return _buildRequestCard(authProvider, booking);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(AuthProvider authProvider, Map<String, dynamic> booking) {
    final resident = booking['profiles'];
    final room = booking['rooms'];
    final bed = booking['beds'];
    final requestDate = DateTime.parse(booking['created_at']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resident?['full_name'] ?? 'Unknown Resident', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Room: ${room?['room_number'] ?? 'N/A'} - Bed: ${bed?['bed_number'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('Requested on: ${DateFormat.yMMMd().format(requestDate)}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleDeny(authProvider, booking['id']),
                  child: const Text('Deny', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleApprove(authProvider, booking['id'], bed['id'].toString()),
                  child: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
