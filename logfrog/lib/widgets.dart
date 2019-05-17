import 'package:flutter/material.dart';


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
    return Container(
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


class StatusWidget extends StatefulWidget{
  final String title;
  final String hint;
  final textController = TextEditingController();
  bool validate;
  bool enabled;
  String status = "available";
  String get value => this.status;
  void setStatus(String stat) {
    this.status = stat;
  }

  StatusWidget({this.title, this.hint, this.enabled = true, this.validate = true});
  @override
  StatusWidgetState createState () => StatusWidgetState();
}

class StatusWidgetState extends State<StatusWidget>{

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child: Padding(padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold),),
    widget.enabled == true ? DropdownButtonHideUnderline(
    child: DropdownButton(
      isExpanded: true,
      value: widget.status,
      items: <DropdownMenuItem<String>>[
    DropdownMenuItem(
    child: Text(''),
        value: '',)
        ,
        DropdownMenuItem(
          child: Text('Available'),
          value: 'available',
        ),
        DropdownMenuItem(
          child: Text('Unavailable'),
          value: 'unavailable',
        ),
        DropdownMenuItem(
          //TODO: remove, we don't support this
          child: Text('Discontinued'),
          value: 'discontinued',
        )
      ],
    onChanged: (String stat) {
        setState(() {
          widget.status = stat;
        });


    }

    )) : Text(widget.status, style: new TextStyle(
      fontSize: 18.0)),
    Divider(color: Colors.black,)

            ],
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
