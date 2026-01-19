import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingList {
  final String id;
  final String name;
  final String groupId; // Which group does this belong to?
  final String createdBy;
  final DateTime createdAt;
  final bool isCompleted;

  ShoppingList({
    required this.id,
    required this.name,
    required this.groupId,
    required this.createdBy,
    required this.createdAt,
    this.isCompleted = false,
  });

  // Convert Firebase Data to our Object
  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      id: doc.id,
      name: data['name'] ?? '',
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert our Object to Firebase Data
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'groupId': groupId,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isCompleted': isCompleted,
    };
  }
}