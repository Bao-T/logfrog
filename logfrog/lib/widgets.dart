import 'package:flutter/material.dart';

class cameraScannerWidget extends StatefulWidget  {
  cameraScannerWidget({Key key}) : super(key: key);
  @override
  cameraScannerState createState() => cameraScannerState();

}

class cameraScannerState extends State<cameraScannerWidget>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: OrientationBuilder(
          builder: (context,orientation){
            return AspectRatio(
                aspectRatio: orientation == Orientation.portrait ? 3.0 / 4.0 : 4.0/3.0,
                child: Container(
                  margin: EdgeInsets.all(5.0),
                  color: Colors.greenAccent,
                  child: Text("Camera"),
                )
            );
          }
      )
    );
  }
}
