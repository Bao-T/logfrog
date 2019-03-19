import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference


Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access


class Equipment {
  int id;
  String condition;
  List<DocumentReference> history;
  String image; //leaving this as string for now, until we figure out getting firebase to accept images
  List<String> notes;
  DocumentReference reference;
  int barcode;
  int type;

  Equipment(this.id, this.condition, this.history, this.image, this.notes, this.reference, this.barcode, this.type);

  Equipment.map(dynamic obj) {
    this.id = obj['id'];
    this.condition = obj['condition'];
    this.history = obj['history'];
    this.image = obj['image'];
    this.notes = obj['notes'];
    this.reference = obj['reference'];
    this.barcode = obj['barcode'];
    this.type = obj['type'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (id != null) {
      map['id'] = id;
    }
    map['condition'] =  condition;
    map['history'] = history;
    map['image'] = image;
    map['notes'] = notes;
    map['reference'] = reference;
    map['barcode'] = barcode;
    map['type'] = type;
    return map;
  }
  Equipment.fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.condition = map['condition'];
    this.history = map['history'];
    this.image = map['image'];
    this.notes = map['notes'];
    this.reference = map['reference'];
    this.barcode = map['barcode'];
    this.type = map['type'];
  }

}