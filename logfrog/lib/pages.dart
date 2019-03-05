import 'package:flutter/material.dart';

class PageOne extends StatefulWidget {
  PageOne({Key key}) : super(key: key);
  @override
  PageOneState createState() => PageOneState();
}

class PageOneState extends State<PageOne> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        child: Column(children: [
          Expanded(
              flex: 4,
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AspectRatio(
                        aspectRatio: 3.0 / 4.0,
                        child: Container(
                          height: 120,
                          margin: EdgeInsets.all(5.0),
                          color: Colors.greenAccent,
                          child: Text("Camera"),
                        )),
                    Expanded(
                      child: Container(
                          margin: EdgeInsets.all(5.0),
                          color: Colors.red,
                          child: Text("User Info")),
                    )
                  ],
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
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),
                        const Text('I\'m dedicating every day to you'),
                        const Text('Domestic life was never quite my style'),
                        const Text('When you smile, you knock me out, I fall apart'),
                        const Text('And I thought I was so smart'),

                      ],
                    ),
                  ),
                ),
              ],
            )
          )
        ]),
      ),
    );
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
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
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
