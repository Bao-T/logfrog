import 'package:cloud_firestore/cloud_firestore.dart';


class Item {
  String condition; //item condition comments
  String itemID;
  String itemType; //Camera, Lights, etc.
  String name; //item name (unsure what will fill this?)
  String notes; //other notes
  String purchased;//
  bool status; // checkout status (true is checked in, false is checked out)
  int value; //value of object (for replacement costs if lost)

  //Default object creator
  Item(this.condition, this.itemID, this.itemType, this.name, this.notes, this.purchased, this.status, this.value);

  //creates history object mapping
  Item.map(dynamic obj) {
    this.condition = obj['condition'];
    this.itemID = obj['itemID'];
    this.itemType = obj['itemType'];
    this.name = obj['name'];
    this.notes = obj['notes'];
    this.purchased= obj['purchased'];
    this.status = obj['status'];
    this.value = obj['value'];
  }

  //creates a map from a object to store on firebase
  static Map<String, dynamic> toMap(Item item) {
    var map = new Map<String, dynamic>();
    if (item.itemID != "") { //if the string is not empty for item ID number
      map['itemID'] = item.itemID;
    }
    map['condition'] = item.condition;
    map['itemType'] = item.itemType;
    map['name'] = item.name;
    map['notes'] = item.notes;
    map['purchased'] = item.purchased;
    map['status'] = item.status;
    map['value'] = item.value;
    return map;
  }

  //creates a object from a map (how history objects will be created from those stored on firebase already)
  Item.fromMap(Map<String, dynamic> map) {
    this.itemID = map['itemID'];
    this.condition = map['condition'];
    //TODO:  finish this method
  }
}

