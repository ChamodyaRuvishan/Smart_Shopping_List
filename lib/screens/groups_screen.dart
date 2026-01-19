import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'group_details_screen.dart'; 

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = FirestoreService();

    // Helper to show "Add Group" dialog
    void showAddGroupDialog() {
      final TextEditingController nameController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Create New Group"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "e.g., Home, Office"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  firestore.createGroup(nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Groups")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddGroupDialog,
        icon: const Icon(Icons.add),
        label: const Text("New Group"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getUserGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("No groups yet. Create one!"),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List members = data['members'] ?? [];
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.groups, color: Colors.teal),
                  ),
                  title: Text(data['name'], 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${members.length} members"),
                  onTap: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(groupId: doc.id, groupData: data)
      ));
    },
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      final emailController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Add Member"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Enter the email of a registered user."),
                              const SizedBox(height: 10),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  hintText: "e.g. az@gmail.com",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Checking user database...")),
                                );

                                String result = await firestore.addMemberSafe(
                                  doc.id,
                                  emailController.text.trim(),
                                );

                                if (result == "Success") {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Member added successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}