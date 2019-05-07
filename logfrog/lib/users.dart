//import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff

//Class for Users of logfrog, Users are connected to a site and will be logging on to the app itself

class Users {
  String _emailAddress; //email adress of user, used for login
  List<String> _databases; //databases connected with user
  int _checkoutPeriod; //allowed length of time for item checkout (int of days allowed)

  Users(this._emailAddress, this._checkoutPeriod);


  //get methods for private variables
  String get emailAddress => _emailAddress;
  List<String> get databases => _databases;
  int get checkoutPeriod => _checkoutPeriod;

  Users.map(dynamic obj) {
    this._emailAddress = obj['emailAddress'];
    this._databases = obj['databases'];
    this._checkoutPeriod = obj['checkoutPeriod'];
  }

  static Map<String, dynamic> toMap(Users usr) {
    var map = new Map<String, dynamic>();
    map['emailAddress'] = usr._emailAddress;
    map['databases'] = usr._databases;
    map['checkoutPeriod'] = usr._checkoutPeriod;
    return map;
  }

  Users.fromMap(Map<String, dynamic> map) {
    this._emailAddress = map['emailAddress'];
    this._databases = map['databases'];
    this._checkoutPeriod = map['checkoutPeriod'];
  }
}
