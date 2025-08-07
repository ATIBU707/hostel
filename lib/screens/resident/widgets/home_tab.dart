import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback onCreateNewRequest;

  const HomeTab({
    super.key,
    required this.onNavigateToTab,
    required this.onCreateNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final residentName = authProvider.userProfile?['full_name'] ?? 'Resident';
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        children: [
          _buildHeader(residentName, today),
          const SizedBox(height: 28),
          _buildRoomInfoCard(context, authProvider),
          const SizedBox(height: 28),
          _buildQuickActions(context, authProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome, $name!',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider authProvider) {
    final bool hasApprovedBooking = authProvider.activeBooking != null;
    final bool canBookRoom = !authProvider.residentBookings.any((b) => b['status'] == 'approved' || b['status'] == 'pending');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (canBookRoom)
          _buildActionItem(
            context,
            Icons.king_bed_outlined,
            'Book a Room',
            'Find and reserve your new space',
            () => Navigator.pushNamed(context, '/book-room'),
          ),
        if (hasApprovedBooking) ...[
          _buildActionItem(
            context,
            Icons.payment_outlined,
            'Make a Payment',
            'Pay your monthly rent and dues',
            () => onNavigateToTab(2), // Navigate to PaymentsTab
          ),
          _buildActionItem(
            context,
            Icons.build_outlined,
            'New Maintenance Request',
            'Report an issue in your room or common areas',
            onCreateNewRequest,
          ),
        ],
        _buildActionItem(
          context,
          Icons.contact_support_outlined,
          'Contact Staff',
          'Get in touch with the hostel administration',
          () => Navigator.pushNamed(context, '/staff-list'),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildRoomInfoCard(BuildContext context, AuthProvider authProvider) {
    final approvedBooking = authProvider.activeBooking;
    Map<String, dynamic>? pendingBooking;
    try {
      pendingBooking = authProvider.residentBookings.firstWhere((b) => b['status'] == 'pending');
    } catch (e) {
      pendingBooking = null;
    }

    final bookingToShow = approvedBooking ?? pendingBooking;

    if (bookingToShow == null) {
      return _buildNoBookingCard(context);
    }

    final room = bookingToShow['rooms'];
    final bed = bookingToShow['beds'];
    final status = bookingToShow['status'];

    final imageUrl = room?['image_url'] as String?;
    final roomNumber = room?['room_number']?.toString() ?? 'N/A';
    final roomType = room?['room_type'] ?? 'Unknown';
    final bedNumber = bed?['bed_number']?.toString() ?? 'N/A';
    final hostelName = room?['hostel_name']?.toString() ?? 'No Hostel';

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hostelName.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Room $roomNumber - $roomType',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Assigned Space', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Bed $bedNumber', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                _buildStatusChip(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBookingCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Icon(Icons.king_bed_outlined, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              'No Active Booking',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'You don\'t have a room yet. Let\'s find one for you!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/book-room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Book a Room Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final Color chipColor = isApproved ? Colors.green.shade100 : (isPending ? Colors.orange.shade100 : Colors.grey.shade200);
    final Color textColor = isApproved ? Colors.green.shade800 : (isPending ? Colors.orange.shade800 : Colors.grey.shade800);
    final IconData icon = isApproved ? Icons.check_circle_outline : (isPending ? Icons.hourglass_empty_rounded : Icons.help_outline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 12, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
