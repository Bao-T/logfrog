//import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Users {
  int _id;
  String _firstName;
  String _lastName;
  String _emailAddress;
  String _username;
  String _password;

  Users(this._id, this._firstName, this._lastName, this._emailAddress, this._username, this._password);

  //get methods for private variables
  int get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get emailAddress => _emailAddress;
  String get username => _username;
  String get password => _password;


  Users.map(dynamic obj) {
    this._id = obj['id'];
    this._firstName = obj['firstName'];
    this._lastName = obj['lastName'];
    this._emailAddress = obj['emailAddress'];
    this._username = obj['username'];
    this._password = obj['password'];
  }

  static Map<String, dynamic> toMap(Users usr) {
    var map = new Map<String, dynamic>();
    if (usr._id != null) {
      map['_id'] = usr._id;
    }
    map['firstName'] = usr._firstName;
    map['lastName'] = usr._lastName;
    map['emailAddress'] = usr._emailAddress;
    map['username'] = usr._username;
    map['password'] = usr._password;
    return map;
  }

  Users.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._firstName = map['firstName'];
    this._lastName = map['_lastName'];
    this._emailAddress = map['emailAddress'];
    this._username = map['username'];
    this._password = map['password'];
  }
}