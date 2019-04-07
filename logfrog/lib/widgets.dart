import 'package:flutter/material.dart';

//class cameraScannerWidget extends StatefulWidget  {
//  cameraScannerWidget({Key key}) : super(key: key);
//  @override
//  cameraScannerState createState() => cameraScannerState();
//
//}
//
//class cameraScannerState extends State<cameraScannerWidget>{
//  @override
//  Widget build(BuildContext context) {
//    // TODO: implement build
//    return Scaffold(
//      body: OrientationBuilder(
//          builder: (context,orientation){
//            return AspectRatio(
//                aspectRatio: orientation == Orientation.portrait ? 3.0 / 4.0 : 4.0/3.0,
//                child: Container(
//                  margin: EdgeInsets.all(5.0),
//                  color: Colors.greenAccent,
//                  child: Text("Camera"),
//                )
//            );
//          }
//      )
//    );
//  }
//}


class FieldWidget extends StatelessWidget{
  TextField tf;
  final textController = TextEditingController();
  final String title;
  final String hint;
  String get value => this.textController.text;
  FieldWidget({this.title, this.hint}) {
    this.tf = TextField(
      controller: textController,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        decoration: new InputDecoration(
        hintText: hint
    )
    );
  }
  void setString(String text){
    this.textController.text = text;
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
      child: Padding(padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[Text(title, style: TextStyle(fontWeight: FontWeight.bold),), tf],
      )),
    );
  }
}
