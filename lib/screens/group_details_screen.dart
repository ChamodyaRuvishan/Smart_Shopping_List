import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'list_details_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailsScreen({super.key, required this.groupId, required this.groupData});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = FirestoreService();
    
    // Format the date
    Timestamp? createdTs = groupData['createdAt'] as Timestamp?;
    String createdDate = createdTs != null 
        ? DateFormat('MMM d, yyyy').format(createdTs.toDate()) 
        : "Unknown";

    List members = groupData['members'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(groupData['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Card(
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.teal),
                title: Text("Created by: ${groupData['createdBy'] ?? 'Unknown'}"),
                subtitle: Text("Date: $createdDate"),
              ),
            ),
            const SizedBox(height: 20),
            
            // Members List
            const Text("Group Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text(members[index][0].toUpperCase()),
                      ),
                      title: Text(members[index]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Lists in Group
            const Text("Group Lists", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('lists')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No lists in this group yet."));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var listDoc = snapshot.data!.docs[index];
                      var listData = listDoc.data() as Map<String, dynamic>;
                      String listId = listDoc.id;
                      String listName = listData['name'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.list_alt, color: Colors.teal),
                          title: Text(listName),
                          subtitle: Text("Created by ${listData['createdByName'] ?? 'Unknown'}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete List?"),
                                  content: const Text("Any group member can delete lists."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        firestore.deleteList(groupId, listId, listName);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListDetailsScreen(
                                  groupId: groupId,
                                  listId: listId,
                                  listName: listName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Delete Group Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete),
                label: const Text("Delete Group"),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Group?"),
                      content: const Text("Any group member can delete the group. All lists will be lost."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            firestore.deleteGroup(groupId, groupData['name']);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text("Delete"),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}