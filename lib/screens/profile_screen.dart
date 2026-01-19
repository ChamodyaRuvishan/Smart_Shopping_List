import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;
    
    // Get join date from Firebase Auth Metadata
    String joinedDate = "Unknown";
    if (user.metadata.creationTime != null) {
      joinedDate = DateFormat('MMMM d, yyyy').format(user.metadata.creationTime!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            
            // User Email
            Text(
              user.email!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text("Joined: $joinedDate", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 30),

            // Statistics Card
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('memberIds', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int groupCount = 0;
                if (snapshot.hasData) {
                  groupCount = snapshot.data!.docs.length;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: "My Groups", 
                        count: groupCount.toString(), 
                        icon: Icons.group
                      )
                    ),
                    const SizedBox(width: 15),
                    // You could add another stat here like "Lists Created"
                    const Expanded(
                      child: _StatCard(
                        label: "Status", 
                        count: "Active", 
                        icon: Icons.verified_user
                      )
                    ),
                  ],
                );
              },
            ),
            
            const Spacer(),
            
            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;

  const _StatCard({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal, size: 30),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}