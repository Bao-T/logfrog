//History class, will be owned by a 'site'
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//History class will have instances of an equipment being checked out at Objects site by a patron

class History {
  String _itemID; //id of item being checked out
  String _historyID; //History ID (autogenerated) (firebase keys)
  //String _itemID; //id of item being checked out (equipment barcode)
  String _itemName; //name of item being checked out /in
  String _memID; //member checking in/out
  String _memName; //name of member checking in/out
  //String _username; //_username of member checking in/out
  Timestamp _timeCheckedOut;//may or may not break horribly??? if so, could use this fix: https://stackoverflow.com/questions/52996707/flutter-app-error-type-timestamp-is-not-a-subtype-of-type-datetime
  Timestamp _timeCheckedIn; //default of same as checked out timestamp initially (so if they are the same time, the item is not checked back in)

  //Creates a history object from a map with all fields filled
  History(this._itemID, this._itemName, this._memID, this._memName, this._timeCheckedOut, this._timeCheckedIn);

  //get methods to access private variables
  String get itemID => _itemID;
  String get itemName => _itemName;
  String get memID => _memID;
  String get memName => _memName;
  //String get username => _username;
  String get timeCheckedOutString => _timeCheckedOut == null ? '' : DateFormat.yMd().add_jm().format(_timeCheckedOut.toDate());
  String get timeCheckedInString =>  _timeCheckedIn == null ? '' : DateFormat.yMd().add_jm().format(_timeCheckedIn.toDate());
  Timestamp get timeCheckedOut => _timeCheckedOut;
  Timestamp get timeCheckedIn => timeCheckedIn;
  //creates history object mapping
  History.map(dynamic obj) {
    this._itemID = obj['itemID'];
    this._itemName = obj['itemName'];
    this._memID = obj['memID'];
    this._memName = obj['memName'];
    //this._username = obj['username'];
    this._timeCheckedOut= obj['timeCheckedOut'];
    this._timeCheckedIn = obj['timeCheckedIn'];
  }

  //creates a map from a history object
  static Map<String, dynamic> toMap(History history) {
    var map = new Map<String, dynamic>();
    map['itemID'] = history._itemID;
    map['itemName'] = history._itemName;
    map['memID'] = history._memID;
    map['memName'] = history._memName;
    map['timeCheckedOut'] = history._timeCheckedOut;
    map['timeCheckedIn'] = history._timeCheckedIn;
    return map;
  }

  //creates a history object from a map (how history objects will be created from those stored on firebase already)
  History.fromMap(Map<String, dynamic> map) {
    this._itemID = map['itemID'];
    this._itemName = map['itemName'];
    this._memID = map['memID'];
    this._memName = map['memName'];
    //this._username = map['username'];
    this._timeCheckedOut = map['timeCheckedOut'];
    this._timeCheckedIn = map['timeCheckedIn'];
  }
}

