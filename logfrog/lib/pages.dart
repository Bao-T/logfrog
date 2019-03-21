import 'package:flutter/material.dart';
import 'liveCamera.dart';
import 'dart:math' as math;
import "widgets.dart";

import 'package:firebase_auth/firebase_auth.dart';

class PageOne extends StatefulWidget {
  PageOne({Key key}) : super(key: key);
  @override
  PageOneState createState() => PageOneState();
}

class PageOneState extends State<PageOne> {
  LiveBarcodeScanner _Bscanner;
  var ori = Orientation.portrait;
  String data = "";
  Container camera;
  Expanded userInfo;
  CustomScrollView database;
  /*
  Container camera = Container(
    height: 120,
    margin: EdgeInsets.all(5.0),
    color: Colors.greenAccent,
    child: _Bscanner,
  );
  Expanded userInfo = Expanded(
    child: Container(
        margin: EdgeInsets.all(5.0),
        color: Colors.red,
        child: Text("User Info")),
  );
  CustomScrollView database = CustomScrollView(
    shrinkWrap: true,
    slivers: <Widget>[
      SliverPadding(
        padding: const EdgeInsets.all(20.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            <Widget>[
              Text(_Bscanner.codes.toString()),
            ],
          ),
        ),
      ),
    ],
  );
  */
  @override
  void initState() {
    super.initState();
    _Bscanner = LiveBarcodeScanner(
      onBarcode: (code) {
        //print(code);
        setState(() {
          if (data != code)
            data = code;
        });
        return true;
      },
    );
    camera = Container(
      margin: EdgeInsets.all(5.0),
      color: Colors.greenAccent,
      child: _Bscanner,
    );
    userInfo = Expanded(
      child: Container(
          margin: EdgeInsets.all(5.0),
          color: Colors.red,
          child: Text("User Info")),
    );
    database = CustomScrollView(
      shrinkWrap: true,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(20.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                Text(data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(5.0),
      child: Scaffold(body: OrientationBuilder(
        builder: (context, orientation) {
          ori = orientation;
          if (ori == Orientation.portrait) {
            return Column(children: [
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
                  child: CustomScrollView(
                    shrinkWrap: true,
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.all(20.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            <Widget>[
                              Text(data),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),)
            ]);
          } else {
            return Row(children: [
              Expanded(
                  flex: 3,
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[camera, userInfo],
                    ),
                  )),
              Expanded(flex: 7, child: CustomScrollView(
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.all(20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          Text(data),
                        ],
                      ),
                    ),
                  ),
                ],
              ))
            ]);
          }
        },
      )),
    ));
  }
}
// End of page template and page functionality

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key);
  @override
  PageHomeState createState() => PageHomeState();
}

class PageHomeState extends State<PageHome> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('LogFrog')
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

//adapted from: https://medium.com/coding-with-flutter/take-your-flutter-tests-to-the-next-level-e2fb15641809
//date accessed: 3/21/2019

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

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

  void validateAndSubmit() async {
    if (validateAndSave()) {
      try {
        FirebaseUser user = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _email, password: _password);
        setState(() {
          _authHint = 'Success\n\nUser id: ${user.uid}';
        });
      }
      catch (e) {
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
                        child: new Text('Login', style: new TextStyle(fontSize: 20.0)),
                        onPressed: validateAndSubmit
                    ),
                    new Container(
                        height: 80.0,
                        padding: const EdgeInsets.all(32.0),
                        child: buildHintText())
                  ],
                )
            )
        )
    );
  }

  Widget buildHintText() {
    return new Text(
        _authHint,
        key: new Key('hint'),
        style: new TextStyle(fontSize: 18.0, color: Colors.grey),
        textAlign: TextAlign.center);
  }
}