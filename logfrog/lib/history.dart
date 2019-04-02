//History class, will be owned by a 'site'
import 'package:cloud_firestore/cloud_firestore.dart';


class History {
  String itemID; //id of item being checked out
  String itemName; //name of item being checked out /in
  String memID; //member checking in/out
  String memName; //name of member checking in/out
  String username; //username of member checking in/out
  Timestamp timeCheckedOut;//may or may not break horribly??? if so, could use this fix: https://stackoverflow.com/questions/52996707/flutter-app-error-type-timestamp-is-not-a-subtype-of-type-datetime
  Timestamp timeCheckedIn; //default of same as checked out timestamp initially (so if they are the same time, the item is not checked back in)

  //Creates a history object from a map with all fields filled
  History(this.itemID, this.itemName, this.memID, this.memName, this.username, this.timeCheckedOut, this.timeCheckedIn);

  //creates history object mapping
  History.map(dynamic obj) {
    this.itemID = obj['itemID'];
    this.itemName = obj['itemName'];
    this.memID = obj['memID'];
    this.memName = obj['memName'];
    this.username = obj['username'];
    this.timeCheckedOut= obj['timeCheckedOut'];
    this.timeCheckedIn = obj['timeCheckedIn'];
  }

  //creates a map from a history object
  static Map<String, dynamic> toMap(History history) {
    var map = new Map<String, dynamic>();
    if (history.itemID != "") { //if the string is not empty for item being checked out
      map['id'] = history.itemID;
    }
    map['itemID'] = history.itemID;
    map['itemName'] = history.itemName;
    map['memID'] = history.memID;
    map['memName'] = history.memName;
    map['username'] = history.username;
    map['timeCheckedOut'] = history.timeCheckedOut;
    map['timeCheckedIn'] = history.timeCheckedIn;
    return map;
  }

  //creates a history object from a map (how history objects will be created from those stored on firebase already)
  History.fromMap(Map<String, dynamic> map) {
    this.itemID = map['itemID'];
    this.itemName = map['itemName'];
    this.memID = map['memID'];
    this.memName = map['memName'];
    this.username = map['username'];
    this.timeCheckedOut = map['timeCheckedOut'];
    this.timeCheckedIn = map['timeCheckedIn'];
  }
}

