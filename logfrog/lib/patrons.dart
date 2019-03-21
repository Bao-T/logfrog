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

  static Map<String, dynamic> toMap(Patrons pat) {
    var map = new Map<String, dynamic>();
    if (pat.id != null) {
      map['id'] = pat.id;
    }
    map['firstName'] = pat.firstName;
    map['lastName'] = pat.lastName;
    map['emailAddress'] = pat.emailAddress;
    map['username'] = pat.username;
    map['password'] = pat.password;
    map['checkOutHistory'] = pat.checkOutHistory;
    map['checkedOutEquipment'] = pat.checkedOutEquipment;
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