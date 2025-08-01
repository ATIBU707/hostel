import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import 'edit_room_screen.dart';
import 'staff_drawer.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  List<Map<String, dynamic>> _staffRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffRooms();
  }

  Future<void> _loadStaffRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rooms = await authProvider.getStaffRooms();
      if (mounted) setState(() => _staffRooms = rooms);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rooms: ${e.toString()}'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoom(String roomId, String roomNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Room', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete room $roomNumber? This action is permanent.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.deleteRoom(roomId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Room $roomNumber deleted.'), backgroundColor: Colors.green.shade600),
          );
          _loadStaffRooms();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting room: ${e.toString()}'), backgroundColor: Colors.red.shade600),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: StaffDrawer(),
      backgroundColor: colors.surface, // Use theme surface color
      appBar: AppBar(
        title: Text('Manage Rooms', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colors.onSurface)),
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors.shadow.withOpacity(0.2),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.primary),
            onPressed: _loadStaffRooms,
            tooltip: 'Refresh Rooms',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: colors.outline.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffRooms.isEmpty
              ? _buildEmptyState()
              : _buildRoomsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No Rooms Found',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new room to see it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    return RefreshIndicator(
      onRefresh: _loadStaffRooms,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _staffRooms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildRoomCard(_staffRooms[index]);
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final colors = Theme.of(context).colorScheme;
    final roomNumber = room['room_number']?.toString() ?? 'N/A';
    final roomType = room['room_type'] ?? 'Unknown';
    final capacity = room['capacity'] ?? 0;
    final rentAmount = (room['rent_amount'] ?? 0.0).toDouble();
    final occupiedBeds = room['occupied_beds'] ?? 0;
    final hostelName = room['hostel_name'] ?? 'Unassigned';
    final imageUrl = room['image_url'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: colors.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left: Image
            SizedBox(
              width: 110,
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0))),
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: Icon(Icons.apartment_rounded, size: 40, color: Colors.grey.shade400)),
              ),
            ),

            // Middle: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostelName.toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Room $roomNumber',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(Icons.king_bed_outlined, roomType, colors),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.groups_outlined, '$occupiedBeds/$capacity Beds', colors),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '\$${rentAmount.toStringAsFixed(0)}/month',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Actions
            Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: colors.outline.withOpacity(0.2)))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRoomScreen(room: room)));
                      if (result == true) _loadStaffRooms();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20), color: colors.onSurfaceVariant,
                    tooltip: 'Edit Room', splashRadius: 24,
                  ),
                  IconButton(
                    onPressed: () => _deleteRoom(room['id'], roomNumber),
                    icon: const Icon(Icons.delete_outline, size: 20), color: colors.error,
                    tooltip: 'Delete Room', splashRadius: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: colors.primary),
          ),
        ],
      ),
    );
  }
}
