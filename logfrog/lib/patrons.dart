import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Patrons {
  int id;
  String firstName;
  String lastName;
  String emailAddress;
  String username;
  String password;
  List<DocumentReference> checkOutHistory;
  List<DocumentReference> checkedOutEquipment;

  Patrons(this.id, this.firstName, this.lastName, this.emailAddress, this.username, this.password, this.checkOutHistory, this.checkedOutEquipment);

  Patrons.map(dynamic obj) {
    this.id = obj['id'];
    this.firstName = obj['firstName'];
    this.lastName = obj['lastName'];
    this.emailAddress = obj['emaileAddress'];
    this.username = obj['username'];
    this.password = obj['password'];
    this.checkOutHistory = obj['checkOutHistory'];
    this.checkedOutEquipment = obj['checkedOutEquipment'];
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
    map['checkOutHistory'] = checkOutHistory;
    map['checkedOutEquipment'] = checkedOutEquipment;
    return map;
  }

  Patrons.fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.firstName = map['firstName'];
    this.lastName = map['lastName'];
    this.emailAddress = map['emaileAddress'];
    this.username = map['username'];
    this.password = map['password'];
    this.checkOutHistory = map['checkOutHistory'];
    this.checkedOutEquipment = map['checkedOutEquipment'];
  }
}