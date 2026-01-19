import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  final String userName = FirebaseAuth.instance.currentUser!.email!.split('@')[0];

  // --- LOGGING (User-specific) ---
  Future<void> logActivity(String message) async {
    await _db.collection('users').doc(userId).collection('userActivities').add({
      'message': message,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- GROUPS (Shared between members, stored at root level) ---
  Future<void> createGroup(String groupName) async {
    await _db.collection('groups').add({
      'name': groupName,
      'members': [userEmail],
      'memberIds': [userId],
      'createdBy': userEmail,
      'createdByUid': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logActivity("Created group: $groupName");
  }

  Future<void> deleteGroup(String groupId, String groupName) async {
    // Delete the group from root collection
    await _db.collection('groups').doc(groupId).delete();
    
    // Log the Deletion
    await logActivity("Deleted group: $groupName");
  }

  // Get groups where current user is a member
  Stream<QuerySnapshot> getUserGroups() {
    return _db.collection('groups').where('memberIds', arrayContains: userId).snapshots();
  }

  Future<String> addMemberSafe(String groupId, String emailToAdd) async {
    try {
      // 1. Check if user exists
      QuerySnapshot userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: emailToAdd)
          .get();

      if (userQuery.docs.isEmpty) {
        return "User not found! They must sign up first.";
      }

      // 2. Get their Data
      var userDoc = userQuery.docs.first;
      String newMemberId = userDoc['uid'];
      String newMemberName = userDoc['name'];

      // 3. Add to Group (at root level)
      await _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([emailToAdd]),
        'memberIds': FieldValue.arrayUnion([newMemberId]),
      });

      await logActivity("Added $newMemberName ($emailToAdd) to a group");
      return "Success";
      
    } catch (e) {
      return "Error: $e";
    }
  }

  // --- LISTS (Stored at group level, shared by all members) ---
  Future<void> createList(String name, String groupId) async {
    await _db.collection('groups').doc(groupId).collection('lists').add({
      'name': name,
      'groupId': groupId,
      'createdBy': userId,
      'createdByEmail': userEmail,
      'createdByName': userName,
      'createdAt': FieldValue.serverTimestamp(),
      'isCompleted': false,
    });
    await logActivity("Created list: $name in a group");
  }

  // --- ITEMS (Stored at list level, with priority support) ---
  Future<void> addItem(String groupId, String listId, String itemName, String quantity, String priority) async {
    final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .add({
          'name': itemName,
          'quantity': quantity,
          'priority': priority,
          'priorityOrder': priorityOrder[priority] ?? 2,
          'isBought': false,
          'boughtBy': null,
          'addedAt': FieldValue.serverTimestamp(),
        });
    await logActivity("Added item: $itemName to a list");
  }

  Future<void> deleteItem(String groupId, String listId, String itemId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Future<void> updateItemStatus(String groupId, String listId, String itemId, bool isBought, String? boughtBy) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .update({
          'isBought': isBought,
          'boughtBy': boughtBy,
        });
  }

  Future<void> deleteList(String groupId, String listId, String listName) async {
    // Delete list from group
    await _db.collection('groups').doc(groupId).collection('lists').doc(listId).delete();
    await logActivity("Deleted list: $listName");
  }

  // Get all lists for a specific group (all members see the same lists)
  Stream<QuerySnapshot> getGroupLists(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all lists from all groups the user is a member of
  Stream<QuerySnapshot> getAllUserLists() {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots();
  }

  // Update list completion status
  Future<void> updateListStatus(String groupId, String listId, bool isCompleted) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .doc(listId)
        .update({'isCompleted': isCompleted});
  }

  // Get items for a list sorted by priority
  Stream<QuerySnapshot> getListItems(String groupId, String listId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .orderBy('priorityOrder', descending: false)
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}