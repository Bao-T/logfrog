import 'package:cloud_firestore/cloud_firestore.dart' as db;
import 'package:flutter/material.dart';
import 'package:logfrog/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logfrog/models/todo.dart';
import 'dart:async';
import 'package:logfrog/pages.dart';
import 'package:logfrog/firebase_service.dart';


class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> _todoList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;
  Query _todoQuery;
  FirebaseFirestoreService fs;
  bool _isEmailVerified = false;

  int _bottomNavBarIndex = 0;
  CheckoutPg checkoutPg;
  CheckinPg checkinPg;
  DatabasePg databasePg;
  PageHome pgHome;
  SettingsPage settingpg;
  List<Widget> pageList;
  List<dynamic> databases;
  String currentSite;
  Widget currentPage;
  int checkoutPeriodActual;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();

    _todoList = new List();
    _todoQuery = _database
        .reference()
        .child("todo")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription =
        _todoQuery.onChildChanged.listen(_onEntryChanged);
    Future getDatabases() async{
      var document = await db.Firestore.instance.collection('Users').document(widget.userId).get();
      var siteDocument = await db.Firestore.instance.collection(document.data["databases"][0].toString()).document(currentSite).get(); //gets the checkoutPeriod for the first site
      setState(() {
        databases = document.data["databases"]; //databases that user has access to
        currentSite = databases[0].toString(); //name of current stite
        checkoutPeriodActual = siteDocument.data["checkoutPeriod"]; //checkout period to determine if items are overdue for a site
        checkoutPg = CheckoutPg(site: currentSite);
        checkinPg = CheckinPg(site: currentSite);
        pgHome = PageHome(referenceSite: widget.userId, checkoutPeriod: checkoutPeriodActual ); //calling statistics page with site and allowed checkout period to display out/in items and late items
        databasePg = new DatabasePg(
          site: currentSite,
        );
        settingpg = SettingsPage(
            userId: widget.userId,
            auth: widget.auth,
            onSignedOut: widget.onSignedOut,
            site: currentSite,);
        pageList = [
          pgHome,
          checkoutPg,
          checkinPg,
          databasePg,
          settingpg
        ];
        currentPage = pgHome;
      });
    }
     //Change Site to access different sites

    try {
      getDatabases();
    }
    catch(exception){
      _signOut();
    }
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail() {
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Please verify account in the link sent to email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content:
              new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] =
          Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  _addNewTodo(String todoItem) {
    if (todoItem.length > 0) {
      Todo todo = new Todo(todoItem.toString(), widget.userId, false);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  _updateTodo(Todo todo) {
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteTodo(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        _todoList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(
                    child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new todo',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _addNewTodo(_textEditingController.text.toString());
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  Widget _showTodoList() {
    if (_todoList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _todoList.length,
          itemBuilder: (BuildContext context, int index) {
            String todoId = _todoList[index].key;
            String subject = _todoList[index].subject;
            bool completed = _todoList[index].completed;
            String userId = _todoList[index].userId;
            return Dismissible(
              key: Key(todoId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteTodo(todoId, index);
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: (completed)
                        ? Icon(
                            Icons.done_outline,
                            color: Colors.green,
                            size: 20.0,
                          )
                        : Icon(Icons.done, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      _updateTodo(_todoList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(
          child: Text(
        "Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _bottomNavBarIndex,
          onTap: (int index) {
            setState(() {
              //Temp page selector
              if (index == 3){
                bool failedAttempt = false;
                showDialog(
                  barrierDismissible: false,
                    context: context,
                builder: (BuildContext context){
                      TextEditingController passwordControl = new TextEditingController(
                      );
                  return AlertDialog(
                    title: new Text("Please enter your password"),
                    content: TextField(
                      obscureText: true,
                      controller: passwordControl,
                        decoration: new InputDecoration(
                          hintText: "Password",
                          errorText: failedAttempt ? 'Error authenticating password' : null,
                        )
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                      child: Text("Authenticate"),
                      onPressed: () async{
                       bool validate = await widget.auth.reauthenticate(passwordControl.text);
                       if (validate == true){
                         setState(() {
                           _bottomNavBarIndex = index;
                           currentPage = pageList[index];
                         });

                         Navigator.of(context).pop();
                       }
                       else
                         {
                           print("failed");
                           passwordControl.clear();
                           setState(() {
                             failedAttempt = true;
                           });

                         }
                      }
                    )]
                  );
                }
                );
              }
              else {
                _bottomNavBarIndex = index;
                currentPage = pageList[index];
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.file_upload),
              title: new Text('Check-Out'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.file_download),
              title: new Text('Check-In'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.storage),
              title: new Text('Database'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.settings),
              title: new Text('Settings'),
            ),
          ]),
    );
  }
}
