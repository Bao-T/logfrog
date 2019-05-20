import 'package:flutter/material.dart';
import 'package:logfrog/firebase_service.dart';
import 'package:logfrog/classes/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/widgets/widgets.dart';
import "package:qr_mobile_vision/qr_camera.dart";
import 'package:logfrog/pages/memberPages.dart';
import 'package:intl/intl.dart';
class ViewItem extends StatefulWidget {
  ViewItem({Key key, this.item, this.site}) : super(key: key);
  final Equipment item;
  final String site;
  @override
  ViewItemState createState() => ViewItemState();
}

//view an equipment item and update variables
//Already has the equipment stored in the widget.item
class ViewItemState extends State<ViewItem> {
  final Timestamp dateNow =
      Timestamp.now(); //default timestamp is the current one
  bool validateName = false;
  bool editMode = false;
  FirebaseFirestoreService fs;
  @override
  void initState() {
    //fill all values
    fs = FirebaseFirestoreService(widget.site);
    condition.setString(widget.item.condition);
    itemId.setString(widget.item.itemID);
    itemType.setString(widget.item.itemType);
    name.setString(widget.item.name);
    notes.setString(widget.item.notes);
    status.setStatus(widget.item.status);
    purchased.setString(widget.item.thisPurchased);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  //Setting up item viewer
  FieldWidget condition = FieldWidget(
    title: 'Condition',
    hint: 'Item Condition:',
    enabled: false,
  );
  //Setting up viewer for equipment fields
  FieldWidget itemId = FieldWidget(
      title: 'Item ID', hint: 'An ID will generate by default', enabled: false);
  FieldWidget itemType =
      FieldWidget(title: 'Item Type', hint: 'Enter Item Type', enabled: false);
  FieldWidget name =
      FieldWidget(title: 'Item Name', hint: 'Enter Item Name', enabled: false);
  FieldWidget notes =
      FieldWidget(title: 'Notes', hint: 'Item Notes', enabled: false);
  FieldWidget purchased =
      FieldWidget(title: 'Purchased Date', hint: 'Date', enabled: false);
  StatusWidget status = StatusWidget(title: 'Item Status', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons
                  .edit), //if entering edit mode, uses above FieldWidgets to edit content
              onPressed: () {
                editMode = true;
                setState(() {
                  itemId = FieldWidget(
                      title: 'Item ID',
                      hint: 'Scan your Image Code',
                      enabled: false);
                  itemType = FieldWidget(
                      title: 'Item Type',
                      hint: 'Enter Item Type',
                      enabled: true);
                  name = FieldWidget(
                      title: 'Item Name',
                      hint: 'Enter Item Name',
                      enabled: true);
                  notes = FieldWidget(
                      title: 'Notes', hint: 'Item Notes', enabled: true);
                  purchased = FieldWidget(
                      title: 'Purchased Date', hint: 'Date', enabled: true);
                  status = StatusWidget(title: 'Item Status', enabled: true);
                  condition.setString(widget.item.condition);
                  itemId.setString(widget.item.itemID);
                  itemType.setString(widget.item.itemType);
                  name.setString(widget.item.name);
                  notes.setString(widget.item.notes);
                  purchased.setString(widget.item.thisPurchased);
                  status.setStatus(widget.item.status);
                });
              }),
          actions: <Widget>[
            IconButton(
                //closing edit mode
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title:
              editMode == false ? Text("Item Details") : Text("Edit Details"),
        ),
        body: cameraView
            ? Column(
                //allow user to scan qr code to input updated qr
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
                              itemId.setString(code);
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
                              name,
                              Row(children: <Widget>[
                                Expanded(child: itemId),
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
                              itemType,
                              purchased,
                              status,
                              condition,
                              notes,
                            ],
                          )),
                          editMode == false
                              ? Container()
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                      RaisedButton(
                                        child: Text(
                                            "Update"), //when update is pressed, update the equipment fields
                                        onPressed: () async {
                                          if (name.value.isEmpty) {
                                            setState(() {
                                              name = FieldWidget(
                                                title: 'Item Name',
                                                hint: 'Enter Item Name',
                                                validate: true,
                                                enabled: true,
                                              );
                                            });
                                            _showToast(context,
                                                'Error: You must enter an item name.');
                                          } else if ((itemId.value.isEmpty)) {
                                            _showToast(context,
                                                'Error: You must scan an item code.');
                                          } else {
                                            //TODO:  add itemID checks to make sure that it is not used in the equipemnt/patron classes already
                                            try {
                                              await fs.updateEquipment(
                                                  name: name.value,
                                                  itemID: itemId.value,
                                                  itemType: itemType.value,
                                                  purchased: dateNow,
                                                  status: status.value,
                                                  condition: condition.value,
                                                  lastCheckedOut:
                                                      dateNow, //set last checked out date to same as purchased date
                                                  notes: notes.value);
                                              await fs.updateItemTypes(
                                                  itemType.value);
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
                                                    title: Text("Delete Item"),
                                                    content: Text(
                                                        "Are you sure you want to delete this item? This will not reflect in the history logs and may unlink data."),
                                                    actions: <Widget>[
                                                      FlatButton(
                                                          child: Text("Delete"),
                                                          onPressed: () {
                                                            try {
                                                              fs.deleteEquipment(
                                                                  widget.item
                                                                      .itemID);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              print(
                                                                  e.toString());
                                                              _showToast(
                                                                  context,
                                                                  e.toString());
                                                            }
                                                          }),
                                                      FlatButton(
                                                          child: Text("Cancel"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }),
                                                    ]);
                                              });
                                        },
                                      ),
                                    ])
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
//end view/udpate equipment

