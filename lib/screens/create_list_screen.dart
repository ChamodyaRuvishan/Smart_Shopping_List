import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _nameController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  String? _selectedGroupId; // To store which group the user picked

  void _saveList() async {
    if (_nameController.text.isEmpty || _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name and select a group")),
      );
      return;
    }

    // Call our service to save to Firebase
    await _firestore.createList(_nameController.text, _selectedGroupId!);
    
    if (mounted) {
      Navigator.pop(context); // Go back to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New List")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("List Name", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "e.g., Weekly Groceries",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text("Assign to Group", style: TextStyle(fontWeight: FontWeight.bold)),
            // Fetch Groups from Firebase to populate the dropdown
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.getUserGroups(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                
                var groups = snapshot.data!.docs;
                
                if (groups.isEmpty) {
                  return const Text("No groups found. Please create a group first!", style: TextStyle(color: Colors.red));
                }

                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  hint: const Text("Select a Group"),
                  items: groups.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedGroupId = val);
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: _saveList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Create List", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}