import 'package:flutter/material.dart';
import 'manage_rooms_screen.dart';
import 'reservation_approval_screen.dart';
import 'staff_chat_screen.dart';
import 'staff_dashboard_screen.dart';
import 'staff_profile_screen.dart';
import 'staff_reports_screen.dart';
import 'add_room_screen.dart';

class StaffDrawer extends StatelessWidget {
  const StaffDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Hostel Staff',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
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
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Room'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AddRoomScreen()),
              );
            },
          ),
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
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
