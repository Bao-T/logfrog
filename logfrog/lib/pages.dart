import 'package:flutter/material.dart';
import 'liveCamera.dart';
import 'dart:math' as math;
import "chartWidgets.dart";

class CheckoutPg extends StatefulWidget {
  CheckoutPg({Key key}) : super(key: key);
  @override
  CheckoutPgState createState() => CheckoutPgState();
}

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
