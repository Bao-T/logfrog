import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //adding firebase stuff
import 'firebase_service.dart';

void main() => runApp(MyApp());

Firestore db = Firestore
    .instance; //Initially getting firestore instance for use in database access

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'LogFrog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'LogFrog'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _bottomNavBarIndex = 0;
  CheckoutPg checkoutPg;
  PageHome pgHome;
  LoginPage loginPg;
  SettingsPage settingpg;

  List<Widget> pageList;
  Widget currentPage;

  @override
  void initState() {
    checkoutPg = CheckoutPg();
    pgHome = PageHome();
    settingpg = SettingsPage();
    loginPg = LoginPage(title: 'LogFrog Login', callback: this.callback);
    pageList = [pgHome, checkoutPg, checkoutPg, new DatabasePg(site: "Test",), settingpg];
    currentPage = pgHome;
    super.initState();
  }

  void callback() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    if (loginPg.loginComplete == false) {
      return loginPg;
    } else {
      return Scaffold(
        body: currentPage,
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _bottomNavBarIndex,
            onTap: (int index) {
              setState(() {
                _bottomNavBarIndex = index;
                //Temp page selector
                currentPage = pageList[index];
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
}
// Pages and their states
