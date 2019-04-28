import 'package:flutter/material.dart';
import 'liveCamera.dart';
import "chartWidgets.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';
import 'equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets.dart';
//import 'package:audioplayers/audio_cache.dart';
import 'package:intl/intl.dart';
import 'patrons.dart';
import 'package:logfrog/services/authentication.dart';
import 'history.dart';

String dataSite;
FirebaseFirestoreService db;
const alarmAudioPath = "beep.mp3";

class CheckoutPg extends StatefulWidget {
  CheckoutPg({Key key, this.site}) : super(key: key);
  final site;
  @override
  CheckoutPgState createState() => CheckoutPgState();
}

class CheckoutPgState extends State<CheckoutPg> {
  //static AudioCache player = new AudioCache();

  var ori = Orientation.portrait;
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  GestureDetector camera;
  Expanded userInfo;
  String currentMemberID;
  String currentMemberName;
  CustomScrollView database;
  int cameraIndex = 0;
  FirebaseFirestoreService fs;
  Stream<QuerySnapshot> itemStream;
  Stream<QuerySnapshot> memberStream;
  changeCamera() {
    setState(() {
      cameraIndex = (cameraIndex + 1) % 2;
      print('tap' + cameraIndex.toString());
    });
  }

  Future validate(String code) async {
    dynamic member = await Firestore.instance
        .collection('Objects')
        .document(widget.site)
        .collection('Members')
        .document(code)
        .get();
    if (member.exists) {
      currentMemberName =
          member.data['firstName'] + ' ' + member.data['lastName'];
      currentMemberID = code;
    } else {
      dynamic items = await Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection('Items')
          .where('ItemID', isEqualTo: code)
          .getDocuments();
      if (items.documents.isNotEmpty) {
        setState(() {
          dataList.add(code);
          dataNameList.add(items.documents[0]['Name']);
          //player.play(alarmAudioPath);
        });
      } else {
        print('No documents with that id found! v_v');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    fs = FirebaseFirestoreService(widget.site);

    camera = new GestureDetector(
      onTap: changeCamera,
      child: Card(
        margin: EdgeInsets.all(5.0),
        child: LiveBarcodeScanner(
          onBarcode: (code) {
            //print(code);
            if (dataSet.contains(code) == false) {
              dataSet.add(code);
              validate(code);

              //Create widgets for scanned items
              //debugPrint(dataWidget.toString());
            }
            return true;
          },
          cameraIndex: cameraIndex,
        ),
      ),
    );
    userInfo = Expanded(
        child: Card(
      margin: EdgeInsets.all(5.0),
      child: Center(child: Text("User Info")),
    ));
  }

  Future<dynamic> finalTransaction(
      String memID, String memName, List<String> itemIds) async {
    for (int i = 0; i < dataList.length; i++) {
      String itemID = dataList[i];
      var item = await Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection('Items')
          .document(itemID)
          .get();
      String itemName = item.data["Name"].toString();
      DateTime timeCheckedIn;
      DateTime timeCheckedOut = DateTime.now();
      fs.createHistory(
          itemID: itemID,
          itemName: itemName,
          memID: memID,
          memName: memName,
          timeCheckedIn: null,
          timeCheckedOut: timeCheckedOut);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(title: Text('Check-out')),
        body: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Scaffold(
                body: Column(children: [
              Expanded(
                  flex: 8,
                  child: Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[camera, userInfo],
                    ),
                  )),
              Expanded(
                  flex: 10,
                  child: Card(
                      child: ListView.builder(
                    itemCount: dataList.length,
                    itemBuilder: (context, int index) {
                      return Dismissible(
                          key: Key(UniqueKey().toString()),
                          onDismissed: (direction) {
                            debugPrint(
                                index.toString() + " " + dataList[index]);
                            dataSet.remove(dataList[index]);
                            dataList.removeAt(index);
                            dataNameList.removeAt(index);
                          },
                          child: Column(children: <Widget>[
                            InkWell(
                                onTap: () {
                                  print("tapped");
                                },
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: ListTile(
                                        title: Text(dataNameList[index])))),
                            Divider()
                          ]));
                    },
                  ))),
              Expanded(
                  flex: 1,
                  child: SizedBox.expand(
                    child: RaisedButton(
                      color: Colors.green,
                      child: Text("Finish Transaction"),
                      onPressed: () {
                        finalTransaction(
                            currentMemberID, currentMemberName, dataList);
                      },
                    ),
                  ))
            ]))));
  }
}
// End of page template and page functionality

