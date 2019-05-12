import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/equipment.dart';
import 'package:logfrog/users.dart';
import 'package:logfrog/patrons.dart';
import 'package:logfrog/history.dart';

final CollectionReference objectCollection =
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
        objectCollection.document(site).collection("Items").snapshots();
    return snapshots;
  }

  //Returns stream of snapshots for members collection (owned by a site)
  Stream<QuerySnapshot> getMembers() {
    Stream<QuerySnapshot> snapshots =
        objectCollection.document(site).collection("Members").snapshots();
    return snapshots;
  }

  Stream<QuerySnapshot> getMemberHistory(String memID) {
    Stream<QuerySnapshot> snapshots = objectCollection
        .document(site)
        .collection("History")
        .where("memID", isEqualTo: memID)
        .snapshots();
    return snapshots;
  }

  Stream<QuerySnapshot> getHistories() {
    Stream<QuerySnapshot> snapshots = objectCollection
        .document(site)
        .collection("History")
        .orderBy("timeCheckedOut", descending: true)
        .snapshots();
    return snapshots;
  }

  Stream<QuerySnapshot> getItemsQuery(
      String itemType, String status, String sortBy, bool desc) {
    Query docs = objectCollection.document(site).collection("Items");
    if (itemType != "") {
      docs = docs.where("ItemType", isEqualTo: itemType);
      print("Type");
    }
    if (status != "") {
      docs = docs.where("Status", isEqualTo: status);
      print("Status");
    }
    if (sortBy != "" && desc != null) {
      docs = docs.orderBy(sortBy, descending: desc);
      print("Sort");
    }
    print("here");
    return docs.snapshots();
  }

  //create an equipment asynchronously
  //input of Equipment type map
  Future<Equipment> createEquipment(
      {String name,
      String itemID,
      String itemType,
      Timestamp purchased,
      String status,
      String condition,
      String notes}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      //creating firestore transaction
      print(site);
      DocumentSnapshot ds;
      if (itemID != "") {
        //Default itemID is "" ????
        ds = await tx.get(objectCollection
            .document(site)
            .collection("Items")
            .document(itemID));
      } else {
        ds = await tx.get(objectCollection
            .document(site)
            .collection("Items")
            .document()); //Note that the Equipment class is named 'Items' in collections
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
      await tx.set(ds.reference,
          dataMap); //set data map to the reference for the transaction
      return dataMap;
    };
    if (itemID != "") {
      return objectCollection
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
  Future<Patrons> createPatron({
    String id,
    String firstName,
    String lastName,
    String address,
    String phone,
    String notes,
  }) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (id != "") {
        ds = await tx.get(
            objectCollection.document(site).collection("Members").document(id));
      } else {
        ds = await tx.get(
            objectCollection.document(site).collection("Members").document());
        id = ds.documentID;
      }

      var dataMap = new Map<String, dynamic>();
      dataMap['id'] = id;
      dataMap['firstName'] = firstName;
      dataMap['lastName'] = lastName;
      dataMap['emailAddress'] = address;
      dataMap['phone'] = phone;
      dataMap['notes'] = notes;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (id != "") {
      return objectCollection
          .document(site)
          .collection("Members")
          .document(id)
          .get()
          .then((doc) {
        if (doc.exists) {
          throw ("error: Item ID already exists");
        } else { //TODO:  add extra id check for items having the id checks
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
  Future<Users> createUser({
    String id,
    String emailAddress,
    List<String> databases,
    int checkoutPeriod,
  }) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      ds = await tx.get(usersCollection.document(id));

      var dataMap = new Map<String, dynamic>();
      dataMap['emailAddress'] = emailAddress;
      dataMap['databases'] = databases;
      dataMap['checkoutPeriod'] = checkoutPeriod;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return usersCollection.document(id).get().then((doc) {
      if (doc.exists) {
        //throw ("error: Item ID already exists");
      } else {
        return Firestore.instance
            .runTransaction(createTransaction)
            .then((mapData) {
          return Users.fromMap(mapData);
        }).catchError((error) {
          throw ('error: unable to communicate with server');
        });
      }
    }).catchError((e) {
      throw (e);
    });
  }

  //Creates a History object given a patron id and a equipment id
  Future<History> createHistory(
      {String itemID,
      String itemName,
      String memID,
      String memName,
      Timestamp timeCheckedIn,
      Timestamp timeCheckedOut}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      ds = await tx.get(
          objectCollection.document(site).collection("History").document());

      var dataMap = new Map<String, dynamic>();
      dataMap['itemID'] = itemID;
      dataMap['itemName'] = itemName;
      dataMap['memID'] = memID;
      dataMap['memName'] = memName;
      dataMap['timeCheckedIn'] = timeCheckedIn;
      dataMap['timeCheckedOut'] = timeCheckedOut;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return History.fromMap(mapData);
    }).catchError((error) {
      throw ('error: unable to communicate with server');
    });
  }

  Future<dynamic> updateEquipment(
      {String name,
      String itemID,
      String itemType,
      Timestamp purchased,
      String status,
      String condition,
      String notes}) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (itemID != "") {
        ds = await tx.get(objectCollection
            .document(site)
            .collection("Items")
            .document(itemID));
      } else {
        ds = await tx.get(objectCollection
            .document(site)
            .collection("Items")
            .document()); //Note that Equipment was changed to 'Items'
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
      return objectCollection
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

//  Future<dynamic> updateUsers(Users usr) async {
//    final TransactionHandler updateTransaction = (Transaction tx) async {
//      String idGet = usr.id.toString();
//      final DocumentSnapshot ds = await tx.get(usersCollection.document(idGet));
//      await tx.update(ds.reference, Users.toMap(usr));
//      return {'updated': true};
//    };
//
//    return Firestore.instance
//        .runTransaction(updateTransaction)
//        .then((result) => result['updated'])
//        .catchError((error) {
//      print('error: $error');
//      return false;
//    });
//  }

  Future<dynamic> updateHistory(
      String historyID, //History ID (autogenerated)
      String itemID, //id of item being checked out
      String itemName, //name of item being checked out /in
      String memID, //member checking in/out
      String memName, //name of member checking in/out
      //String _username; //_username of member checking in/out
      Timestamp
          timeCheckedOut, //may or may not break horribly??? if so, could use this fix: https://stackoverflow.com/questions/52996707/flutter-app-error-type-timestamp-is-not-a-subtype-of-type-datetime
      Timestamp
          timeCheckedIn //default of same as checked out timestamp initially (so if they are the same time, the item is not checked back in)}
      ) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      if (historyID != "") {
        ds = await tx.get(objectCollection
            .document(site)
            .collection("History")
            .document(historyID));
      } else {
        ds = await tx.get(
            objectCollection.document(site).collection("History").document());
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
      return objectCollection
          .document(site)
          .collection("History")
          .document(historyID)
          .get()
          .then((doc) {
        if (doc.exists) {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return History.fromMap(
                mapData); //TODO:update this to reflect current structure
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        } else {
          throw ('error: could not find matching history');
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
  ) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      DocumentSnapshot ds;
      ds = await tx.get(
          objectCollection.document(site).collection("Members").document(id));
      var dataMap = new Map<String, dynamic>();
      dataMap['id'] = id;
      dataMap['firstName'] = firstName;
      dataMap['lastName'] = lastName;
      dataMap['emailAddress'] = address;
      dataMap['phone'] = phone;
      dataMap['notes'] = notes;
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    if (id != "") {
      return objectCollection
          .document(site)
          .collection("Members")
          .document(id)
          .get()
          .then((doc) {
        if (doc.exists) {
          return Firestore.instance
              .runTransaction(createTransaction)
              .then((mapData) {
            return Patrons.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        } else {
          throw ('error: could not find matching user');
        }
      }).catchError((e) {
        throw (e);
      });
    } else {
      throw ("error: User ID is required to update");
    }
  }

  Future<dynamic> deleteEquipment(String id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(
          objectCollection.document(site).collection("Items").document(id));
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
  Future<dynamic> deletePatron(String id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(
          objectCollection.document(site).collection("Members").document(id));
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

  Future<Patrons> getPatron(String barcodeIn) async {
    Patrons p;
    await objectCollection
        .document(site)
        .collection("Members")
        .document(barcodeIn)
        .get()
        .then((doc) {
      if (doc.exists) {
        p = Patrons.fromMap(doc.data);
      }
    });
    return p;
  }

  //Fuction for checkin and checkout
  //Checks if a barcode coming in is a student ID
  //returns true if it is, false if not
  Future<bool> patronExists(String barcodeIn) async {
    bool passes = false;
    //check if barcode in students using solution adapted from:
    //https://www.queryxchange.com/q/27_37397205/google-firebase-check-if-child-exists/ (accessed 4/24/19)
    //https://stackoverflow.com/questions/38948905/how-can-i-check-if-a-value-exists-already-in-a-firebase-data-class-android
    await objectCollection
        .document(site)
        .collection("Members")
        .document(barcodeIn)
        .get()
        .then((doc) {
      if (doc.exists) {
        passes = true;
      }
    });
    return passes;
  }

  //For use in livecamera.dart, checks if a given equipment id exists (use before equipmentNotCheckedOut check to avoid pulling data and generating a Equipment member)
  Future<bool> equipmentExists(String barcodeIn) async {
    bool exists = false;
    await objectCollection
        .document(site)
        .collection("Items")
        .document(barcodeIn)
        .get()
        .then((doc) {
      if (doc.exists) {
        exists = true;
      }
    });
    return exists;
  }

  //function which checks if a item is currently checked in or currently checked out for a scanned item barcode in liveCamera.dart
  //true = is checked in and can be checked out
  //false = is checked out and was not checked back in OR is not in the system
  //TODO: Add popups for the two cases to prompt a) scanning item back in to check out or b) entering item in database
  Future<bool> equipmentNotCheckedOut(String barcodeIn) async {
    bool canBeCheckedOut = false;
    await objectCollection
        .document(site)
        .collection("Items")
        .document(barcodeIn)
        .get()
        .then((doc) {
      if (doc.exists) {
        //document exists, and we have the doc data.
        Equipment dummyEquip = Equipment.fromMap(
            doc.data); //should fill in equipment dummy with jason map
        if (dummyEquip.status.toLowerCase() == "available") {
          canBeCheckedOut = true; //Is
        } else {
          canBeCheckedOut = false; //is "CheckedOut", cannot check out item
        }
      }
    });
    return canBeCheckedOut;
  }

  Future<dynamic> deleteHistory(int id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      //final DocumentSnapshot ds = await tx.get(.document(id.toString()));

      //await tx.delete(ds.reference);
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

  Future<void> updateItemTypes(String newItemType) async {
//    final DocumentReference doc = objectCollection.document(site);
//    try {
//      Firestore.instance.runTransaction((Transaction tx) async {
//      DocumentSnapshot docSnapshot = await tx.get(doc).then(onValue);
//      if (docSnapshot.exists) {
//        List<String> itemTypes = docSnapshot["ItemTypes"];
//        if (!itemTypes.contains(newItemType)) {
//          print("here");
//          await tx.update(doc,
//              <String, dynamic>{
//                'ItemTypes': docSnapshot.data['ItemTyps'] + newItemType
//              });
//        }
//      }
//      });
//    } catch (e) {print(e.toString());}
    final DocumentReference postRef = objectCollection.document(site);

    Firestore.instance.runTransaction((Transaction tx) async {
      try {
        DocumentSnapshot postSnapshot = await tx.get(postRef);
        if (postSnapshot.exists) {
          if (!postSnapshot.data.containsKey('ItemTypes')) {
            print("here");
            await tx.set(postRef, <String, dynamic>{
              'ItemTypes': [newItemType]
            });
            postSnapshot = await tx.get(postRef);
          } else if (postSnapshot.data.containsKey('ItemTypes')) {
            if (!postSnapshot.data['ItemTypes'].contains(newItemType)) {
              await tx.update(postRef, <String, dynamic>{
                'ItemTypes': postSnapshot.data['ItemTypes'] + [newItemType]
              });
            }
          }
        }
      } catch (e) {
        print(e.toString());
      }
    });
  }
}
