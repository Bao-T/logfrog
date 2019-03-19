import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/equipment.dart';
import 'package:logfrog/users.dart';
import 'package:logfrog/patrons.dart';

final CollectionReference equipmentCollection = Firestore.instance.collection('Equipment');
final CollectionReference usersCollection = Firestore.instance.collection('Users');
final CollectionReference patronsCollection = Firestore.instance.collection('Patrons');

class FirebaseFirestoreService {
  //Setup class stuff from tutorial
  //https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference

  static final FirebaseFirestoreService _instance = new FirebaseFirestoreService.internal();
  factory FirebaseFirestoreService() => _instance;
  FirebaseFirestoreService.internal();


  Future<Equipment> createEquipment(String title, String description) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(db.collection('Equipment').document());
      var dataMap = new Map<String, dynamic>();
      dataMap['title'] = 'title';
      dataMap['description'] = 'description';
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData)
    {
      return Equipment.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<Users> createUser(String title, String description) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(db.collection('Users').document());
      var dataMap = new Map<String, dynamic>();
      dataMap['title'] = 'title';
      dataMap['description'] = 'description';
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData)
    {
      return Users.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<Patrons> createPatron(String title, String description) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(db.collection('Patron').document());
      var dataMap = new Map<String, dynamic>();
      dataMap['title'] = 'title';
      dataMap['description'] = 'description';
      await tx.set(ds.reference, dataMap);
      return dataMap;
    };
    return Firestore.instance.runTransaction(createTransaction).then((mapData)
    {
      return Patrons.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }



}