class CheckinPg extends StatefulWidget {
  CheckinPg({Key key, this.site}) : super(key: key);
  final site;
  @override
  CheckinPgState createState() => CheckinPgState();
}

class CheckinPgState extends State<CheckinPg> {
  //static AudioCache player = new AudioCache();

  var ori = Orientation.portrait;
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  GestureDetector camera;
  Expanded userInfo;
  String currentMemberID;
  String currentMemberName;
  CustomScrollView database;
  int cameraIndex = 0;
  FirebaseFirestoreService fs;
  Stream<QuerySnapshot> itemStream;
  Stream<QuerySnapshot> memberStream;
  changeCamera() {
    setState(() {
      cameraIndex = (cameraIndex + 1) % 2;
      print('tap' + cameraIndex.toString());
    });
  }

  Future validate(String code) async {
    var historyObj = await Firestore.instance
        .collection('Objects')
        .document(widget.site)
        .collection('History')
        .where("itemID", isEqualTo: code)
        .orderBy("timeCheckedOut",descending: true)
        .limit(1)
        .getDocuments();

    if (historyObj.documents.isNotEmpty &&
        historyObj.documents[0].data["timeCheckedIn"] == null) {
      fs.updateHistory(
          historyObj.documents[0].documentID,
          historyObj.documents[0].data["itemID"],
          historyObj.documents[0].data["itemName"],
          historyObj.documents[0].data["memID"],
          historyObj.documents[0].data["memName"],
          historyObj.documents[0].data["timeCheckedOut"],
          DateTime.now());
    } else {
      print("This item DNE or is currently not checked out yet.");
    }
  }

  @override
  void initState() {
    super.initState();

    fs = FirebaseFirestoreService(widget.site);

    camera = new GestureDetector(
      onTap: changeCamera,
      child: Card(
        margin: EdgeInsets.all(5.0),
        child: LiveBarcodeScanner(
          onBarcode: (code) {
            //print(code);
            if (dataSet.contains(code) == false) {
              dataSet.add(code);
              print(code);
              validate(code);

              //Create widgets for scanned items
              //debugPrint(dataWidget.toString());
            }
            return true;
          },
          cameraIndex: cameraIndex,
        ),
      ),
    );
    userInfo = Expanded(
        child: Card(
      margin: EdgeInsets.all(5.0),
      child: Center(child: Text("User Info")),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(title: Text('Check-in')),
        body: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Scaffold(
                body: Column(children: [
              Expanded(
                  flex: 8,
                  child: Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[camera, userInfo],
                    ),
                  )),
              Expanded(
                  flex: 10,
                  child: Card(
                      child: ListView.builder(
                    itemCount: dataList.length,
                    itemBuilder: (context, int index) {
                      return Dismissible(
                          key: Key(UniqueKey().toString()),
                          onDismissed: (direction) {
                            debugPrint(
                                index.toString() + " " + dataList[index]);
                            dataSet.remove(dataList[index]);
                            dataList.removeAt(index);
                            dataNameList.removeAt(index);
                          },
                          child: Column(children: <Widget>[
                            InkWell(
                                onTap: () {
                                  print("tapped");
                                },
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: ListTile(
                                        title: Text(dataNameList[index])))),
                            Divider()
                          ]));
                    },
                  ))),

            ]))));
  }
}
// End of page template and page functionality

class PageHome extends StatefulWidget {
  PageHome({Key key, this.referenceSite}) : super(key: key);

  final referenceSite;
  @override
  PageHomeState createState() => PageHomeState();
}

class PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LogFrog')),
      body: ListView(children: <Widget>[
        Card(child: Text(widget.referenceSite)),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: <Widget>[
                  Text("Chart  1"),
                  Container(
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height / 4,
                      child: DonutAutoLabelChart.withSampleData())
                ]))),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: <Widget>[
                  Text("Chart  2"),
                  Container(
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height / 4,
                      child: StackedFillColorBarChart.withSampleData())
                ])))
      ]),
    );
  }
}

