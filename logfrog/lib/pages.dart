import 'package:flutter/material.dart';
import 'liveCamera.dart';
import "chartWidgets.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';
import 'equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPg extends StatefulWidget {
  CheckoutPg({Key key}) : super(key: key);
  @override
  CheckoutPgState createState() => CheckoutPgState();
}

class CheckoutPgState extends State<CheckoutPg> {
  LiveBarcodeScanner _Bscanner;
  var ori = Orientation.portrait;
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<Widget> dataWidget = [];
  Card camera;
  Expanded userInfo;
  CustomScrollView database;

  @override
  void initState() {
    super.initState();
    _Bscanner = LiveBarcodeScanner(
      onBarcode: (code) {
        //print(code);
        setState(() {
          if (dataSet.contains(code) == false) {
            dataSet.add(code);
            dataList.add(code);
            //Create widgets for scanned items
            //debugPrint(dataWidget.toString());
          }
        });
        return true;
      },
    );
    camera = Card(
      margin: EdgeInsets.all(5.0),
      child: _Bscanner,
    );
    userInfo = Expanded(
      child: Card(
          margin: EdgeInsets.all(5.0),
          color: Colors.red,
          child: Text("User Info")),
    );
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
                  flex: 4,
                  child: Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[camera, userInfo],
                    ),
                  )),
              Expanded(
                  flex: 6,
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
                          },
                          child: Column(children: <Widget>[
                            InkWell(
                                onTap: () {
                                  print("tapped");
                                },
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: ListTile(
                                        title: Text(dataList[index])))),
                            Divider()
                          ]));
                    },
                  )))
            ]))));
  }
}
// End of page template and page functionality

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key);
  @override
  PageHomeState createState() => PageHomeState();
}

class PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LogFrog')),
      body: ListView(children: <Widget>[
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

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: Text("Change Username"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Change Password"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Change Email"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Manage Databases"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Log Out"),
              onTap: () {},
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
  StreamSubscription<QuerySnapshot> itemSub;
  List<Equipment> filteredItems = new List();
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Database');
  String site;
  FirebaseFirestoreService db = new FirebaseFirestoreService();

  DatabasePgState(String site) {
    this.site = site;
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
    this.itemSub = db.getItems(site: this.site).listen((QuerySnapshot snapshot) {
      final List<Equipment> equipment = snapshot.documents
          .map((documentSnapshot) => Equipment.fromMap(documentSnapshot.data))
          .toList();
      setState(() {
        this.items = equipment;
        this.filteredItems = items;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    itemSub?.cancel();
    super.dispose();
  }
  Widget _buildList() {
    if (!(_searchText.isEmpty)) {
      List<Equipment> tempList = new List();
      for (int i = 0; i < items.length; i++) {
        if (items[i].thisName
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tempList.add(items[i]);
        }
      }
      filteredItems = tempList;
    }
    return ListView.builder(
      itemCount: items == null ? 0 : filteredItems.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          title: Text(filteredItems[index].thisName),
          onTap: () => print(filteredItems[index].thisName),
        );
      },
    );
  }

  void _addPressed(){} //TODO: implement adding new entry

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
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
      ),
      body: Container(child: _buildList()),
      resizeToAvoidBottomPadding: false,
      floatingActionButton: FloatingActionButton(
          onPressed: _addPressed,
          child: Icon(Icons.add),
      ),
    );
  }
}
