import 'package:flutter/material.dart';
import 'package:logfrog/firebase_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/widgets/widgets.dart';
import 'package:logfrog/classes/patrons.dart';
import 'package:logfrog/classes/history.dart';
import "package:qr_mobile_vision/qr_camera.dart";
import 'package:logfrog/pages/historyPages.dart';

bool frontCamera = false;
//view/update member information
//Has the member information already from the list widgets above
class ViewMember extends StatefulWidget {
  ViewMember({Key key, this.mem, this.site}) : super(key: key);
  final Patrons mem; //has a Patrons class member
  final String site;
  @override
  ViewMemberState createState() => ViewMemberState();
}

class ViewMemberState extends State<ViewMember> {
  final Timestamp dateNow = Timestamp.now(); //TODO:  why do we need this???
  bool validateName = false;
  bool editMode = false;
  FirebaseFirestoreService fs;
  List<History>
  histories; //Will pull up the histories using a streamquery for this member
  StreamSubscription<QuerySnapshot> historySub;
  @override
  void initState() {
    fs = FirebaseFirestoreService(widget.site);
    historySub?.cancel();
    //Finding relevant histories
    this.historySub =
        fs.getMemberHistory(widget.mem.id).listen((QuerySnapshot snapshot) {
          final List<History> history = snapshot.documents
              .map((documentSnapshot) => History.fromMap(documentSnapshot.data))
              .toList();
          setState(() {
            this.histories = history;
          });
        });
    //Filling other member fields
    id.setString(widget.mem.id);
    firstName.setString(widget.mem.firstName);
    lastName.setString(widget.mem.lastName);
    address.setString(widget.mem.emailAddress);
    phone.setString(widget.mem.phone);
    notes.setString(widget.mem.notes);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  //Setting up FieldWidgets for editting member/patron variables
  FieldWidget id = FieldWidget(
      title: 'Item ID', hint: 'An ID will generate by default', enabled: false);
  FieldWidget firstName = FieldWidget(
      title: 'First Name', hint: 'Member First Name', enabled: false);
  FieldWidget lastName =
  FieldWidget(title: 'Last Name', hint: 'Member Last Name', enabled: false);
  FieldWidget address =
  FieldWidget(title: 'Email Address', hint: 'Email', enabled: false);
  FieldWidget phone = FieldWidget(
      title: 'Phone Number', hint: '(###) ###-####', enabled: false);
  FieldWidget notes =
  FieldWidget(title: 'Notes', hint: 'Member notes:', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                editMode =
                true; //if in edit mode, allow variables to be changed using above widgets
                setState(() {
                  id = FieldWidget(
                      title: 'ID',
                      hint: 'An ID will generate by default',
                      enabled: false);
                  firstName = FieldWidget(
                      title: 'First Name',
                      hint: 'Member First Name',
                      enabled: true);
                  lastName = FieldWidget(
                      title: 'Last Name',
                      hint: 'Member Last Name',
                      enabled: true);
                  address = FieldWidget(
                      title: 'Email Address', hint: 'Email', enabled: true);
                  phone = FieldWidget(
                      title: 'Phone Number',
                      hint: '(###) ###-####',
                      enabled: true);
                  notes = FieldWidget(
                      title: 'Notes', hint: 'Member notes:', enabled: true);
                  id.setString(widget
                      .mem.id); //TODO:  add id checks for the members/patrons
                  firstName.setString(widget.mem.firstName);
                  lastName.setString(widget.mem.lastName);
                  address.setString(widget.mem.emailAddress);
                  phone.setString(widget.mem.phone);
                  notes.setString(widget.mem.notes);
                });
              }),
          actions: <Widget>[
            IconButton(
              //closing view mode
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title:
          editMode == false ? Text("Member Details") : Text("Edit Details"),
        ),
        body: cameraView
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new SizedBox(
                width: 200.0,
                height: 300.0,
                child: new QrCamera(
                    front: frontCamera,
                    onError: (context, error) => Text(
                      error.toString(),
                      style: TextStyle(color: Colors.red),
                    ),
                    qrCodeCallback: (code) {
                      setState(() {
                        id.setString(code);
                        cameraView = false;
                      });
                    })),
            RaisedButton(
              child: Text("Cancel"),
              onPressed: () {
                setState(() {
                  cameraView = false;
                });
              },
            )
          ],
        )
            : Builder(
            builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                      child: ListView(
                        children: <Widget>[
                          firstName,
                          lastName,
                          Row(children: <Widget>[
                            Expanded(child: id),
                            editMode == false
                                ? Container()
                                : IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () {
                                  setState(() {
                                    cameraView = true;
                                  });
                                })
                          ]),
                          address,
                          phone,
                          notes,
                          Card(
                            //displaying history items associated with this member in a list
                              child: Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Text("History",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.0))),
                                    Container(
                                      //displaying history items associated with the member
                                        height: 500,
                                        child: ListView.separated(
                                          separatorBuilder: (context, index) =>
                                              Divider(
                                                color: Colors.black,
                                              ),
                                          itemCount: histories == null
                                              ? 0
                                              : histories.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return new Container(
                                                color: histories[index]
                                                    .timeCheckedInString !=
                                                    ''
                                                    ? Colors.green[200]
                                                    : Colors.red[200],
                                                child: ListTile(
                                                  title: Text(histories[index]
                                                      .itemName
                                                      .toString()),
                                                  trailing: Text(histories[
                                                  index]
                                                      .timeCheckedOutString),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ViewHistory(
                                                                  hist: histories[
                                                                  index])),
                                                    );
                                                  },
                                                ));
                                          },
                                        ))
                                  ],
                                ),
                              ))
                        ],
                      )),
                  editMode == false
                      ? Container()
                      : Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      RaisedButton(
                        child: Text("Update"),
                        onPressed: () async {
                          if (firstName.value.isEmpty) {
                            setState(() {
                              firstName = FieldWidget(
                                  title: 'Item Name',
                                  hint: 'Enter Item Name',
                                  validate: true,
                                  enabled: true);
                            });
                            _showToast(context,
                                'Error: You must enter item name.');
                          } else {
                            try {
                              //print(id.value);
                              await fs.updatePatrons(
                                  id.value,
                                  firstName.value,
                                  lastName.value,
                                  address.value,
                                  phone.value,
                                  notes.value);
                              Navigator.pop(context);
                            } catch (e) {
                              print(e.toString());
                              _showToast(context, e.toString());
                            }
                          }
                        },
                      ),
                      RaisedButton(
                        color: Colors.red,
                        child: Text("Delete"),
                        onPressed: () async {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: Text("Delete Member"),
                                    content: Text(
                                        "Are you sure you want to delete this Member? This will not reflect in the history logs and may unlink data."),
                                    actions: <Widget>[
                                      FlatButton(
                                          child: Text("Delete"),
                                          onPressed: () {
                                            try {
                                              fs.deletePatron(
                                                  widget.mem.id);
                                              Navigator.of(
                                                  context)
                                                  .pop();
                                              Navigator.pop(
                                                  context);
                                            } catch (e) {
                                              print(e.toString());
                                              _showToast(context,
                                                  e.toString());
                                            }
                                          }),
                                      FlatButton(
                                          child: Text("Cancel"),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop();
                                          }),
                                    ]);
                              });
                        },
                      )
                    ],
                  )
                ])));
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

