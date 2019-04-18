//adapted from: https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview
//date accessed: 4/4/2019

//Class for each site where logfrog will be used to track photography equipment
//Each Site will be connected to a User, and will have Patrons (students), Equipment, and History objects

class Objects{
  //declaring the variables that we will be working with in this particular instance
  String _id; //ID of the equipment site/classroom
  String _className; //name given to classroom for easier searching

  Objects(this._id, this._className); //initialize the variables

  //map the items to JSON so that it can be sent up to the Firestore
  Objects.map(dynamic obj){
    this._id = obj['id'];
    this._className = obj['ClassName'];
  }

  //get functions so that we can work with our private variables
  String get id => _id;
  String get className => _className;

  //translate JSON to something our program can understand
  Map<String, dynamic> toMap(){
    var map = new Map<String, dynamic>();
    if( _id != null){
      map['id'] = _id;
    }
    map['ClassName'] = _className;

    return map;

  }
  //translate dart to something JSON will understand
 Objects.fromMap(Map<String, dynamic> map){
    this._id = map['id'];
    this._className = map['ClassName'];
 }
}
