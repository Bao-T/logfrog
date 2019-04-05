import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
//import 'dart:async';

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference


Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access


class Equipment {
  String _condition;
  String _itemID;
  String _itemType;
  String _name;
  String _notes;
  String _purchased;
  String _status;

  Equipment(this._condition, this._itemID, this._itemType, this._name, this._notes, this._purchased, this._status);


  //  String get id => _id;
  //  String get title => _title;
  //  String get description => _description;

  //get functions to access private variables
  String get itemID => _itemID;
  String get condition => _condition;
  String get notes => _notes;
  String get itemType => _itemType;
  String get name => _name;
  String get purchased => _purchased;
  String get status => _status;

  Equipment.map(dynamic obj) {
//    this.id = obj['id'];
//    this._condition = obj['_condition'];
//    this.history = obj['history'];
//    this._notes = obj['_notes'];
//    this.reference = obj['reference'];
//    this.barcode = obj['barcode'];
//    this.type = obj['type'];
  }

  static Map<String, dynamic> toMap(Equipment equip) {
    var map = new Map<String, dynamic>();
    map['condition'] = equip._condition;
    map['itemID'] = equip._itemID;
    map['itemType'] = equip._itemType;
    map['name'] = equip._name;
    map['notes'] = equip._notes;
    map['purchased'] = equip._purchased;
    map['status'] = equip._status;
    return map;
  }


  Equipment.fromMap(Map<String, dynamic> dataMap) {
    this._condition =  dataMap['condition'];
    this._itemID=  dataMap['itemID'];
    this._itemType  =dataMap['itemType'];
    this._name =dataMap['name'];
    this._notes= dataMap['notes'];
    this._purchased = dataMap['purchased'];
    this._status =dataMap['status'];








  }

}