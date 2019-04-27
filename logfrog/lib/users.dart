//import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff

//Class for Users of logfrog, Users are connected to a site and will be logging on to the app itself

class Users {
  String _emailAddress;
  List<String> _databases;
  Users(this._emailAddress);

  //get methods for private variables
  String get emailAddress => _emailAddress;
  List<String> get databases => _databases;
  Users.map(dynamic obj) {
    this._emailAddress = obj['emailAddress'];
    this._databases = obj['databases'];
  }

  static Map<String, dynamic> toMap(Users usr) {
    var map = new Map<String, dynamic>();
    map['emailAddress'] = usr._emailAddress;
    map['databases'] = usr._databases;
    return map;
  }

  Users.fromMap(Map<String, dynamic> map) {
    this._emailAddress = map['emailAddress'];
    this._databases = map['databases'];
  }
}
