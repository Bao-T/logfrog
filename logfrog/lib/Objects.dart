import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff

//adapted from: https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview
//date accessed: 4/4/2019

//Firestore db = Firestore.instance; //set up the database to recieve information

//CollectionReference objectCollectionRef = db.collection('Objects'); //Reference which collection we will be using

//DocumentReference jsaDocumentRef = db.collection('Objects').document('History');

class Object{
  //declaring the variables that we will be working with in this particular instance
  String _id;
  String _ClassName;

  Object(this._id, this._ClassName); //initialize the variables

  //map the items to JSON so that it can be sent up to the Firestore
  Object.map(dynamic obj){
    this._id = obj['id'];
    this._ClassName = obj['classname'];
  }

  //get functions so that we can work with our private variables
  String get id => _id;
  String get className => _ClassName;

  //translate JSON to something our program can understand
  Map<String, dynamic> toMap(){
    var map = new Map<String, dynamic>();
    if( _id != null){
      map['id'] = _id;
    }
    map['classname'] = _ClassName;

    return map;

  }
  //translate dart to something JSON will understand
 Object.fromMap(Map<String, dynamic> map){
    this._id = map['id'];
    this._ClassName = map['classname'];
 }
}


//class Sites {
//  String classname;
//
//  Sites(this.classname);
//
//  Sites.map(dynamic obj) {
//    this.classname = obj['Classname'];
//  }
//
//  static Map<String, dynamic> toMap(Sites site) {
//    var map = new Map<String, dynamic>();
//    map['Classname'] = site.classname;
//
//    return map;
//  }
//
//  Sites.fromMap(Map<String, dynamic> map) {
//    this.classname = map['Classname'];
//  }
//}