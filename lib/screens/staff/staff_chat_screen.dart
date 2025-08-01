import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_contact.dart';
import '../../providers/auth_provider.dart';
import 'chat_detail_screen.dart';
import 'staff_drawer.dart';

class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key});

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  late Future<List<ChatContact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _contactsFuture = authProvider.fetchChatContacts().then((data) => 
        data.map((item) => ChatContact.fromMap(item)).toList()
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Residents'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      drawer: const StaffDrawer(),
      body: FutureBuilder<List<ChatContact>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No residents found.'));
          }

          final contacts = snapshot.data!;

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: contact.avatarUrl != null
                      ? NetworkImage(contact.avatarUrl!)
                      : null,
                  child: contact.avatarUrl == null
                      ? Text(contact.name.isNotEmpty ? contact.name[0] : 'R')
                      : null,
                ),
                title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Room: ${contact.roomNumber}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(contact: contact),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
