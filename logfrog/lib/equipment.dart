import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
//import 'dart:async';

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference


Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access


class Equipment {
  String condition, itemId, itemType, name, notes, purchased, status;

  Equipment(this.condition, this.itemId, this.itemType, this.name, this.notes, this.purchased, this.status);


  //  String get id => _id;
  //  String get title => _title;
  //  String get description => _description;


  String get thisId => itemId;
  String get thisCondition => condition;
  String get thisNotes => notes;
  String get thisType => itemType;
  String get thisName => name;
  String get thisPurchased => purchased;
  String get thisStatus => status;

  Equipment.map(dynamic obj) {
//    this.id = obj['id'];
//    this.condition = obj['condition'];
//    this.history = obj['history'];
//    this.notes = obj['notes'];
//    this.reference = obj['reference'];
//    this.barcode = obj['barcode'];
//    this.type = obj['type'];
  }

  static Map<String, dynamic> toMap(Equipment equip) {
    var map = new Map<String, dynamic>();
    map['Condition'] = equip.condition;
    map['ItemID'] = equip.itemId;
    map['ItemType'] = equip.itemType;
    map['Name'] = equip.name;
    map['Notes'] = equip.notes;
    map['Purchased'] = equip.purchased;
    map['Status'] = equip.status;
    return map;
  }


  Equipment.fromMap(Map<String, dynamic> dataMap) {
    this.condition =  dataMap['Condition'];
    this.itemId=  dataMap['ItemID'];
    this.itemType  =dataMap['ItemType'];
    this.name =dataMap['Name'];
    this.notes= dataMap['Notes'];
    this.purchased = dataMap['Purchased'];
    this.status =dataMap['Status'];








  }

}