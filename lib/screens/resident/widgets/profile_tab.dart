// // e:\hostel\lib\screens\resident\widgets\profile_tab.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../providers/auth_provider.dart';
// import '../resident_profile_screen.dart';

// class ProfileTab extends StatelessWidget {
//   const ProfileTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.user;

//     final String userName = user?.userMetadata?['name'] ?? 'Resident Name';
//     final String userEmail = user?.email ?? 'resident@email.com';
//     final String profileImageUrl = user?.userMetadata?['profile_url'] ?? 'https://via.placeholder.com/150';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed: () {
//               Navigator.of(context).push(MaterialPageRoute(
//                 builder: (context) => const ResidentProfileScreen(),
//               ));
//             },
//             tooltip: 'Edit Profile',
//           ),
//         ],
//         automaticallyImplyLeading: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             children: [
//               CircleAvatar(
//                 radius: 60,
//                 backgroundImage: NetworkImage(profileImageUrl),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 userName,
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 userEmail,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 32),
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.logout, color: Colors.red),
//                 title: const Text('Logout', style: TextStyle(color: Colors.red)),
//                 onTap: () async {
//                   await Provider.of<AuthProvider>(context, listen: false).signOut();
//                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
//                 },
//               ),
//               const Divider(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }