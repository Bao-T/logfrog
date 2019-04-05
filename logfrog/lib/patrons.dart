import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Patrons {
  int _id;
  String _firstName;
  String _lastName;
  String _emailAddress;
  String _username;
  String _password;
  List<DocumentReference> _checkOutHistory;
  List<DocumentReference> _checkedOutEquipment;

  Patrons(this._id, this._firstName, this._lastName, this._emailAddress, this._username, this._password, this._checkOutHistory, this._checkedOutEquipment);

  //get methods to access private variables
  int get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get emailAddress => _emailAddress;
  String get username => _username;
  String get password => _password;
  List<DocumentReference> get checkOutHistory => _checkOutHistory;
  List<DocumentReference> get checkedOutEquipment => _checkedOutEquipment;

  Patrons.map(dynamic obj) {
    this._id = obj['id'];
    this._firstName = obj['firstName'];
    this._lastName = obj['lastName'];
    this._emailAddress = obj['emailAddress'];
    this._username = obj['username'];
    this._password = obj['password'];
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
    map['emailAddress'] = pat._emailAddress;
    map['username'] = pat._username;
    map['password'] = pat._password;
    map['checkOutHistory'] = pat._checkOutHistory;
    map['checkedOutEquipment'] = pat._checkedOutEquipment;
    return map;
  }

  Patrons.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._firstName = map['firstName'];
    this._lastName = map['lastName'];
    this._emailAddress = map['emaileAddress'];
    this._username = map['username'];
    this._password = map['password'];
    this._checkOutHistory = map['checkOutHistory'];
    this._checkedOutEquipment = map['checkedOutEquipment'];
  }
}