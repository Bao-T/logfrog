import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:logfrog/login_utils/authentication.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.auth, this.userId, this.onSignedOut, this.site})
      : super(key: key);
  //Login information for re-verifying user in app before allowing them to make edits
  final String site;
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _SettingsPageState();
}

//Log in/log out mechanics
//uses on sign out tapped in the Widget(build)

class _SettingsPageState extends State<SettingsPage> {
  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();  //ignore this error, it is actually a function.
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    //Scaffold of settings page
    //TWo initial options for settings page:  log out of site and manage database
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          children: <Widget>[
//            ListTile(
//              //two options in setting page
//              title: Text("Email History"), //enter management/edit mode
//              onTap: () {
//                FirebaseFirestoreService fs =
//                    FirebaseFirestoreService(widget.site);
//                fs..getHistoryLog(); //TODO
//              },
//            ),
            ListTile(
              title: Text("Log Out"), //sign out of edit mode
              onTap: () {
                _signOut(); //calls above sign out function
              },
            ),
          ],
        ));
  }
}
