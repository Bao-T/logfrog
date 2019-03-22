//import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Users {
  int id;
  String firstName;
  String lastName;
  String emailAddress;
  String username;
  String password;

  Users(this.id, this.firstName, this.lastName, this.emailAddress, this.username, this.password);

  Users.map(dynamic obj) {
    this.id = obj['id'];
    this.firstName = obj['firstName'];
    this.lastName = obj['lastName'];
    this.emailAddress = obj['emaileAddress'];
    this.username = obj['username'];
    this.password = obj['password'];
  }

  static Map<String, dynamic> toMap(Users usr) {
    var map = new Map<String, dynamic>();
    if (usr.id != null) {
      map['id'] = usr.id;
    }
    map['firstName'] = usr.firstName;
    map['lastName'] = usr.lastName;
    map['emailAddress'] = usr.emailAddress;
    map['username'] = usr.username;
    map['password'] = usr.password;
    return map;
  }

  Users.fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.firstName = map['firstName'];
    this.lastName = map['lastName'];
    this.emailAddress = map['emaileAddress'];
    this.username = map['username'];
    this.password = map['password'];
  }
}