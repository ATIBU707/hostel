import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MaintenanceRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const MaintenanceRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'unknown';
    final createdAt = DateTime.parse(request['created_at']);
    final formattedDate = DateFormat.yMMMd().format(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request['category'] ?? 'General',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported on $formattedDate',
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 24),
            Text(
              request['description'] ?? 'No description provided.',
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pending':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'in_progress':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.construction_rounded;
        break;
      case 'completed':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
      default:
        chipColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
