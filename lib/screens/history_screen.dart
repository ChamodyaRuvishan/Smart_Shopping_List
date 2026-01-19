import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Activity History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('userActivities')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No activity yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // Handle Timestamp
              DateTime date = DateTime.now();
              if (data['timestamp'] != null) {
                date = (data['timestamp'] as Timestamp).toDate();
              }
              
              String timeStr = DateFormat('h:mm a').format(date);
              String dateStr = DateFormat('MMM d, yyyy').format(date);

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  color: Colors.red.shade100,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('userActivities')
                      .doc(doc.id)
                      .delete();
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(Icons.history, size: 20, color: Colors.teal),
                    ),
                    title: Text(data['message'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("$dateStr at $timeStr", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    trailing: Icon(Icons.swipe_left, color: Colors.grey[300], size: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}