//Adding a new patron to firebase
class AddMember extends StatefulWidget {
  AddMember({Key key, this.site}) : super(key: key);
  final String site;
  @override
  AddMemberState createState() => AddMemberState();
}

class AddMemberState extends State<AddMember> {
  final Timestamp dateNow = Timestamp
      .now(); //default timestamp is now....TODO: find out why we need this
  bool validateName = false;
  FirebaseFirestoreService fs;
  @override
  void initState() {
    //opening a firestore service for the correct class site
    fs = FirebaseFirestoreService(widget.site);
    super.initState();
  }

  //Setting up widget fields to collect new member info
  FieldWidget firstName =
  FieldWidget(title: 'First Name', hint: 'Member First Name');
  FieldWidget lastName =
  FieldWidget(title: 'Last Name', hint: 'Member Last Name');
  FieldWidget memberID = FieldWidget(
      title: 'Member ID',
      hint: 'A random ID will be generated if left empty',
      enabled: false);
  FieldWidget address =
  FieldWidget(title: 'Address', hint: 'Email address of Member');
  FieldWidget phone =
  FieldWidget(title: 'Phone Number', hint: 'Phone Contact of Member');
  FieldWidget notes = FieldWidget(title: 'Notes', hint: 'Notes:');

  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.edit),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title: Text("Add Member"),
        ),
        body: cameraView
            ? Column(
          //Allowing new patron id codes from student IDs to be scanned when adding a member
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new SizedBox(
                width: 200.0,
                height: 300.0,
                child: new QrCamera(
                    front: frontCamera,
                    onError: (context, error) => Text(
                      error.toString(),
                      style: TextStyle(color: Colors.red),
                    ),
                    qrCodeCallback: (code) {
                      setState(() {
                        memberID.setString(code);
                        cameraView = false;
                      });
                    })),
            RaisedButton(
              child: Text("Cancel"),
              onPressed: () {
                setState(() {
                  cameraView = false;
                });
              },
            )
          ],
        )
            : Builder(
            builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                      child: ListView(
                        children: <Widget>[
                          firstName,
                          lastName,
                          Row(children: <Widget>[
                            Expanded(child: memberID),
                            IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () {
                                  setState(() {
                                    cameraView = true;
                                  });
                                })
                          ]),
                          phone,
                          address,
                          notes,
                        ],
                      )),
                  RaisedButton(
                    //when done filling info, add new patron to firestore
                    child: Text("Submit"),
                    onPressed: () async {
                      if (firstName.value.isEmpty) {
                        //must enter a first name field for new members
                        setState(() {
                          firstName.validate = false;
                        });
                        _showToast(context,
                            'Error: You must enter a member name.');
                      } else {
                        //TODO:  add check for memberID to make sure it is not used and is not a equipment ID already
                        try {
                          await fs.createPatron(
                              id: memberID.value,
                              firstName: firstName.value,
                              lastName: lastName.value,
                              address: address.value,
                              phone: phone.value,
                              notes: notes.value);
                          Navigator.pop(context);
                        } catch (e) {
                          print(e.toString());
                          _showToast(context, e.toString());
                        }
                      }
                    },
                  )
                ])));
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
//end new memeber/patron creation

//end user/Patron update
