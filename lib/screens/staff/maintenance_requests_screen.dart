import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() => _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchStaffMaintenanceRequests();
    });
  }

  void _showUpdateStatusDialog(BuildContext context, Map<String, dynamic> request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String currentStatus = request['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Request Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: currentStatus,
                isExpanded: true,
                items: {
                  'Pending': 'pending',
                  'In Process': 'in_progress',
                  'Completed': 'completed',
                  'Cancelled': 'cancelled',
                }.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      currentStatus = newValue;
                    });
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await authProvider.updateMaintenanceRequestStatus(
                  requestId: request['id'],
                  newStatus: currentStatus,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && (authProvider.staffMaintenanceRequests?.isEmpty ?? true)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.staffMaintenanceRequests == null || authProvider.staffMaintenanceRequests!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No maintenance requests.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: authProvider.fetchStaffMaintenanceRequests,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: authProvider.staffMaintenanceRequests!.length,
              itemBuilder: (context, index) {
                final request = authProvider.staffMaintenanceRequests![index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final resident = request['bookings']?['profiles'];
    final room = request['bookings']?['rooms'];
    final requestDate = DateTime.parse(request['created_at']);
    final status = request['status'] ?? 'Pending';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showUpdateStatusDialog(context, request),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request['category'],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(request['description']),
              const SizedBox(height: 16),
              Text('Resident: ${resident?['full_name'] ?? 'N/A'}'),
              Text('Room: ${room?['room_number'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text('Requested on: ${DateFormat.yMMMd().format(requestDate)}', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Process':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
