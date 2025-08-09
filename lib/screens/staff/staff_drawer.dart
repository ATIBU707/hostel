import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_rooms_screen.dart';
import 'reservation_approval_screen.dart';
import 'staff_chat_screen.dart';
import 'staff_dashboard_screen.dart';
import 'staff_profile_screen.dart';
import 'staff_reports_screen.dart';
import 'unbooking_requests_screen.dart';
import 'maintenance_requests_screen.dart';
// import 'add_room_screen.dart';

class StaffDrawer extends StatelessWidget {
  const StaffDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                accountName: Text(authProvider.userProfile?['full_name'] ?? 'Staff Member'),
                accountEmail: Text(authProvider.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: authProvider.userProfile?['avatar_url'] != null &&
                          authProvider.userProfile!['avatar_url'].isNotEmpty
                      ? NetworkImage(authProvider.userProfile!['avatar_url'])
                      : null,
                  child: authProvider.userProfile?['avatar_url'] == null ||
                          authProvider.userProfile!['avatar_url'].isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StaffDashboardScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.hotel),
            title: Text('Manage Rooms'),
            onTap: () {
               Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ManageRoomsScreen()),
              );
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text('Add Room'),
          //   onTap: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => AddRoomScreen()),
          //     );
          //   },
          // ),
          ListTile(
            leading: Icon(Icons.check_circle),
            title: Text('Reservations'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ReservationApprovalScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.event_busy_outlined),
            title: Text('Unbooking Requests'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UnbookingRequestsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.build_circle_outlined),
            title: Text('Maintenance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MaintenanceRequestsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StaffProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.message),
            title: Text('Messages'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StaffChatScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.report),
            title: Text('Reports'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StaffReportsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      );
        },
      ),
    );
  }
}