//adapted from: https://medium.com/coding-with-flutter/take-your-flutter-tests-to-the-next-level-e2fb15641809
//date accessed: 3/21/2019

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title, this.callback}) : super(key: key);
  Function callback;
  final String title;
  bool testMode = false;
  bool loginComplete = false;

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final formKey = new GlobalKey<FormState>();

  String _email;
  String _password;
  String _authHint = '';

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  //TODO: Execute when username and password are successfully validated.
  void loginComplete() {
    widget.loginComplete = true;
    widget.callback();
  }

  //TODO: Connect with firebase Users document.
  void validateAndSubmit() async {
    if (validateAndSave()) {
      try {
        FirebaseUser user = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _email, password: _password);
        setState(() {
          loginComplete();
          _authHint = 'Success\n\nUser id: ${user.uid}';
        });
      } catch (e) {
        setState(() {
          _authHint = 'Sign In Error\n\n${e.toString()}';
        });
      }
    } else {
      setState(() {
        _authHint = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
                key: formKey,
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    new TextFormField(
                      key: new Key('email'),
                      decoration: new InputDecoration(labelText: 'Email'),
                      validator: (val) =>
                          val.isEmpty ? 'Email can\'t be empty.' : null,
                      onSaved: (val) => _email = val,
                    ),
                    new TextFormField(
                      key: new Key('password'),
                      decoration: new InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (val) =>
                          val.isEmpty ? 'Password can\'t be empty.' : null,
                      onSaved: (val) => _password = val,
                    ),
                    new RaisedButton(
                        key: new Key('login'),
                        child: new Text('Login',
                            style: new TextStyle(fontSize: 20.0)),
                        //testMode will enable or disable validation of username and password.
                        onPressed: widget.testMode == false
                            ? validateAndSubmit
                            : loginComplete),
                    new Container(
                        height: 80.0,
                        padding: const EdgeInsets.all(32.0),
                        child: buildHintText())
                  ],
                ))));
  }

  Widget buildHintText() {
    return new Text(_authHint,
        key: new Key('hint'),
        style: new TextStyle(fontSize: 18.0, color: Colors.grey),
        textAlign: TextAlign.center);
  }
}

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: Text("Manage Databases"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Log Out"),
              onTap: () {
                _signOut();
              },
            ),
          ],
        ));
  }
}

class DatabasePg extends StatefulWidget {
  DatabasePg({Key key, this.site}) : super(key: key);
  final String site;
  @override
  DatabasePgState createState() => DatabasePgState(site);
}

class DatabasePgState extends State<DatabasePg> {
  final TextEditingController _filter = new TextEditingController();
  final dio = new Dio();
  String _searchText = "";
  List<Equipment> items;
  List<Patrons> mems;
  StreamSubscription<QuerySnapshot> itemSub;
  StreamSubscription<QuerySnapshot> memSub;
  List<Equipment> filteredItems = new List();
  List<Patrons> filteredMems = new List();
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Database');
  String _mode = "Items";
  DatabasePgState(String site) {
    dataSite = site;
    db = new FirebaseFirestoreService(dataSite);
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filteredItems = items;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  @override
  void initState() {
    itemSub?.cancel();
    this.itemSub = db.getItems().listen((QuerySnapshot snapshot) {
      final List<Equipment> equipment = snapshot.documents
          .map((documentSnapshot) => Equipment.fromMap(documentSnapshot.data))
          .toList();
      setState(() {
        this.items = equipment;
        this.filteredItems = items;
      });
    });

    memSub?.cancel();
    this.memSub = db.getMembers().listen((QuerySnapshot snapshot) {
      final List<Patrons> members = snapshot.documents
          .map((documentSnapshot) => Patrons.fromMap(documentSnapshot.data))
          .toList();
      setState(() {
        this.mems = members;
        this.filteredMems = mems;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    itemSub?.cancel();
    super.dispose();
  }

  Widget _buildItemsList() {
    if (!(_searchText.isEmpty)) {
      List<Equipment> tempList = new List();
      for (int i = 0; i < items.length; i++) {
        if (items[i].name.toLowerCase().contains(_searchText.toLowerCase())) {
          tempList.add(items[i]);
        }
      }
      filteredItems = tempList;
    }
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
            color: Colors.black,
          ),
      itemCount: items == null ? 0 : filteredItems.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          title: Text(filteredItems[index].name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ViewItem(item: filteredItems[index])),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersList() {
    if (!(_searchText.isEmpty)) {
      List<Patrons> tempList = new List();
      for (int i = 0; i < mems.length; i++) {
        print(i.toString());
        if (mems[i]
                .firstName
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            mems[i]
                .lastName
                .toLowerCase()
                .contains(_searchText.toLowerCase())) {
          tempList.add(mems[i]);
        }
      }
      filteredMems = tempList;
    }
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
            color: Colors.black,
          ),
      itemCount: items == null ? 0 : filteredMems.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          title: Text(filteredMems[index].firstName +
              " " +
              filteredMems[index].lastName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ViewMember(mem: filteredMems[index])),
            );
          },
        );
      },
    );
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
              border: InputBorder.none,
              prefixIcon: new Icon(Icons.search),
              hintText: 'Search...'),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('Database');
        filteredItems = items;
        _filter.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle,
        leading: new IconButton(
          icon: _searchIcon,
          onPressed: _searchPressed,
        ),
        actions: <Widget>[
          DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: _mode,
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      child: Text('Items'),
                      value: 'Items',
                    ),
                    DropdownMenuItem(
                      child: Text('Members'),
                      value: 'Members',
                    )
                  ],
                  onChanged: (String mode) {
                    setState(() => _mode = mode);
                  }))
        ],
      ),
      body: Container(
          child: _mode == "Items" ? _buildItemsList() : _buildMembersList()),
      resizeToAvoidBottomPadding: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    _mode == "Items" ? AddItem() : AddMember()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddItem extends StatefulWidget {
  @override
  AddItemState createState() => AddItemState();
}

