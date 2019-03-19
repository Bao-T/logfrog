import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


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

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (id != null) {
      map['id'] = id;
    }
    map['firstName'] = firstName;
    map['lastName'] = lastName;
    map['emailAddress'] = emailAddress;
    map['username'] = username;
    map['password'] = password;
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