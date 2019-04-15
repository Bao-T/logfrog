import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Patrons {
  String _id;
  String _firstName;
  String _lastName;
  String _address;
  String _phone;
  String _notes;
  List<dynamic> _checkOutHistory;
  List<dynamic> _checkedOutEquipment;

  Patrons(this._id, this._firstName, this._lastName, this._address, this._phone, this._notes, this._checkOutHistory, this._checkedOutEquipment);

  //get methods to access private variables
  String get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get emailAddress => _address;
  String get phone => _phone;
  String get notes => _notes;
  List<DocumentReference> get checkOutHistory => _checkOutHistory;
  List<DocumentReference> get checkedOutEquipment => _checkedOutEquipment;

  Patrons.map(dynamic obj) {
    this._id = obj['id'];
    this._firstName = obj['firstName'];
    this._lastName = obj['lastName'];
    this._address = obj['emailAddress'];
    this._phone = obj['phone'];
    this._notes = obj['notes'];
    this._checkOutHistory = obj['checkOutHistory'];
    this._checkedOutEquipment = obj['checkedOutEquipment'];
  }

  static Map<String, dynamic> toMap(Patrons pat) {
    var map = new Map<String, dynamic>();
    if (pat._id != null) {
      map['id'] = pat._id;
    }
    map['firstName'] = pat._firstName;
    map['lastName'] = pat._lastName;
    map['emailAddress'] = pat._address;
    map['phone'] = pat._phone;
    map['notes'] = pat._notes;
    map['checkOutHistory'] = pat._checkOutHistory;
    map['checkedOutEquipment'] = pat._checkedOutEquipment;
    return map;
  }

  Patrons.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._firstName = map['firstName'];
    this._lastName = map['lastName'];
    this._address = map['emaileAddress'];
    this._phone = map['phone'];
    this._notes = map['notes'];
    this._checkOutHistory = map['checkOutHistory'];
    this._checkedOutEquipment = map['checkedOutEquipment'];
  }
}