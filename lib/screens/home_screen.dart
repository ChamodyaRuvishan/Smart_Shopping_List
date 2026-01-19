import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_list_screen.dart';
import 'list_details_screen.dart';
import 'groups_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart'; // Make sure you have this file from the previous step!
import '../services/firestore_service.dart'; // For deleting lists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0 = Home, 1 = My Lists, 2 = Profile

  // This function handles the Bottom Bar clicks
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // We define the different pages here
    final List<Widget> pages = [
      const HomeDashboardContent(), // Created below
      const Center(child: Text("My Lists Page (Coming Soon)")), // Placeholder for middle tab
      const ProfileScreen(), // This links to your Profile Page
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // The body changes based on which tab is selected
      body: pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}

// We moved your original Home content into this separate widget
// so it is easier to swap between Home and Profile
class HomeDashboardContent extends StatelessWidget {
  const HomeDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold( // Nested scaffold for AppBar
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Smart Shopping", style: TextStyle(fontSize: 16, color: Colors.white70)),
            Text("Hi, ${user.email!.split('@')[0]}", 
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ready to shop?", 
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Manage your lists easily.", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shopping_basket, color: Colors.white, size: 30),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 25),

              // 2. Quick Actions
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ActionCard(
                    icon: Icons.add_circle, color: Colors.orange, title: "New List",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.group, color: Colors.blue, title: "My Groups",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.history, color: Colors.purple, title: "History",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.settings, color: Colors.grey, title: "Settings",
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 3. Active Lists from All Groups
              const Text("Your Active Lists", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .where('memberIds', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, groupSnapshot) {
                  if (!groupSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (groupSnapshot.data!.docs.isEmpty) {
                    return const Text("No groups yet. Create one to add lists.");
                  }

                  // Build list of all lists from all groups
                  List<Widget> allListWidgets = [];
                  
                  for (var groupDoc in groupSnapshot.data!.docs) {
                    String groupId = groupDoc.id;
                    String groupName = groupDoc['name'];

                    allListWidgets.add(
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .collection('lists')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, listSnapshot) {
                          if (!listSnapshot.hasData) {
                            return const SizedBox();
                          }

                          if (listSnapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: listSnapshot.data!.docs.map((listDoc) {
                              var listData = listDoc.data() as Map<String, dynamic>;
                              String listId = listDoc.id;
                              String listName = listData['name'];

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: const Icon(Icons.list_alt, color: Colors.teal),
                                  title: Text(listName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("in $groupName", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete List?"),
                                          content: const Text("Any group member can delete this list."),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                FirestoreService().deleteList(groupId, listId, listName);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text("Delete"),
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

                  return allListWidgets.isEmpty
                      ? const Text("No lists in your groups yet.")
                      : Column(children: allListWidgets);
                },
              ),

              const SizedBox(height: 25),

              // 4. Recent Activity
              const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('userActivities')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Text("No recent activity.");
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      
                      DateTime date = DateTime.now();
                      if (data['timestamp'] != null) {
                        date = (data['timestamp'] as Timestamp).toDate();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade50,
                            child: const Icon(Icons.info, size: 18, color: Colors.teal),
                          ),
                          title: Text(data['message']),
                          subtitle: Text(
                            "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('userActivities')
                                  .doc(doc.id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.color, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}