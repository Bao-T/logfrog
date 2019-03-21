import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
//import 'dart:async';

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference


Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access


class Equipment {
  int id;
  String condition;
  List<DocumentReference> history;
  List<String> notes;
  DocumentReference reference;
  int barcode;
  int type;

  Equipment(this.id, this.condition, this.history, this.notes, this.reference, this.barcode, this.type);


  //  String get id => _id;
  //  String get title => _title;
  //  String get description => _description;


  int get thisId => id;
  String get thisCondition => condition;
  List<DocumentReference> get thisHistory => history;
  List<String> get thisNotes => notes;
  DocumentReference get thisReference => reference;
  int get thisBarcode => barcode;
  int get thisType => type;

  Equipment.map(dynamic obj) {
    this.id = obj['id'];
    this.condition = obj['condition'];
    this.history = obj['history'];
    this.notes = obj['notes'];
    this.reference = obj['reference'];
    this.barcode = obj['barcode'];
    this.type = obj['type'];
  }

  static Map<String, dynamic> toMap(Equipment equip) {
    var map = new Map<String, dynamic>();
    if (equip.id != null) {
      map['id'] = equip.id;
    }
    map['condition'] =  equip.condition;
    map['history'] = equip.history;
    map['notes'] = equip.notes;
    map['reference'] = equip.reference;
    map['barcode'] = equip.barcode;
    map['type'] = equip.type;
    return map;
  }


  Equipment.fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.condition = map['condition'];
    this.history = map['history'];
    this.notes = map['notes'];
    this.reference = map['reference'];
    this.barcode = map['barcode'];
    this.type = map['type'];
  }

}