import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
import 'package:intl/intl.dart';
//import 'dart:async';

//Following this tutorial for building the class
// https://grokonez.com/flutter/flutter-firestore-example-firebase-firestore-crud-operations-with-listview#Initialize_038_Reference

Firestore db = Firestore.instance; //Initially getting firestore instance for use in database access

class Equipment {

  //private string variables except for Datemtime, which is a firebase class
  String _condition; //condition of equipment
  String _itemID; //id of object (used in generating QR code)
  String _itemType; //type of object (camera, lens, etc.)
  String _name; //object name, if any
  String _notes; //Any additional notes can go here
  DateTime _purchased; //Date purchased for equipment (defaults to date added to database if not given)
  String _status; //Checked in or checked out status
  
  //Equipment mapping
  Equipment(this._condition, this._itemID, this._itemType, this._name, this._notes, this._purchased, this._status);


  //get functions to access private variables
  String get itemID => _itemID;
  String get condition => _condition;
  String get notes => _notes;
  String get itemType => _itemType;
  String get name => _name;
  String get thisPurchased => DateFormat('MM-dd-yyyy').format(_purchased); //reformats the date into MM-dd-yyyy
  String get status => _status;

  //mapping of object
  Equipment.map(dynamic obj) {
    this._condition =  obj['Condition'];
    this._itemID =  obj['ItemID'];
    this._itemType  =obj['ItemType'];
    this._name =obj['Name'];
    this._notes= obj['Notes'];
    this._purchased = obj['Purchased'];
    this._status =obj['Status'];
  }

  //creates map of an object for storing on firebase
  static Map<dynamic, dynamic> toMap(Equipment equip) {
    var map = new Map<String, dynamic>();
    map['Condition'] = equip._condition;
    map['ItemID'] = equip._itemID;
    map['ItemType'] = equip._itemType;
    map['Name'] = equip._name;
    map['Notes'] = equip._notes;
    map['Purchased'] = equip._purchased;
    map['Status'] = equip._status;
    return map;
  }


  //creates object from stored firebase map
  Equipment.fromMap(Map<String, dynamic> dataMap) {
    this._condition =  dataMap['Condition'];
    this._itemID=  dataMap['ItemID'];
    this._itemType  =dataMap['ItemType'];
    this._name =dataMap['Name'];
    this._notes= dataMap['Notes'];
    this._purchased = dataMap['Purchased'];
    this._status =dataMap['Status'];
  }

}