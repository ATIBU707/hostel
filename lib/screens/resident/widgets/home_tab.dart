import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final residentName = authProvider.userProfile?['full_name'] ?? 'Resident';

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Welcome Message
            Text(
              'Welcome, $residentName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Room Information Card
            _buildRoomInfoCard(context, authProvider),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final bool hasApprovedBooking = authProvider.activeBooking != null;
                final bool canBookRoom = !authProvider.residentBookings.any((b) => b['status'] == 'approved' || b['status'] == 'pending');

                List<Widget> actionCards = [];

                if (canBookRoom) {
                  actionCards.add(_buildActionCard(
                    context,
                    Icons.king_bed_outlined,
                    'Book a Room',
                    () => Navigator.pushNamed(context, '/book-room'),
                  ));
                }

                if (hasApprovedBooking) {
                  actionCards.addAll([
                    _buildActionCard(context, Icons.payment, 'Pay Rent', () {}),
                    _buildActionCard(context, Icons.build, 'New Request', onCreateNewRequest),
                    _buildActionCard(
                      context,
                      Icons.receipt_long,
                      'Payment History',
                      () => onNavigateToTab(2),
                    ),
                  ]);
                }

                actionCards.add(_buildActionCard(
                  context,
                  Icons.contact_support_outlined,
                  'Contact Admin',
                  () => Navigator.pushNamed(context, '/staff-list'),
                ));

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: actionCards,
                );
              },
            ),
          ],
        );
      },
    );
  }

    Widget _buildActionCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
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
      return _buildNoBookingCard();
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
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
                          color: Colors.white,
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

  Widget _buildNoBookingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: ListTile(
          leading: Icon(Icons.info_outline, size: 32),
          title: Text('No Active Booking', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Book a room to see your details here.'),
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
