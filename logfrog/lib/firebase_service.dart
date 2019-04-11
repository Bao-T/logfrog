import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/equipment.dart';
import 'package:logfrog/users.dart';
import 'package:logfrog/patrons.dart';

final CollectionReference equipmentCollection =
    Firestore.instance.collection('Objects');
final CollectionReference usersCollection =
    Firestore.instance.collection('Users');

class FirebaseFirestoreService {
  //Setup class stuff from tutorial
  //https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference

  /*static final FirebaseFirestoreService _instance =
      new FirebaseFirestoreService.internal();
  factory FirebaseFirestoreService() => _instance;
  FirebaseFirestoreService.internal();
  */
  String site;

  FirebaseFirestoreService(String site) {
    this.site = site;
  }

  Stream<QuerySnapshot> getItems() {
    Stream<QuerySnapshot> snapshots =
        equipmentCollection.document(site).collection("Items").snapshots();

    /*
    if (offset != null) {
      snapshots = snapshots.skip(offset);
    }

    if (limit != null) {
      snapshots = snapshots.take(limit);
    }
  */
    return snapshots;
  }

  Stream<QuerySnapshot> getMembers() {
    Stream<QuerySnapshot> snapshots =
        equipmentCollection.document(site).collection("Members").snapshots();

    /*
    if (offset != null) {
      snapshots = snapshots.skip(offset);
    }

    if (limit != null) {
      snapshots = snapshots.take(limit);
    }
  */
    return snapshots;
  }

  Future<Equipment> createEquipment(
      {String name,
      String itemID,
      String itemType,
      DateTime purchased,
      String status,
      String condition,
      String notes}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (itemID != "") {
        ds = await tx.get(equipmentCollection
            .document(site)
            .collection("Items")
            .document(itemID));
      } else {
        ds = await tx.get(
            equipmentCollection.document(site).collection("Items").document());
        itemID = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
      dataMap['Condition'] = condition;
      dataMap['ItemID'] = itemID;
      dataMap['ItemType'] = itemType;
      dataMap['Name'] = name;
      dataMap['Notes'] = notes;
      dataMap['Purchased'] = purchased;
      dataMap['Status'] = status;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (itemID != "") {
      return equipmentCollection
          .document(site)
          .collection("Items")
          .document(itemID)
          .get()
          .then((doc) {
        if (doc.exists) {
          print("DNE");
          throw ("error: Item ID already exists");
        } else {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Equipment.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        }
      }).catchError((e) {
        throw (e);
      });
    } else {
      return Firestore.instance
          .runTransaction(createTransaction)
          .then((mapData) {
        return Equipment.fromMap(mapData);
      }).catchError((error) {
        throw ('error: unable to communicate with server');
      });
    }
  }

  Future<Users> createMember(
      {String firstname,
      String lastname,
      String memID,
      String address,
      String phone,
      String notes}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(
          equipmentCollection.document(site).collection("Members").document());
      var dataMap = new Map<String, dynamic>();
      dataMap['Address'] = address;
      dataMap['FirstName'] = firstname;
      dataMap['LastName'] = lastname;
      dataMap['MemID'] = memID;
      dataMap['Phone'] = phone;
      dataMap['Notes'] = notes;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return Users.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<Users> createUser(String title, String description) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds =
          await tx.get(db.collection('Users').document());
      var dataMap = new Map<String, dynamic>();
      dataMap['title'] = 'title';
      dataMap['description'] = 'description';
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return Users.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<dynamic> updateEquipment(Equipment equipment) async {
    final TransactionHandler updateTransaction = (Transaction tx) async {

      String idGet = equipment.itemID.toString();
      final DocumentSnapshot ds = await tx.get(equipmentCollection.document(idGet));

      await tx.update(ds.reference, Equipment.toMap(equipment));
      return {'updated': true};
    };

    return Firestore.instance
        .runTransaction(updateTransaction)
        .then((result) => result['updated'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }

  Future<dynamic> updateUsers(Users usr) async {
    final TransactionHandler updateTransaction = (Transaction tx) async {
      String idGet = usr.id.toString();
      final DocumentSnapshot ds = await tx.get(usersCollection.document(idGet));
      await tx.update(ds.reference, Users.toMap(usr));
      return {'updated': true};
    };

    return Firestore.instance
        .runTransaction(updateTransaction)
        .then((result) => result['updated'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }

  Future<dynamic> deleteEquipment(int id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds =
          await tx.get(equipmentCollection.document(id.toString()));

      await tx.delete(ds.reference);
      return {'deleted': true};
    };

    return Firestore.instance
        .runTransaction(deleteTransaction)
        .then((result) => result['deleted'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }

  Future<dynamic> deleteUsers(int id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds =
          await tx.get(usersCollection.document(id.toString()));

      await tx.delete(ds.reference);
      return {'deleted': true};
    };

    return Firestore.instance
        .runTransaction(deleteTransaction)
        .then((result) => result['deleted'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }
}
