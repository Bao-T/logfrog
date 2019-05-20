import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff

//Class for Patrons of a objects site
//So, class for students at a classroom site


class Patrons {
  String _id; //student id
  String _firstName; //student first name
  String _lastName; //student last name
  String _address; //student address
  String _phone; //student phone number
  String _notes; //extra notes to be entered

  Patrons(this._id, this._firstName, this._lastName, this._address, this._phone, this._notes);

  //get methods to access private variables
  String get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get emailAddress => _address;
  String get phone => _phone;
  String get notes => _notes;


  Patrons.map(dynamic obj) {
    this._id = obj['id'];
    this._firstName = obj['firstName'];
    this._lastName = obj['lastName'];
    this._address = obj['emailAddress'];
    this._phone = obj['phone'];
    this._notes = obj['notes'];

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

    return map;
  }

  Patrons.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._firstName = map['firstName'];
    this._lastName = map['lastName'];
    this._address = map['emailAddress'];
    this._phone = map['phone'];
    this._notes = map['notes'];
  }
}