//Adding a new item widgets
//For adding a new equipment/student
class AddItem extends StatefulWidget {
  AddItem({Key key, this.site}) : super(key: key);
  final String site;
  @override
  AddItemState createState() => AddItemState();
}

//Setting up AddItemWidget
class AddItemState extends State<AddItem> {
  final Timestamp dateNow =
  Timestamp.now(); //timetsamp of item creation in the database
  bool validateName = false; //boolean for determining if the name will be valid
  FirebaseFirestoreService
  fs; //declaring a instance of firestore to handle the transactions
  FieldWidget condition =
  FieldWidget(title: 'Condition', hint: 'Item Condition:');
  FieldWidget itemId = FieldWidget(
      title: 'Item ID', hint: 'An ID will generate by default', enabled: false);
  FieldWidget itemType =
  FieldWidget(title: 'Item Type', hint: 'Enter Item Type');
  FieldWidget name = FieldWidget(title: 'Item Name', hint: 'Enter Item Name');
  FieldWidget notes = FieldWidget(title: 'Notes', hint: 'Item Notes');
  FieldWidget purchased = FieldWidget(
    title: 'Purchased Date',
    hint: 'Date',
  );
  StatusWidget status = StatusWidget(
    title: 'Item Status',
  );
  //Status for checking an item in and out
  bool cameraView = false;

  @override
  //Setting up the widget, default purchased date is reformatted Timestamp of current time
  void initState() {
    print(widget.site);
    fs = FirebaseFirestoreService(widget.site);
    purchased
        .setString(DateFormat('MM-dd-yyyy').format(Timestamp.now().toDate()));
    super.initState();
  }

  @override
  //Scaffolding the item adding widget
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.note_add),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  //when icon is pressed, pops up the add item area
                  Navigator.pop(context);
                })
          ],
          title: Text("Add Item"),
        ),
        body: cameraView
        //Allows new qr code to be scanned for a added item, that way a item can be assigned a qr sticker if any are available
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
                        itemId.setString(code);
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
                          name,
                          Row(children: <Widget>[
                            Expanded(child: itemId),
                            IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () {
                                  setState(() {
                                    cameraView = true;
                                  });
                                })
                          ]),
                          itemType,
                          purchased,
                          status,
                          condition,
                          notes,
                        ],
                      )),
                  RaisedButton(
                    child: Text("Submit"),
                    onPressed: () async {
                      //in item creation mode, when submit is pressed will create on firebase
                      if (name.value.isEmpty) {
                        setState(() {
                          name.validate = false;
                        });
                        _showToast(context,
                            'Error: You must enter item name.'); //must have a item name
                      } else if (itemId.value.isEmpty) {
                        _showToast(context,
                            'Error: You must scan item code.'); //must have a id number for qr generation
                        //TODO:  add another else if for checking if the id exists in firebase???? and is nto alreaydy used for a student id???
                      } else {
                        try {
                          await fs.createEquipment(
                            //try to create the item
                              name: name.value,
                              itemID: itemId.value,
                              itemType: itemType.value,
                              purchased: dateNow,
                              status: status.value,
                              condition: condition.value,
                              lastCheckedOut:
                              dateNow, //default date last checked out to same as purchased date for new item
                              notes: notes.value);
                          await fs.updateItemTypes(itemType.value);

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
//end equipment creation