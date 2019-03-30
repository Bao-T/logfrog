import 'package:flutter/material.dart';
import 'liveCamera.dart';
import 'dart:math' as math;
import "chartWidgets.dart";
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPg extends StatefulWidget {
  CheckoutPg({Key key}) : super(key: key);
  @override
  CheckoutPgState createState() => CheckoutPgState();}

class CheckoutPgState extends State<CheckoutPg> {
  LiveBarcodeScanner _Bscanner;
  var ori = Orientation.portrait;
  Set<String> data = {};
  List<Widget> dataWidget = [];
  Container camera;
  Expanded userInfo;
  CustomScrollView database;

  @override
  void initState() {
    super.initState();
    _Bscanner = LiveBarcodeScanner(
      onBarcode: (code) {
        //print(code);
        setState(() {
          if (data.contains(code) == false) {
            data.add(code);
            dataWidget.add(Text(code));
            //debugPrint(dataWidget.toString());
          }
        });
        return true;
      },
    );
    camera = Container(
      margin: EdgeInsets.all(5.0),
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
                Text(data.toString()),
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
        /*
        appBar: AppBar(
            title: Text('Check-In')
        ),*/
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
                child: CustomScrollView(
                  shrinkWrap: true,
                  slivers: <Widget>[
                    SliverPadding(
                        padding: const EdgeInsets.all(20.0),
                        sliver: SliverList(
                          delegate:
                              SliverChildListDelegate(dataWidget.toList()),
                        )),
                  ],
                ),
              )
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
      body: ListView(
          children: <Widget>[
            Card(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(children: <Widget>[
                    Text("Chart  1"),
                    Container( width: MediaQuery.of(context).size.width/2, height: MediaQuery.of(context).size.height/4, child: DonutAutoLabelChart.withSampleData())
                  ])
              )),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: <Widget>[
                      Text("Chart  2"),
                      Container( width: MediaQuery.of(context).size.width/2, height: MediaQuery.of(context).size.height/4, child: StackedFillColorBarChart.withSampleData())
                    ])
                ))
          ]
      ),
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
