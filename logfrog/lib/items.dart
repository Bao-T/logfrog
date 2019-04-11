import 'package:cloud_firestore/cloud_firestore.dart';


class Item {
  String _condition; //item _condition comments
  String _itemID;
  String _itemType; //Camera, Lights, etc.
  String _name; //item _name (unsure what will fill this?)
  String _notes; //other _notes
  String _purchased;//
  bool _status; // checkout _status (true is checked in, false is checked out)
  int _value; //_value of object (for replacement costs if lost)

  //Default object creator
  Item(this._condition, this._itemID, this._itemType, this._name, this._notes, this._purchased, this._status, this._value);

  //get methods to access the private variables
  String get condition => _condition;
  String get itemID => _itemID;
  String get itemType => _itemType;
  String get name => _name;
  String get notes => _notes;
  String get purchased => _purchased;
  bool get status => _status;
  int get value => _value;

  //creates history object mapping
  Item.map(dynamic obj) {
    this._condition = obj['condition'];
    this._itemID = obj['itemID'];
    this._itemType = obj['itemType'];
    this._name = obj['name'];
    this._notes = obj['notes'];
    this._purchased= obj['purchased'];
    this._status = obj['status'];
    this._value = obj['value'];
  }

  //creates a map from a object to store on firebase
  static Map<String, dynamic> toMap(Item item) {
    var map = new Map<String, dynamic>();
    if (item._itemID != "") { //if the string is not empty for item ID number
      map['itemID'] = item._itemID;
    }
    map['condition'] = item._condition;
    map['itemType'] = item._itemType;
    map['name'] = item._name;
    map['notes'] = item._notes;
    map['purchased'] = item._purchased;
    map['status'] = item._status;
    map['value'] = item._value;
    return map;
  }

  //creates a object from a map (how history objects will be created from those stored on firebase already)
  Item.fromMap(Map<String, dynamic> map) {
    this._itemID = map['itemID'];
    this._condition = map['condition'];
    this._itemType = map['itemType'];
    this._name = map['name'];
    this._notes = map['notes'];
    this._purchased = map['purchased'];
    this._status = map['status'];
    this._value = map['value'];
  }
}