class AddItemState extends State<AddItem> {
  final DateTime dateNow = DateTime.now();
  bool validateName = false;
  @override
  void initState() {
    purchased.setString(DateFormat('MM-dd-yyyy').format(DateTime.now()));
    super.initState();
  }

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
  FieldWidget status =
      FieldWidget(title: 'Item Status', hint: '(Available, Unavailable)');
  bool cameraView = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.note_add),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title: Text("Add Item"),
        ),
        body: cameraView
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BarcodeScanner(
                    onBarcode: (code) {
                      setState(() {
                        itemId.setString(code);
                        cameraView = false;
                      });

                      return true;
                    },
                  ),
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
                              if (name.value.isEmpty) {
                                setState(() {
                                  name.validate = false;
                                });
                                _showToast(context,
                                    'Error: You must enter item name.');
                              } else if (itemId.value.isEmpty) {
                                _showToast(
                                    context, 'Error: You must scan item code.');
                              } else {
                                try {
                                  await db.createEquipment(
                                      name: name.value,
                                      itemID: itemId.value,
                                      itemType: itemType.value,
                                      purchased: dateNow,
                                      status: status.value,
                                      condition: condition.value,
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

class AddMember extends StatefulWidget {
  @override
  AddMemberState createState() => AddMemberState();
}

class AddMemberState extends State<AddMember> {
  final DateTime dateNow = DateTime.now();
  bool validateName = false;

  @override
  void initState() {
    //purchased.setString(DateFormat('MM-dd-yyyy').format(DateTime.now()));
    super.initState();
  }

  FieldWidget firstName =
      FieldWidget(title: 'First Name', hint: 'Member First Name');
  FieldWidget lastName =
      FieldWidget(title: 'Last Name', hint: 'Member Last Name');
  FieldWidget memberID = FieldWidget(
      title: 'Member ID',
      hint: 'A random ID will be generated if left empty',
      enabled: false);
  FieldWidget address =
      FieldWidget(title: 'Address', hint: 'Address of Member');
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BarcodeScanner(
                    onBarcode: (code) {
                      setState(() {
                        memberID.setString(code);
                        cameraView = false;
                      });

                      return true;
                    },
                  ),
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
                            child: Text("Submit"),
                            onPressed: () async {
                              if (firstName.value.isEmpty) {
                                setState(() {
                                  firstName.validate = false;
                                });
                                _showToast(context,
                                    'Error: You must enter item name.');
                              } else {
                                try {
                                  await db.createPatron(
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

class ViewItem extends StatefulWidget {
  ViewItem({Key key, this.item}) : super(key: key);
  final Equipment item;
  @override
  ViewItemState createState() => ViewItemState();
}

class ViewItemState extends State<ViewItem> {
  final DateTime dateNow = DateTime.now();
  bool validateName = false;
  bool editMode = false;
  @override
  void initState() {
    condition.setString(widget.item.condition);
    itemId.setString(widget.item.itemID);
    itemType.setString(widget.item.itemType);
    name.setString(widget.item.name);
    notes.setString(widget.item.notes);
    purchased.setString(widget.item.thisPurchased);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  FieldWidget condition = FieldWidget(
    title: 'Condition',
    hint: 'Item Condition:',
    enabled: false,
  );
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
  FieldWidget status = FieldWidget(
      title: 'Item Status', hint: '(Available, Unavailable)', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.edit),
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
                  status = FieldWidget(
                      title: 'Item Status',
                      hint: '(Available, Unavailable)',
                      enabled: true);
                  condition.setString(widget.item.condition);
                  itemId.setString(widget.item.itemID);
                  itemType.setString(widget.item.itemType);
                  name.setString(widget.item.name);
                  notes.setString(widget.item.notes);
                  purchased.setString(widget.item.thisPurchased);
                });
              }),
          actions: <Widget>[
            IconButton(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BarcodeScanner(
                    onBarcode: (code) {
                      setState(() {
                        itemId.setString(code);
                        cameraView = false;
                      });

                      return true;
                    },
                  ),
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
                              : RaisedButton(
                                  child: Text("Update"),
                                  onPressed: () async {
                                    if (name.value.isEmpty) {
                                      setState(() {
                                        name = FieldWidget(
                                            title: 'Item Name',
                                            hint: 'Enter Item Name',
                                            validate: true);
                                      });
                                      _showToast(context,
                                          'Error: You must enter item name.');
                                    } else if ((itemId.value.isEmpty)) {
                                      _showToast(context,
                                          'Error: You must scan an item code.');
                                    } else {
                                      try {
                                        await db.updateEquipment(
                                            name: name.value,
                                            itemID: itemId.value,
                                            itemType: itemType.value,
                                            purchased: dateNow,
                                            status: status.value,
                                            condition: condition.value,
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

class ViewMember extends StatefulWidget {
  ViewMember({Key key, this.mem}) : super(key: key);
  final Patrons mem;
  @override
  ViewMemberState createState() => ViewMemberState();
}

class ViewMemberState extends State<ViewMember> {
  final DateTime dateNow = DateTime.now();
  bool validateName = false;
  bool editMode = false;
  List<History> histories;
  StreamSubscription<QuerySnapshot> historySub;
  @override
  void initState() {
    historySub?.cancel();
    this.historySub =
        db.getMemberHistory(widget.mem.id).listen((QuerySnapshot snapshot) {
      final List<History> history = snapshot.documents
          .map((documentSnapshot) => History.fromMap(documentSnapshot.data))
          .toList();
      setState(() {
        this.histories = history;
      });
    });

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
                editMode = true;
                setState(() {
                  id = FieldWidget(
                      title: 'Item ID',
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
                  id.setString(widget.mem.id);
                  firstName.setString(widget.mem.firstName);
                  lastName.setString(widget.mem.lastName);
                  address.setString(widget.mem.emailAddress);
                  phone.setString(widget.mem.phone);
                  notes.setString(widget.mem.notes);
                });
              }),
          actions: <Widget>[
            IconButton(
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
                  BarcodeScanner(
                    onBarcode: (code) {
                      setState(() {
                        id.setString(code);
                        cameraView = false;
                      });

                      return true;
                    },
                  ),
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
                                  child: Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Column(
                                  children: <Widget>[
                                    Text("History",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Container(
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
                                            return new ListTile(
                                              title: Text(histories[index]
                                                  .itemName
                                                  .toString()),
                                              onTap: () {
//                                  Navigator.push(
//                                    context,
//                                    MaterialPageRoute(
//                                        builder: (context) => ViewItem(item: filteredItems[index])),
//                                  );
                                              },
                                            );
                                          },
                                        ))
                                  ],
                                ),
                              ))
                            ],
                          )),
                          editMode == false
                              ? Container()
                              : RaisedButton(
                                  child: Text("Update"),
                                  onPressed: () async {
                                    if (firstName.value.isEmpty) {
                                      setState(() {
                                        firstName = FieldWidget(
                                            title: 'Item Name',
                                            hint: 'Enter Item Name',
                                            validate: true);
                                      });
                                      _showToast(context,
                                          'Error: You must enter item name.');
                                    } else {
                                      try {
//                                        await db.updateEquipment(
//                                            name: name.value,
//                                            itemID: itemId.value,
//                                            itemType: itemType.value,
//                                            purchased: dateNow,
//                                            status: status.value,
//                                            condition: condition.value,
//                                            notes: notes.value);
//                                        Navigator.pop(context);
                                      } catch (e) {
                                        print(e.toString());
                                        _showToast(context, e.toString());
                                      }
                                    }
                                  },
                                ),
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
