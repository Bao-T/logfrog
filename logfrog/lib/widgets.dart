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
class FieldWidget extends StatefulWidget{
  final String title;
  final String hint;
  final textController = TextEditingController();
  bool validate;
  bool enabled;
  String get value => this.textController.text;
  void setString(String text) {
    this.textController.text = text;
  }

  FieldWidget({this.title, this.hint, this.enabled = true, this.validate = true});
  @override
  FieldWidgetState createState () => FieldWidgetState();
}

class FieldWidgetState extends State<FieldWidget>{

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
      child: Padding(padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold),), TextField(
                enabled: widget.enabled,
                controller: widget.textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: new InputDecoration(
                  hintText: widget.hint,
                  errorText: !widget.validate ? 'Value Can\'t Be Empty' : null,
                )
            )],
          )),
    );
  }
}

//class FieldWidget extends StatelessWidget{
//  TextField tf;
//  final String title;
//  final String hint;
//  final textController = TextEditingController();
//  bool validate = true;
//  bool enabled;
//  String get value => this.textController.text;
//
//
//  FieldWidget({this.title, this.hint, this.enabled, this.validate = true}) {
//    this.tf = TextField(
//      enabled: enabled,
//      controller: textController,
//        keyboardType: TextInputType.multiline,
//        maxLines: null,
//        decoration: new InputDecoration(
//        hintText: hint,
//          errorText: !validate ? 'Value Can\'t Be Empty' : null,
//    )
//    );
//  }
//
//  void setString(String text){
//    this.textController.text = text;
//  }
//  @override
//  Widget build(BuildContext context) {
//    // TODO: implement build
//    return Card(
//      child: Padding(padding: EdgeInsets.all(10.0),
//      child: Column(
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: <Widget>[Text(title, style: TextStyle(fontWeight: FontWeight.bold),), tf],
//      )),
//    );
//  }
//}
