import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logfrog/services/authentication.dart';
import 'package:logfrog/pages/root_page.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return new MaterialApp(
        title: 'Flutter login demo',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.green,
        ),
        home: new RootPage(auth: new Auth()));
  }
}