import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
//import 'dart:async';

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference


Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access


class Member {
  String address, firstname, lastname, memID,notes,phone;

  Member({this.address, this.firstname, this.lastname, this.memID,this.phone,this.notes});

  String get thisAddress => address;
  String get thisFirstName =>firstname;
  String get thisLastName =>lastname;
  String get thisMemId => memID;
  String get thisPhone =>phone;
  String get thisNotes => notes;


  Member.map(dynamic obj) {
    this.address =  obj['Address'];
    this.firstname=  obj['FirstName'];
    this.lastname  =obj['LastName'];
    this.memID =obj['MemID'];
    this.phone = obj['Phone'];
    this.notes = obj['Notes'];
  }

  static Map<String, dynamic> toMap(Member mem) {
    var map = new Map<String, dynamic>();
    map['Address'] = mem.address;
    map['FirstName'] = mem.firstname;
    map['LastName'] = mem.lastname;
    map['MemID'] = mem.memID;
    map['Phone'] = mem.phone;
    map['Notes'] = mem.notes;
    return map;
  }


  Member.fromMap(Map<String, dynamic> dataMap) {
    this.address =  dataMap['Address'];
    this.firstname=  dataMap['FirstName'];
    this.lastname  =dataMap['LastName'];
    this.memID =dataMap['MemID'];
    this.phone = dataMap['Phone'];
    this.notes = dataMap['Notes'];









  }

}