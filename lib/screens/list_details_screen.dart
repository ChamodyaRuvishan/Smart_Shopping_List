import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListDetailsScreen extends StatefulWidget {
  final String groupId;
  final String listId;
  final String listName;

  const ListDetailsScreen({
    super.key, 
    required this.groupId,
    required this.listId, 
    required this.listName
  });

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  // Function to Add Item with Quantity
  void _addItem() {
    if (_itemController.text.isEmpty) return;

    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .add({
          'name': _itemController.text,
          'quantity': _qtyController.text.isEmpty ? "1" : _qtyController.text,
          'isBought': false,
          'boughtBy': null,
          'addedAt': FieldValue.serverTimestamp(),
        });

    _itemController.clear();
    _qtyController.clear();
    Navigator.pop(context);
  }

  // Show Input Dialog
  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Item", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Row to put Name and Quantity side-by-side
            Row(
              children: [
                // Item Name (Takes up most space)
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      hintText: "e.g. Milk",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Quantity (Takes up small space)
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.text, // Text allowed (e.g., "1kg")
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      hintText: "1",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text("Add to List"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Toggle Checkbox (Now saves WHO bought it)
  void _toggleItem(String itemId, bool currentStatus) {
    final user = FirebaseAuth.instance.currentUser!;
    final String userName = user.email!.split('@')[0];

    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .doc(itemId)
        .update({
          'isBought': !currentStatus,
          'boughtBy': !currentStatus ? userName : null,
        });
  }

  // Delete Item
  void _deleteItem(String itemId) {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        label: const Text("Add Item"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('lists')
            .doc(widget.listId)
            .collection('items')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var items = snapshot.data!.docs;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("List is empty. Add something!"),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var doc = items[index];
              Map data = doc.data() as Map<String, dynamic>;
              
              bool isBought = data['isBought'] ?? false;
              String quantity = data['quantity'] ?? "1";
              String? boughtBy = data['boughtBy'];

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.centerRight, 
                  padding: const EdgeInsets.only(right: 20), 
                  child: const Icon(Icons.delete, color: Colors.red)
                ),
                onDismissed: (_) => _deleteItem(doc.id),
                child: Card(
                  elevation: 0,
                  color: isBought ? Colors.grey[100] : Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: isBought,
                      activeColor: Colors.teal,
                      onChanged: (val) => _toggleItem(doc.id, isBought),
                    ),
                    title: Row(
                      children: [
                        Text(
                          data['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: isBought ? TextDecoration.lineThrough : null,
                            color: isBought ? Colors.grey : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quantity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBought ? Colors.grey[300] : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                            "x$quantity",
                            style: TextStyle(
                              fontSize: 12, 
                              color: isBought ? Colors.grey[600] : Colors.teal.shade700,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ],
                    ),
                    subtitle: isBought 
                      ? Text("Bought by $boughtBy", style: const TextStyle(color: Colors.teal, fontSize: 12, fontStyle: FontStyle.italic))
                      : null,

trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
        onPressed: () {
           // Direct delete without swiping
           _deleteItem(doc.id);
        },
      ),

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