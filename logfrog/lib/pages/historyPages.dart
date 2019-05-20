import 'package:flutter/material.dart';
import 'package:logfrog/classes/history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/widgets/widgets.dart';
//view/update history
class ViewHistory extends StatefulWidget {
  ViewHistory({Key key, this.hist}) : super(key: key);
  final History hist;
  @override
  ViewHistoryState createState() => ViewHistoryState();
}

class ViewHistoryState extends State<ViewHistory> {
  final Timestamp dateNow = Timestamp
      .now(); //defaults to current date TODO: determine if we need this
  bool validateName = false;
  bool editMode = false;
  bool itemMode = false;
  bool memMode = false;
  @override
  void initState() {
    //initialize all history variables with the current firebase values
    itemID.setString(widget.hist.itemID);
    itemName.setString(widget.hist.itemName);
    memID.setString(widget.hist.memID);
    memName.setString(widget.hist.memName);
    timeCheckedIn.setString(widget.hist.timeCheckedInString);
    timeCheckedOut.setString(widget.hist.timeCheckedOutString);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  //Setting up FieldWidgets for editing below
  FieldWidget itemID = FieldWidget(title: 'Item ID', hint: '', enabled: false);
  FieldWidget itemName =
  FieldWidget(title: 'Item Name', hint: '', enabled: false);
  FieldWidget memID = FieldWidget(title: 'Member ID', hint: '', enabled: false);
  FieldWidget memName =
  FieldWidget(title: 'Member Name', hint: '', enabled: false);
  FieldWidget timeCheckedIn =
  FieldWidget(title: 'Time Checked In', hint: '', enabled: false);
  FieldWidget timeCheckedOut =
  FieldWidget(title: 'Time Checked Out', hint: '', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title: editMode == false //Select view or edit history mode
              ? Text("History Details")
              : Text("Edit Details"),
        ),
        body: Builder(
            builder: (context) => Column(
              //view history values
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                      child: ListView(
                        children: <Widget>[
                          itemID,
                          itemName,
                          memID,
                          memName,
                          timeCheckedIn,
                          timeCheckedOut
                        ],
                      )),
                ])));
    //TODO: add edit mode here using the Field Widgets above
  }

  void _showToast(BuildContext context, String errorText) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(errorText),
        action: SnackBarAction(
            label: 'Okay', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}