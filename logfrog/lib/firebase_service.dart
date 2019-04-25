import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/equipment.dart';
import 'package:logfrog/users.dart';
import 'package:logfrog/patrons.dart';
import 'package:logfrog/history.dart';

final CollectionReference equipmentCollection =
    Firestore.instance.collection('Objects');
final CollectionReference usersCollection =
    Firestore.instance.collection('Users');


/*
Firebase structure:

1) Objects (AKA Sites)------/History
                            Items (AKA Equipment)
                            Members (AKA Patron)

2) Users -- TODO - update updatePatrons to reflect this structure.
 */



//Class for pushing and pulling app data from Firebase database

class FirebaseFirestoreService {
  //Setup class stuff from tutorial
  //https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference

  //One variable for the FirebaseFirestoreService class, site name (will be associated with user login)
  String site;

  //
  FirebaseFirestoreService(String site) {
    this.site = site;
  }

  //Returns stream of snapshots for items collection (owned by a site)
  Stream<QuerySnapshot> getItems() {
    Stream<QuerySnapshot> snapshots =
        equipmentCollection.document(site).collection("Items").snapshots();
    return snapshots;
  }

  //Returns stream of snapshots for members collection (owned by a site)
  Stream<QuerySnapshot> getMembers() {
    Stream<QuerySnapshot> snapshots =
        equipmentCollection.document(site).collection("Members").snapshots();
    return snapshots;
  }

