import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff


class Sites {
  String classname;

  Sites(this.classname);

  Sites.map(dynamic obj) {
    this.classname = obj['Classname'];
  }

  static Map<String, dynamic> toMap(Sites site) {
    var map = new Map<String, dynamic>();
    map['Classname'] = site.classname;

    return map;
  }

  Sites.fromMap(Map<String, dynamic> map) {
    this.classname = map['Classname'];
  }
}