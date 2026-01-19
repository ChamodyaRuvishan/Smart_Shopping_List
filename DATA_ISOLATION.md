# Smart Shopping - Data Structure & User Isolation

## Overview
This app implements **user-specific data isolation** combined with **shared group functionality**. 
- Groups are shared between members
- Each user's lists and activities remain private
- Users can only see data they have access to

## Database Structure

### Firestore Collection Architecture
```
users/
├── {userId1}/
│   ├── uid
│   ├── email
│   ├── name
│   ├── createdAt
│   ├── userActivities/         (user's private activity log)
│   │   └── {activityId}/
│   │       ├── message
│   │       ├── userId
│   │       ├── userEmail
│   │       └── timestamp
│   └── lists/                  (user's private shopping lists)
│       └── {listId}/
│           ├── name
│           ├── groupId         (which group this list belongs to)
│           ├── createdBy       (userId)
│           ├── createdByName   (username)
│           ├── createdAt
│           ├── isCompleted
│           └── items/          (items in this list)
│               └── {itemId}/
│                   ├── name
│                   ├── quantity
│                   ├── isBought
│                   ├── boughtBy (who marked it as bought)
│                   └── addedAt
│
└── {userId2}/
    └── ... (same structure)

groups/                          (ROOT LEVEL - shared between members)
├── {groupId1}/
│   ├── name
│   ├── members                 (email array: [user1@email, user2@email, ...])
│   ├── memberIds               (uid array: [uid1, uid2, ...])
│   ├── createdBy               (email of creator)
│   ├── createdByUid            (uid of creator)
│   └── createdAt
│
└── {groupId2}/
    └── ... (same structure)
```

## How Data Sharing Works

### Scenario: User 1 creates a group and adds User 2

1. **User 1 creates group "Groceries"**
   - Group created in `groups/groupId1`
   - `members: ["user1@email.com"]`
   - `memberIds: ["uid1"]`

2. **User 1 adds User 2 to the group**
   - Updates `groups/groupId1`
   - `members: ["user1@email.com", "user2@email.com"]`
   - `memberIds: ["uid1", "uid2"]`

3. **User 1 creates a list in the group**
   - List stored in `users/uid1/lists/listId1`
   - Contains `groupId: "groupId1"`
   - User 1 can see this list

4. **User 2 logs in**
   - Sees group "Groceries" because `uid2` is in `groups/groupId1/memberIds`
   - Gets User 1's lists because they're in the same group and can query by `groupId`
   - BUT each user only sees/edits their OWN lists in `users/{userId}/lists/`

5. **User 3 is NOT in the group**
   - Cannot see the group or any lists
   - Firestore rules prevent access

## Key Features

### 1. Shared Groups
- Groups exist at root level and are shared between members
- All members see the same group
- Only members can access the group

### 2. Private Lists
- Each user creates their own lists in `users/{userId}/lists/`
- Lists are filtered by group to show which lists are in which group
- Only the creator of a list can edit/delete it

### 3. User-Specific Activities
- Each user has their own activity log
- Activities are stored in `users/{userId}/userActivities/`
- Only that user can see their activities
- Activities can be deleted (swipe left)

### 4. Data Visibility
| Feature | User 1 | User 2 (Added to group) | User 3 (Not in group) |
|---------|--------|------------------------|-----------------------|
| See group? | ✅ Yes | ✅ Yes | ❌ No |
| See User 1's lists? | ✅ Yes | ✅ Yes | ❌ No |
| See User 2's lists? | ❌ No (unless User 2 created them) | ✅ Yes | ❌ No |
| Edit User 1's lists? | ✅ Yes (creator) | ❌ No | ❌ No |
| See group members? | ✅ Yes | ✅ Yes | ❌ No |

## Firestore Security Rules

The `firestore.rules` file enforces:

```
✅ Users can read/write ONLY their own user document and subcollections
✅ Users can read groups if their uid is in the memberIds array
✅ Users can only write to groups they're members of
✅ Authenticated users can read all user public info (for adding members)
❌ All other access is denied
```

## Database Operations

### Creating a Group
```dart
firestore.createGroup("Groceries")
// Creates in: groups/{groupId}
// Automatically adds current user as member
```

### Sharing a Group
```dart
firestore.addMemberSafe(groupId, "user2@email.com")
// Adds user2 to: groups/{groupId}/members and memberIds
// user2 can now see this group and User 1's lists in it
```

### Creating a List
```dart
firestore.createList("Weekly Groceries", groupId)
// Creates in: users/{currentUserId}/lists/{listId}
// Contains groupId reference so it shows in group
```

### Viewing Group Lists
```dart
firestore.getGroupLists(groupId)
// Returns only current user's lists where groupId matches
// Other members' lists are NOT included (each user's privacy)
```

## Testing User Isolation

**Test Case 1: Basic Sharing**
1. User A signs up, creates group "Groceries"
2. User A creates list "Weekly Shop"
3. User A adds User B
4. ✅ User B logs in and sees "Groceries" group
5. ✅ User B sees User A's "Weekly Shop" list
6. ✅ User C (not added) cannot see anything

**Test Case 2: Privacy**
1. User A creates list "Private List" in group
2. User B is in the group
3. ❌ User B CANNOT edit User A's list (only User A can)
4. ✅ User B CAN see the list and add items to it

**Test Case 3: Activity History**
1. User A creates/deletes items, logged in activities
2. ❌ User B CANNOT see User A's activity history
3. ✅ User B only sees their own activities

## Deploying Security Rules

```bash
firebase deploy --only firestore:rules
```

Or in Firebase Console:
1. Firestore Database → Rules
2. Copy contents of `firestore.rules`
3. Click Publish

## Benefits

✅ **Data Privacy**: Users see only accessible data  
✅ **Shared Collaboration**: Multiple users work in same groups  
✅ **Controlled Access**: Only added members can see groups  
✅ **Scalable**: Easy to add more features  
✅ **Deletable Activities**: Users can manage their history  

## Troubleshooting

**Groups not showing up?**
- Check if user is in memberIds array
- Verify security rules are deployed
- Check browser console for permission errors

**Can't see group members' lists?**
- Lists must be in the same group (groupId must match)
- Each user only sees their OWN lists
- This is by design for privacy

**Activity history not showing?**
- Activities are per-user, check correct user path
- Try refreshing the app
- Check Firestore Rules are deployed