  //create an equipment asynchronously
  //input of Equipment type map
  Future<Equipment> createEquipment(
      {String name,
      String itemID,
      String itemType,
      DateTime purchased,
      String status,
      String condition,
      String notes}) async {
    final TransactionHandler createTransaction = (Transaction tx) async { //creating firestore transaction
      DocumentSnapshot ds;
      if (itemID != "") { //Default itemID is "" ????
        ds = await tx.get(equipmentCollection
            .document(site)
            .collection("Items")
            .document(itemID));
      } else {
        ds = await tx.get(
            equipmentCollection.document(site).collection("Items").document()); //Note that the Equipment class is named 'Items' in collections
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
      await tx.set(ds.reference, dataMap); //set data map to the reference for the transaction
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
          throw ("error: Item ID already exists"); //error for pre-created items being re-created
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

  //create a Patron (AKA a member) asynch
  //input of patron class mapping
  Future<Patrons> createPatron(
      {  String id,
      String firstName,
      String lastName,
      String address,
      String phone,
      String notes,}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (id != "") {
        ds = await tx.get(equipmentCollection
            .document(site)
            .collection("Members")
            .document(id));
      } else {
        ds = await tx.get(equipmentCollection.document(site).collection("Members").document());
        id = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
      dataMap['id'] = id;
      dataMap['firstName'] = firstName;
      dataMap['lastName'] = lastName;
      dataMap['emailAddress'] = address;
      dataMap['phone'] = phone;
      dataMap['notes'] = notes;
      dataMap['checkOutHistory'] = List();
      dataMap['checkedOutEquipment'] = List();
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (id != "") {
      return equipmentCollection
          .document(site)
          .collection("Members")
          .document(id)
          .get()
          .then((doc) {
        if (doc.exists) {
          throw ("error: Item ID already exists");
        } else {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Patrons.fromMap(mapData);
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
        return Patrons.fromMap(mapData);
      }).catchError((error) {
        throw ('error: unable to communicate with server');
      });
    }
  }

  //Create a user object and send to firebase
  //User == Teacher or those who login to app
  Future<Users> createUser(
      { String id,
        String firstName,
        String lastName,
        String emailAddress,
        String username,
        String password,}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (id != "") {
        ds = await tx.get(usersCollection.document(id));
      } else {
        ds = await tx.get(usersCollection.document(id));
        id = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
      dataMap['id'] = id;
      dataMap['firstName'] = firstName;
      dataMap['lastName'] = lastName;
      dataMap['emailAddress'] = emailAddress;
      dataMap['username'] = username;
      dataMap['password'] = password;
      await tx.set(ds.reference, dataMap);
      return dataMap;

    };
    if (id != "") {
    return usersCollection.document(id).get().then((doc) {
      if (doc.exists){
        throw ("error: Item ID already exists");
      } else {
        return Firestore.instance.runTransaction(createTransaction).then((mapData) {
          return Users.fromMap(mapData);
        }).catchError((error) {
          throw ('error: unable to communicate with server');
        });
      }
    }).catchError((e){
      throw (e);
    });
    } else {
      return Firestore.instance.runTransaction(createTransaction).then((mapData){
        return Users.fromMap(mapData);
      }).catchError((error) {
        throw ('error: unable to communicate with server');
      });
    }
  }

  //Creates a History object given a patron id and a equipment id
  Future<History> createHistory (
      {String historyID,
        String itemID,
        String itemName,
        String memID,
        String memName,
        Timestamp timeCheckedIn,
        Timestamp timeCheckedOut }) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (historyID != ""){
        ds = await tx.get(equipmentCollection.document(site).collection("History").document(historyID));
      } else {
        ds = await tx.get(equipmentCollection.document(site).collection("History").document());
        historyID = ds.documentID;
      }
      var dataMap = new Map<String, dynamic>();
      dataMap['historyID'] = historyID;
      dataMap['itemID'] = itemID;
      dataMap['itemName'] = itemName;
      dataMap['memID'] = memID;
      dataMap['memName'] = memName;
      dataMap['timeCheckedIn'] = timeCheckedIn;
      dataMap['timeCheckedOut'] = timeCheckedOut;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (historyID != "") {
      return equipmentCollection.document(site).collection("History").document(historyID).get().then((doc) {
        if (doc.exists){
          throw ("error: Item ID already exists");
        } else {
          return Firestore.instance.runTransaction(createTransaction).then((mapData) {
            return History.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        }
      }).catchError((e){
        throw (e);
      });
    } else {
      return Firestore.instance.runTransaction(createTransaction).then((mapData){
        return History.fromMap(mapData);
      }).catchError((error) {
        throw ('error: unable to communicate with server');
      });
    }
  }


  Future<dynamic> updateEquipment(
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
            equipmentCollection.document(site).collection("Items").document()); //Note that Equipment was changed to 'Items'
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
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Equipment.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        } else {
          throw ('error: could not find matching item');
        }
      }).catchError((e) {
        throw (e);
      });
    } else {
       throw ("error: Item ID is required to update");
    }
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

  Future<dynamic> updateHistory(
      String historyID, //History ID (autogenerated)
      String itemID, //id of item being checked out
      String itemName, //name of item being checked out /in
      String memID, //member checking in/out
      String memName, //name of member checking in/out
      //String _username; //_username of member checking in/out
      Timestamp timeCheckedOut,//may or may not break horribly??? if so, could use this fix: https://stackoverflow.com/questions/52996707/flutter-app-error-type-timestamp-is-not-a-subtype-of-type-datetime
      Timestamp timeCheckedIn //default of same as checked out timestamp initially (so if they are the same time, the item is not checked back in)}
  ) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (historyID != "") {
        ds = await tx.get(equipmentCollection
            .document(site)
            .collection("History") //TODO:update this to reflect current structure
            .document(historyID));
      } else {
        ds = await tx.get(
            equipmentCollection.document(site).collection("History").document());//TODO:update this to reflect current structure
        historyID = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
      dataMap['historyID'] = historyID;
      dataMap['itemID'] = itemID;
      dataMap['itemName'] = itemName;
      dataMap['memID'] = memID;
      dataMap['memName'] = memName;
      dataMap['timeCheckedOut'] = timeCheckedOut;
      dataMap['timeCheckedIn'] = timeCheckedIn;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (historyID != "") {
      return equipmentCollection //TODO:update this to reflect current structure
          .document(site)
          .collection("Items") //TODO:update this to reflect current structure
          .document(historyID) //TODO:update this to reflect current structure
          .get()
          .then((doc) {
        if (doc.exists) {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Equipment.fromMap(mapData); //TODO:update this to reflect current structure
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        } else {
          throw ('error: could not find matching item');
        }
      }).catchError((e) {
        throw (e);
      });
    } else {
      throw ("error: History ID is required to update");
    }
  }

  Future<dynamic> updatePatrons(
        String id, //student id
        String firstName, //student first name
        String lastName, //student last name
        String address, //student address
        String phone, //student phone number
        String notes, //extra notes to be entered
        List<dynamic> checkOutHistory, //list of recent checkOutHistory objects associated with
        List<dynamic> checkedOutEquipment //list of currently checked out equipment //default of same as checked out timestamp initially (so if they are the same time, the item is not checked back in)}
      ) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (id != "") {
        ds = await tx.get(equipmentCollection
            .document(site)
            .collection("Users") //TODO:update this to reflect current structure
            .document(id));
      } else {
        ds = await tx.get(
            equipmentCollection.document(site).collection("Users").document()); //TODO:update this to reflect current structure
        id = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
          dataMap['id'] = id;
      dataMap['firstName'] = firstName;
      dataMap['lastName'] = lastName;
      dataMap['emailAddress'] = address;
      dataMap['phone'] = phone;
      dataMap['notes'] = notes;
      dataMap['checkOutHistory'] = checkOutHistory;
      dataMap['checkedOutEquipment'] = checkedOutEquipment;
      return dataMap;
    };
    if (id != "") {
      return equipmentCollection //TODO:update this to reflect current structure
          .document(site)
          .collection("Patrons")
          .document(id)
          .get()
          .then((doc) {
        if (doc.exists) {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Equipment.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        } else {
          throw ('error: could not find matching item');
        }
      }).catchError((e) {
        throw (e);
      });
    } else {
      throw ("error: Patron ID is required to update");
    }
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

  Future<dynamic> deleteHistory(int id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds =
      await tx.get(.document(id.toString()));

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
