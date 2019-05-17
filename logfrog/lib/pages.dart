import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import "chartWidgets.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';
import 'equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets.dart'; //does this do anything???
import 'package:audioplayers/audio_cache.dart';
import 'package:intl/intl.dart';
import 'patrons.dart';
import 'package:logfrog/services/authentication.dart';
import 'history.dart';
import "package:qr_mobile_vision/qr_camera.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

bool frontCamera = false;

const alarmAudioPath = "beep.mp3"; //check in checkout scanner beep

//Checkout Page:  Students will open this page to checkout equipment _________________________________________
/*To checkout:  First scan student id-> barcode will be used to check if student exists in site database
                                        if student exists, set current student to that student
                scan equipment -> if equipment exists AND is not checked out, creates history object for transaction
                                  (ALLOWS STUDENTS TO REMOVE ITEMS BEFORE FINAL PUSH IF THEY CHANGE THEIR MIND???)
                WHEN SCANNING DONE AND STUDENTS EXIT OUT(??) pushes final transaction up to firebase

                              */
class CheckoutPg extends StatefulWidget {
  CheckoutPg({Key key, this.site}) : super(key: key);
  final site;
  @override
  CheckoutPgState createState() => CheckoutPgState();
}

class CheckoutPgState extends State<CheckoutPg> {
  static AudioCache player = new AudioCache();
  var ori = Orientation.portrait; //camera orientation
  //Setting up lists for dealing with end transactions
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  GestureDetector camera; //setting up camera
  Expanded userInfo;
  String currentMemberID =
      ""; //member ID of student  (AKA patron) checking out equipment
  String currentMemberName; //name of student currently checking out equipment
  CustomScrollView database;
  int cameraIndex = 0;
  FirebaseFirestoreService fs;
  Stream<QuerySnapshot>
      itemStream; //stream for equipment query (IS THIS FOR ALL ITEMS?)
  Stream<QuerySnapshot>
      memberStream; //stream for members query (is this ALL students??)
  //Setting up camera for scanning
  changeCamera() {
    setState(() {
      cameraIndex = (cameraIndex + 1) % 2;
      print('tap' + cameraIndex.toString());
    });
  }

  Future<void> validate(BuildContext context, String code) async {
    //checking if a student exists under the current scanned barcode
    print(fs.patronExists(code));
    if (await fs.patronExists(code)) {
      Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection("Members")
          .document(code)
          .get()
          .then((doc) {
        //retrieves snapshot of that student
        currentMemberName = doc.data['firstName'] + ' ' + doc.data['lastName'];
        print(currentMemberName);
        setState(() {
          userInfo = Expanded(
              child: Card(
            margin: EdgeInsets.all(5.0),
            child: Center(child: Text(currentMemberName)),
          ));
        });
      });
      currentMemberID = code;
    } else if (currentMemberID != "" && await fs.equipmentNotCheckedOut(code)) {
      //If not a student, possibly a object
      //If the currentMemberID shows a student as checking out, allows scan to proceed
      //check if is equipment and it is not checked out
      objectCollection //retrieves snapshot of that student
          .document(widget.site)
          .collection("Items")
          .document(code)
          .get()
          .then((doc) {
        setState(() {
          //adds the valid equipment barcode and name
          dataList.add(code);
          dataNameList.add(doc.data['Name']);
        });
      });
      player.play(alarmAudioPath);
    } else {
      //If it has reached this point:  The barcode scanned was not a student id
      //There is no currentMemberID set or the equipment does not exist or it is in firebase as 'checked out'
      //We want to alert students if:
      //Case 1:  There is no currentMemberID and the scanned barcode was not for a known student
      //Case 1:  There is no currentMemberID and the scanned barcode was not for a known student
      if (currentMemberID == "") {
        //make widget which shows popup with "scan a member id"
        _showDialog(
            context, "Member Checkout Error", "Please scan student ID first");
      } else if (!(await fs.equipmentExists(code))) {
        //Case 2: Invalid equipment ID
        _showDialog(context, "Equipment Checkout Error",
            "Equipment QR code not recognized.  Please check this equipment is entered for this school site.");
      } else if (!(await fs.equipmentNotCheckedOut(code))) {
        //Case 3: Equipment is shown as already checked out
        _showDialog(context, "Equipment Checkout Error",
            "Equipment has already been checked out!  Please check item back in first if you wish to check it out");
      } else {
        //default case
        _showDialog(
            context, "Unknown Checkout Error", "Unknown error as occured!");
        print("Unknown error as occured!");
      }
    }
  }

  // Popups for the error cases above
  //Adapted from: https://medium.com/@nils.backe/flutter-alert-dialogs-9b0bb9b01d28
  //input of error title and error message strings
  void _showDialog(BuildContext context, String errorTitle, String errorText) {
    //
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          //displays a popup window over the rest of the screen which closes when "close" is pressed
          title: new Text(errorTitle),
          content: new Text(errorText),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //init state of checkout page
  @override
  void initState() {
    super.initState();
    fs = FirebaseFirestoreService(widget.site); //connecting to firebase
    //setting up camera
    camera = new GestureDetector(
      onTap: () {},
      child: Card(
          //camera state setup
          margin: EdgeInsets.all(5.0),
          child: new SizedBox(
              width: 200.0,
              height: 300.0,
              child: new QrCamera(
                  front: frontCamera,
                  onError: (context, error) => Text(
                        error.toString(),
                        style: TextStyle(color: Colors.red),
                      ),
                  qrCodeCallback: (code) {
                    //if
                    setState(() {
                      if (dataSet.contains(code) == false) {
                        dataSet.add(code); //adds code to codes seen
                        validate(context,
                            code); //runs validate checks to set student doing scanning, set object being checked out, pop ups
                      }
                    });
                  }))),
    );
    //User info for scanned users displayed by camera view
    userInfo = Expanded(
        child: Card(
      margin: EdgeInsets.all(5.0),
      child: Center(child: Text("User Info")),
    ));
  }

  //Builds transaction when button is pushed
  //Builds new history object for each scanned barcode
  Future<dynamic> finalTransaction(
      String memID, String memName, List<String> itemIds) async {
    //For each item scanned, builds a history object
    for (int i = 0; i < dataList.length; i++) {
      String itemID = dataList[i];
      var item = await Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection('Items')
          .document(itemID)
          .get();
      String itemName = item.data["Name"].toString();
      Timestamp timeCheckedIn; //null for now, will be filled when equipment
      Timestamp timeCheckedOut = Timestamp.now();
      Equipment currentItem = Equipment.fromMap(item.data);
      print(currentItem.itemID);
      currentItem.setStatus("unavailable");
      fs.updateEquipment(
          name: currentItem.name,
          itemID: currentItem.itemID,
          itemType: currentItem.itemType,
          purchased: currentItem.purchasedTimestamp,
          status: currentItem.status,
          lastCheckedOut:
              timeCheckedOut, //added for speeding up graph computations
          condition: currentItem.condition,
          notes: currentItem.notes);
      fs.createHistory(
          itemID: itemID,
          itemName: itemName,
          memID: memID,
          memName: memName,
          timeCheckedIn: null, //Note that null is the default timeCheckedIn
          timeCheckedOut: timeCheckedOut);
    }
    return null;
  }

  //Building context for page: aligning camera view, user info, etc.
  @override
  Widget build(BuildContext context) {
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
                      children: <Widget>[
                        camera,
                        userInfo
                      ], //top row  of screen has the camera and the userinfo displays
                    ),
                  )),
              Expanded(
                  flex: 10,
                  child: Card(
                      color: Colors.green[100],
                      //Pops up checked out objects when they process below camer and user info
                      child: ListView.builder(
                        itemCount: dataList.length,
                        itemBuilder: (context, int index) {
                          return Dismissible(
                              //For each key, if the box that appears can be dismissed to cancel the transaction
                              key: Key(UniqueKey().toString()),
                              onDismissed: (direction) {
                                //IF DISMISSED:
                                debugPrint(
                                    index.toString() + " " + dataList[index]);
                                dataSet
                                    .remove(dataList[index]); //Remove the code
                                dataList.removeAt(index);
                                dataNameList.removeAt(index); //remove the name
                              },
                              //NOT USED- location for adding a ontap action for the equipment cards
                              //
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
                          //
                          //NOT USED
                        },
                      ))),
              Expanded(
                  //Final transaction button widget
                  flex: 1,
                  child: SizedBox.expand(
                    child: RaisedButton(
                      color: currentMemberID == "" ? Colors.grey : Colors.green,
                      child: Text("Finish Transaction"),
                      onPressed: currentMemberID == ""
                          ? () {}
                          : () {
                              //When button is pressed, will create history documents for each scanned item under the current user
                              finalTransaction(
                                  currentMemberID, currentMemberName, dataList);
                              //Clearing transaction fields for next user
                              setState(() {
                                currentMemberID = "";
                                currentMemberName = "";
                                dataSet.clear();
                                dataList.clear();
                                dataNameList.clear();
                                dataWidget.clear();
                              }); //resetting currentMemberID to null to prevent other users from checking out under past user's name
                            },
                    ),
                  ))
            ]))));
  }
}
// End of CheckOutPage____________________________________

//CheckInPage for scanning in checked out items__________________________________________
//Will not need users to scan their ids to check items back in, just scan item
//If it is checked out, it will let the user check the item back in
//If it is not checked out, will throw a popup informing user
class CheckinPg extends StatefulWidget {
  CheckinPg({Key key, this.site}) : super(key: key);
  final site;
  @override
  CheckinPgState createState() => CheckinPgState();
}

class CheckinPgState extends State<CheckinPg> {

  static AudioCache player = new AudioCache();
  var ori = Orientation.portrait; //camera set up
  //Updating history variables
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataItemNameList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  //
  GestureDetector camera;
  //User info variables
  //Container userInfo;
  String currentMemberID = '';
  String currentMemberName = '';
  //
  CustomScrollView database;
  int cameraIndex = 0;
  //Firebase database and streams
  FirebaseFirestoreService fs;
  Stream<QuerySnapshot> itemStream;
  Stream<QuerySnapshot> memberStream;
  //
  //Setup camera
  changeCamera() {
    setState(() {
      cameraIndex = (cameraIndex + 1) % 2;
      print('tap' + cameraIndex.toString());
    });
  }

  //Upon code being scanned, update the history
  Future validate(BuildContext context, String code) async {
    var historyObj = await Firestore
        .instance //get the historyObj from firebase (search by itemID)
        .collection('Objects')
        .document(widget.site)
        .collection('History')
        .where("itemID", isEqualTo: code)
        .orderBy("timeCheckedOut", descending: true)
        .limit(1)
        .getDocuments();

    //Note that this must search through all items stored with that ID
    if (historyObj.documents.isNotEmpty &&
        historyObj.documents[0].data["timeCheckedIn"] == null) {
      //item must have been checked out to be checked back in
      var item = await Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection('Items')
          .document(code)
          .get();
      Equipment currentItem = Equipment.fromMap(item.data);
      print(currentItem.itemID);
      currentItem.setStatus("available");
      fs.updateEquipment(
          name: currentItem.name,
          itemID: currentItem.itemID,
          itemType: currentItem.itemType,
          purchased: currentItem.purchasedTimestamp,
          status: currentItem.status,
          condition: currentItem.condition,
          lastCheckedOut: currentItem.lastCheckedOut, //added for graph page
          notes: currentItem.notes);
      fs.updateHistory(
          historyObj.documents[0].documentID,
          historyObj.documents[0].data["itemID"],
          historyObj.documents[0].data["itemName"],
          historyObj.documents[0].data["memID"],
          historyObj.documents[0].data["memName"],
          historyObj.documents[0].data["timeCheckedOut"],
          Timestamp.now());
      dataList.add(historyObj.documents[0].data["itemID"]);
      dataItemNameList.add(historyObj.documents[0].data["itemName"]);
      dataNameList.add(historyObj.documents[0].data["memName"]);
    } else {
      if (!(historyObj.documents.isNotEmpty)) {
        _showDialog(context, "CheckIn Equipment Error",
            "This equipment item is not in the system and cannot be checked back in");
      } else {
        _showDialog(context, "CheckIn Equipment Error",
            "This item has not been checked out yet, cannot be checked back in.");
      }
    }
  }

  void _showDialog(BuildContext context, String errorTitle, String errorText) {
    //
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          //displays a popup window over the rest of the screen which closes when "close" is pressed
          title: new Text(errorTitle),
          content: new Text(errorText),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //Setting up checkin page initially
  @override
  void initState() {
    fs = FirebaseFirestoreService(widget.site);
    super.initState();
    camera = new GestureDetector(
      //setting up camera
      onTap: () {},
      child: Card(
          //Camera on side
          margin: EdgeInsets.all(5.0),
          child: new SizedBox(
              width: 370.0,
              height: 300.0,
              child: new QrCamera(
                  //QR scanner
                  front: frontCamera,
                  onError: (context, error) => Text(
                        error.toString(),
                        style: TextStyle(color: Colors.red),
                      ),
                  qrCodeCallback: (code) {
                    //When qr code is scanned
                    setState(() {
                      if (dataSet.contains(code) == false) {
                        dataSet.add(code); //adds code to codes seen
                        player.play(alarmAudioPath);
                        validate(context,
                            code); //runs validate checks to set student doing scanning, set object being checked out, pop ups
                      }
                    });
                  }))),
    );

    //DO WE NEED THIS HERE?????  Userinfo is not necessary on checkin page  //TODO: delete????
    // userInfo = Expanded(
    //   child: Card(
    // margin: EdgeInsets.all(5.0),
    //child: Center(child: Text("User Info")),
    //));
    //userInfo = Container();
  }

  //Context for page while running
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //scaffolding layout
        appBar: AppBar(title: Text('Check-in')),
        body: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                child: Column(children: [
              Expanded(
                  flex: 8,
                  child: Container(
                    //placing camera and userinfo square
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        camera
                      ], //Two children at top of page TODO: (possible we do not need userInfo here)
                    ),
                  )),
              Expanded(
                  flex: 10,
                  child: Card(
                      color: Colors.yellow[100],
                      //list of items appearing at the bottom of the screen
                      child: ListView.builder(
                        itemCount: dataList.length,
                        itemBuilder: (context, int index) {
                          return Column(children: <Widget>[
                            InkWell(
                                onTap: () {
                                  print("tapped");
                                },
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: ListTile(
                                      title: Text(dataItemNameList[index]),
                                      trailing: Text(dataNameList[index]),
                                    ))),
                            Divider()
                          ]);
                        },
                      ))),
            ]))));
  }
}
// End of Checkin Page________________________________________________________

//Home AKA Site Statistics Page_____________________________________________________
//Will provide a quick overview of state of site's supplies
//Graph for number available and number unavailable of different types of equipment
//Percentage of checked out material that is overdue
class PageHome extends StatefulWidget {
  PageHome({Key key, this.referenceSite, this.checkoutPeriod})
      : super(key: key);
  final referenceSite; //site statistics being viewed
  final checkoutPeriod; //length of site checkout period
  @override
  PageHomeState createState() => PageHomeState();
}

//Creating state of home page with statistics
class PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container();
  }

// // get snapshots of all data when page opens
//  FirebaseFirestoreService fs;
//  StreamSubscription<QuerySnapshot> itemSub;
//  StreamSubscription<DocumentSnapshot> itemTypeSub;
//  List<dynamic> itemTypes;
//  List<Equipment> items;
//  //map sortedItems;
//  var pieChartSeries; //overall data series
//  var barChartSeries; //list of chart.Series data
//  var sortedItems;
//  //searching items
//  @override
//  void initState() {
//    fs = new FirebaseFirestoreService(widget.referenceSite);
//    print(widget.referenceSite);
//    //initialize the current equipment for the site
//    itemSub?.cancel();
//    this.itemSub = fs.getItems().listen((QuerySnapshot snapshot) {
//      final List<Equipment> equipment = snapshot.documents
//          .map((documentSnapshot) => Equipment.fromMap(documentSnapshot.data))
//          .toList(); //Making list of equipment objects from stored firebase equipments
//      setState(() {
//        //After pulling firebase stored equipment snapshots, sets them as the settings list of equipment we have
//        this.items = equipment;
//      });
//    });
//    //Getting the item types for the site
//    itemTypeSub?.cancel();
//    this.itemTypeSub = fs.getItemTypes().listen((DocumentSnapshot snapshot) {
//      itemTypes = snapshot.data["ItemTypes"]; //should be a list of item type strings
//      this.sortedItems = _buildItemsList();
//      _makeCharts();
//    });
//
//
//    super.initState();
//  }
//
//  //Disposing of query stream subscriptions
//  @override
//  void dispose() {
//    itemSub?.cancel();
//    itemTypeSub?.cancel();
//    super.dispose();
//  }
//  //searching items for search text
//
//  //
//  Map _buildItemsList() {
//    //set up a map for each data type
//    Map<String,dynamic> typesSorted = {};
//    typesSorted["makePieChart"] = [0, 0, 0];
//    print(typesSorted.isEmpty);
//    for (int i = 0; i < itemTypes.length; i++) {
//      typesSorted[itemTypes[i].toString()] = [
//        0,
//        0,
//        0
//      ]; //will have number in, number out, and number overdue for each type
//      //[Available, Unavailable, Overdue]
//    }
//    print(typesSorted);
//    //sort items into types and three categories
//    for (int i = 0; i < items.length; i++) {
//      var type = items[i].itemType.toLowerCase(); //gets item type
//      var inOrOut = items[i].status; //gets item status "Available" or "Unavailable"
//      if (inOrOut == "available") {
//        //increments available
//        typesSorted[type][0] = typesSorted[type][0] + 1;
//        typesSorted["makePieChart"][0] = typesSorted["makePieChart"][0] + 1;
//      } else {
//        //Status is unavailable, determine if checked in or checked out
////        Timestamp dateOut =
////            items[i].lastCheckedOut; //Timestamp for last checked out date
////        //Have a Timestamp now, get number of days from current to lastCheckedOut
////        var difference = (dateOut.toDate().difference(DateTime.now()).inDays);
////
////        ///24 * 60 ^ 60 * 1000; //set difference to number of days
////        if (difference > widget.checkoutPeriod) {
////          //overdue
////          typesSorted[type][2] = typesSorted[type][2] + 1;
////          typesSorted["makePieChart"][2] = typesSorted["makePieChart"][2] + 1;
////        } else {
//          //Just checked out, not overdue
//          typesSorted[type][1] = typesSorted[type][1] + 1;
//          typesSorted["makePieChart"][1] = typesSorted["makePieChart"][1] + 1;
// //       }
//      }
//    }
//
//    //returning set up list widget of bar graph
//    return typesSorted;
//  }
//
//  void _makeCharts(){
//     //all sorting done in below function
//    //now, make the contents sorted items into a data series and a list of data series
//    var pieSeries = [
//      new GraphingData(
//          'Available Items', sortedItems["makePieChart"][0], Colors.green),
//      new GraphingData(
//          'Unavailable Items', sortedItems["makePieChart"][1], Colors.yellow),
////      new GraphingData(
////          'Overdue Items', sortedItems["makePieChart"][2], Colors.red),
//    ];
//    this.pieChartSeries = [
//      new Series(
//        id: "All Items",
//        domainFn: (GraphingData gdata, _) => gdata.title,
//        measureFn: (GraphingData gdata, _) => gdata.itemNumber,
//        colorFn: (GraphingData gdata, _) => gdata.color,
//        data: pieSeries,
//      ),
//    ];
//    //setting up bar chart items
//    //list.add(thing) in dart for adding item to list
////    this.barChartSeries = [];
////    for (int i = 0; i < itemTypes.length; i++) {
////      //create list of series for each bar chart in future
////      barChartSeries.add(
////        new Series(
////          id: itemTypes[i],
////          domainFn: (GraphingData gdata, _) => gdata.title,
////          measureFn: (GraphingData gdata, _) => gdata.itemNumber,
////          colorFn: (GraphingData gdata, _) => gdata.color,
////          data: [
////            new GraphingData(
////                itemTypes[i], sortedItems[itemTypes[i]][0], Colors.green),
////            new GraphingData(
////                itemTypes[i], sortedItems[itemTypes[i]][1], Colors.yellow),
////            new GraphingData(
////                itemTypes[i], sortedItems[itemTypes[i]][2], Colors.red),
////          ],
////        ),
////      );
////    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text('LogFrog')), //Display app name at top of app
//      body: Center(
//          child: ListView(
//        children: <Widget>[
//          //Card(child: Text(widget.referenceSite)), //displays site name at top
//          Card(
//              //Pie chart -> items in vs. items out vs. items out and late
//              child: Padding(
//                  padding: const EdgeInsets.all(16.0),
//                  child: Row(children: <Widget>[
//                    Text("Items In, Out, and Overdue"),
//                    Container(
//                        width: MediaQuery.of(context).size.width / 2,
//                        height: MediaQuery.of(context).size.height / 4,
//                        child: new DonutAutoLabelChart(pieChartSeries,
//                            animate: true)) // new pie chart
//                  ]))),
////          Card(
////              child: ListView.separated(
////                  separatorBuilder: (context, index) => Divider(
////                        color: Colors.black,
////                      ),
////                  itemCount: items == null ? 0 : itemTypes.length,
////                  itemBuilder: (BuildContext context, int index) {
////                    return new Card(
////                        child: Padding(
////                            padding: const EdgeInsets.all(16.0),
////                            child: Row(children: <Widget>[
////                              Text("Number In vs Out: "), //star
////                              Container(
////                                width: MediaQuery.of(context).size.width / 2,
////                                height: MediaQuery.of(context).size.height / 4,
////                                child: new BarChart(
////                                  barChartSeries[index],
////                                  animate: true,
////                                ), //barchart
////                              )
////                            ])));
////                  })),
//        ],
//      )),
//    );
//  }
}

//Settings page for viewing/adjusting site content
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
//Page to access firebase management options- allow authorized users to create equipment and patrons of the app, and search equipment, patrons, and checkout/checkin histories
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

//Setting up database page
//setup Database page
class DatabasePg extends StatefulWidget {
  //Setup site name for accessing the correct database
  DatabasePg({Key key, this.site}) : super(key: key);
  final String site;
  @override
  DatabasePgState createState() => DatabasePgState(site);
}

//Running state for the database page in the app
class DatabasePgState extends State<DatabasePg> {
  //search bar set up
  final TextEditingController _filter = new TextEditingController();
  final dio = new Dio();
  String _searchText = "";
  //Site members/items/histories set up for searching
  List<Equipment> items;
  List<Patrons> mems;
  List<History> hist;
  List<Equipment> filteredItems = new List();
  List<Patrons> filteredMems = new List();
  List<History> filteredHist = new List();
  List<Widget> itemFilters;
  List<dynamic> itemTypes;
  List<DropdownMenuItem<String>> itemTypesMenu = new List();
  //Setting up query snapshots for the three collections of the site contained on firebase
  FirebaseFirestoreService fs;
  StreamSubscription<QuerySnapshot> itemSub;
  StreamSubscription<DocumentSnapshot> itemTypeSub;
  StreamSubscription<QuerySnapshot> memSub;
  StreamSubscription<QuerySnapshot> histSub;
  //Setting up search bar
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Database');
  String _mode = "Items";
  String itemType = '';
  String availability = '';
  String sort = '';
  bool order = true;

  Timestamp startDate;
  Timestamp endDate;
  //Listener for search bar, detects if there is text in the bar
  //If it is, sets the search text to the detected text
  DatabasePgState(String site) {
    fs = new FirebaseFirestoreService(site);
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filteredItems = items;
          filteredMems = mems;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  @override
  //searching items
  void initState() {
    //initialize the settings page equipment query stream
    itemSub?.cancel();
    this.itemSub = fs
        .getItemsQuery(itemType, availability, sort,
            order) //querying firebase for equipment items
        .listen((QuerySnapshot snapshot) {
      final List<Equipment> equipment = snapshot.documents
          .map((documentSnapshot) => Equipment.fromMap(documentSnapshot.data))
          .toList(); //Making list of equipment objects from stored firebase equipments
      setState(() {
        //After pulling firebase stored equipment snapshots, sets them as the settings list of equipment and items
        this.items = equipment;
        this.filteredItems = items;
      });
    });
    itemTypeSub?.cancel();
    this.itemTypeSub = fs.getItemTypes().listen((DocumentSnapshot snapshot) {

      setState(() {
        itemTypes = snapshot.data["ItemTypes"];
        itemTypesMenu.clear();
        itemTypesMenu.add(DropdownMenuItem(
          child: Text('All'),
          value: '',
        ));
        itemTypesMenu.add(DropdownMenuItem(
          child: Text('None'),
          value: '_null_',
        ));
        for (int i = 0; i < itemTypes.length; i++) {
          itemTypesMenu.add(DropdownMenuItem(
            child: Text(itemTypes[i].toString()),
            value: itemTypes[i].toString(),
          ));
        }
      });



    });

    //searching checkout/checkin histories
    histSub?.cancel();
    this.histSub = fs.getHistories().listen((QuerySnapshot snapshot) {
      final List<History> histories = snapshot.documents
          .map((documentSnapshot) => History.fromMap(documentSnapshot.data))
          .toList(); //Creating list of History objects from stored firebase histories
      setState(() {
        this.hist = histories;
        this.filteredHist = hist;
      });
    });

    //searching members
    memSub?.cancel();
    this.memSub = fs.getMembers().listen((QuerySnapshot snapshot) {
      final List<Patrons> members = snapshot.documents
          .map((documentSnapshot) => Patrons.fromMap(documentSnapshot.data))
          .toList(); //Creating list of Patrons class objects from stored firebase data for students/patrons of the site
      setState(() {
        this.mems = members;
        this.filteredMems = mems;
      });
    });

    super.initState();
  }

  //Disposing of settings object necessitates cancelling the query streams
  @override
  void dispose() {
    itemSub?.cancel();
    memSub?.cancel();
    histSub?.cancel();
    super.dispose();
  }

  //searching items for search text
  //
  Widget _buildItemsList() {
    if (!(_searchText.isEmpty)) {
      List<Equipment> tempList = new List();
      //Searches items for those with names containing the search phrase
      for (int i = 0; i < items.length; i++) {
        //convert names to lower case to standardize searching
        if (items[i].name.toLowerCase().contains(_searchText.toLowerCase())) {
          tempList.add(items[i]);
        }
      }
      filteredItems = tempList;
    }

    //Sets up search results for items
    //displaying them in a list
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
            color: Colors.black,
          ),
      itemCount: items == null ? 0 : filteredItems.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          //setting up the list entries
          title: Text(filteredItems[index].name),
          onTap: () {
            //ontap, pull up item details
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ViewItem(
                        item: filteredItems[index],
                        site: widget.site,
                      )),
            );
          },
        );
      },
    );
  }

  //searching members list with search text by first and last name
  Widget _buildMembersList() {
    if (!(_searchText.isEmpty)) {
      List<Patrons> tempList = new List();
      for (int i = 0; i < mems.length; i++) {
        //Searches for first or last name matches the search text when converted to lowercase adds to search results
        if (mems[i]
                .firstName
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            mems[i]
                .lastName
                .toLowerCase()
                .contains(_searchText.toLowerCase())) {
          //searches first and last name
          tempList.add(mems[i]);
        }
      }
      filteredMems = tempList;
    }
    //Setting up member name search results
    //returning set up list widget of search results
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
            color: Colors.black,
          ),
      itemCount: mems == null ? 0 : filteredMems.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          //display the results first and last name
          title: Text(filteredMems[index].firstName +
              " " +
              filteredMems[index].lastName),
          onTap: () {
            //if name is tapped, view the member
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ViewMember(mem: filteredMems[index], site: widget.site)),
            );
          },
        );
      },
    );
  }

  //Searching histories with search text for item name
  Widget _buildHistoriesList() {
    if (!(_searchText.isEmpty)) {
      List<History> tempList = new List();
      for (int i = 0; i < hist.length; i++) {
        //Looking for search histories which match a member name
        if (hist[i]
                .itemName
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            hist[i].memName.toLowerCase().contains(_searchText.toLowerCase()) ||
            hist[i].itemID.contains(_searchText) ||
            hist[i].memID.contains(_searchText)) {
          tempList.add(hist[i]);
        }
      }
      filteredHist = tempList;
    }
    //Setting up list to view histories when search is complete
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
            color: Colors.black,
          ),
      itemCount: hist == null ? 0 : filteredHist.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
            color: filteredHist[index].timeCheckedInString ==
                    "" //Green if checked in, red if checked out for current history state
                ? Colors.red[200]
                : Colors.green[200],
            child: ListTile(
              title: Text(filteredHist[index].memName),
              leading: Text(filteredHist[index].itemName),
              trailing: Text(filteredHist[index].timeCheckedOutString),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ViewHistory(hist: filteredHist[index])),
                );
              },
            ));
      },
    );
  }

  //Building overall list view depending on search mode
  Widget _buildListView(String mode) {
    if (mode == "Items") {
      return _buildItemsList();
    } else if (mode == "Members") {
      return _buildMembersList();
    } else if (mode == "History") {
      return _buildHistoriesList();
    } else {
      return Container();
    }
  }

  //Calls to populate the search bar when the icon is pressed
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
        filteredMems = mems;
        _filter.clear();
      }
    });
  }

  //Uses drawer widget
  //Filtering options for searching items
  Widget _getFilters(String filterType) {
    Timestamp startDate;
    Timestamp endDate;

    if (filterType == "Items") {
      return Column(
        children: <Widget>[
          Center(child: Text("Filters")),
          Divider(),
          ListTile(
            title: Text('Item Type'),
            trailing: DropdownButtonHideUnderline(
                child: DropdownButton(
                    value: itemType,
                    items: itemTypesMenu,
                    onChanged: (String type) {
                      setState(() {
                        itemType = type;
                        itemSub?.cancel();
                        this.itemSub = fs
                            .getItemsQuery(itemType, availability, sort, order)
                            .listen((QuerySnapshot snapshot) {
                          final List<Equipment> equipment = snapshot.documents
                              .map((documentSnapshot) =>
                                  Equipment.fromMap(documentSnapshot.data))
                              .toList();
                          setState(() {
                            this.items = equipment;
                            this.filteredItems = items;
                          });
                        });
                      });
                    })),
          ),
          Divider(),
          ListTile(
              title: Text('Item Status'),
              trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                      value: availability,
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          child: Text('All'),
                          value: '',
                        ),
                        DropdownMenuItem(
                          child: Text('Available'),
                          value: 'available',
                        ),
                        DropdownMenuItem(
                          child: Text('Unavailable'),
                          value: 'unavailable',
                        ),
                        DropdownMenuItem(
                          //TODO: remove, we don't support this
                          child: Text('Discontinued'),
                          value: 'discontinued',
                        )
                      ],
                      onChanged: (String avail) {
                        //Searching contents based on filters
                        setState(() {
                          availability = avail;
                          itemSub?.cancel();
                          this.itemSub = fs
                              .getItemsQuery(
                                  itemType, availability, sort, order)
                              .listen((QuerySnapshot snapshot) {
                            final List<Equipment> equipment = snapshot.documents
                                .map((documentSnapshot) =>
                                    Equipment.fromMap(documentSnapshot.data))
                                .toList();
                            setState(() {
                              this.items = equipment;
                              this.filteredItems = items;
                            });
                          });
                        });
                      }))),
          Divider(),
          ListTile(
              //Sorting the items based on values
              title: Text('Sort By'),
              trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                      value: sort,
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          child: Text('None'),
                          value: '',
                        ),
                        DropdownMenuItem(
                          child: Text('Item Name'),
                          value: 'Name',
                        ),
                        DropdownMenuItem(
                          child: Text('Date'),
                          value: 'Purchased',
                        ),
                      ],
                      onChanged: (String srt) {
                        setState(() {
                          sort = srt;
                          itemSub?.cancel();
                          this.itemSub = fs
                              .getItemsQuery(
                                  itemType, availability, sort, order)
                              .listen((QuerySnapshot snapshot) {
                            final List<Equipment> equipment = snapshot.documents
                                .map((documentSnapshot) =>
                                    Equipment.fromMap(documentSnapshot.data))
                                .toList();
                            setState(() {
                              this.items = equipment;
                              this.filteredItems = items;
                            });
                          });
                        });
                      }))),
          Divider(),
          ListTile(
              // Sorting results based on list  content order
              title: Text('Order'),
              trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                      //choosing option for sorting the results
                      value: order,
                      items: <DropdownMenuItem<bool>>[
                        DropdownMenuItem(
                          child: Text('Ascending'),
                          value: false,
                        ),
                        DropdownMenuItem(
                          child: Text('Descending'),
                          value: true,
                        ),
                      ],
                      onChanged: (bool ord) {
                        //when ordering is selected, sorts query results
                        setState(() {
                          order = ord;
                          itemSub?.cancel();
                          this.itemSub = fs
                              .getItemsQuery(
                                  itemType, availability, sort, order)
                              .listen((QuerySnapshot snapshot) {
                            final List<Equipment> equipment = snapshot.documents
                                .map((documentSnapshot) =>
                                    Equipment.fromMap(documentSnapshot.data))
                                .toList();
                            setState(() {
                              this.items = equipment;
                              this.filteredItems = items;
                            });
                          });
                        });
                      }))),
          Divider()
        ],
      );
    } else if (filterType == "Members") {
      return Container();
    } else if (filterType == "History") {
      return Column(children: <Widget>[
        Center(child: Text("Filters")),
        Divider(),
        ListTile(
          title: Text("Start Date"),
          trailing: this.startDate != null
              ? Text(DateFormat.yMd().format(this.startDate.toDate()))
              : Text(""),
          onTap: () {
            DatePicker.showDatePicker(context,
                showTitleActions: true,
                currentTime:
                    this.startDate != null ? this.startDate.toDate() : null,
                maxTime: this.endDate != null
                    ? this.endDate.toDate()
                    : DateTime.now(), onConfirm: (date) {
              setState(() {
                this.startDate = Timestamp.fromDate(date);
                print(DateFormat.yMd().format(date));
                this.histSub?.cancel();
                this.histSub = fs
                    .getHistoryQuery(
                        this.startDate,
                        Timestamp.fromDate(
                            this.endDate.toDate().add(new Duration(days: 1))))
                    .listen((QuerySnapshot snapshot) {
                  final List<History> histories = snapshot.documents
                      .map((documentSnapshot) =>
                          History.fromMap(documentSnapshot.data))
                      .toList(); //Creating list of History objects from stored firebase histories
                  setState(() {
                    this.hist = histories;
                    this.filteredHist = hist;
                  });
                });
              });
            });
          },
        ),
        Divider(),
        ListTile(
          title: Text("End Date"),
          trailing: this.endDate != null
              ? Text(DateFormat.yMd().format(this.endDate.toDate()))
              : Text(""),
          onTap: () {
            DatePicker.showDatePicker(context,
                showTitleActions: true,
                currentTime:
                    this.endDate != null ? this.endDate.toDate() : null,
                minTime:
                    this.startDate != null ? this.startDate.toDate() : null,
                maxTime: DateTime.now(), onConfirm: (date) {
              setState(() {
                this.endDate = Timestamp.fromDate(date);
                print(DateFormat.yMd().format(date));
                this.histSub?.cancel();
                this.histSub = fs
                    .getHistoryQuery(
                        this.startDate,
                        Timestamp.fromDate(
                            this.endDate.toDate().add(new Duration(days: 1))))
                    .listen((QuerySnapshot snapshot) {
                  final List<History> histories = snapshot.documents
                      .map((documentSnapshot) =>
                          History.fromMap(documentSnapshot.data))
                      .toList(); //Creating list of History objects from stored firebase histories
                  setState(() {
                    this.hist = histories;
                    this.filteredHist = hist;
                  });
                });
              });
            });
          },
        ),
      ]);
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    //Overall scaffolding, for drawer to choose search option, title, search bar
    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle,
        actions: <Widget>[
          new IconButton(
            icon: _searchIcon,
            onPressed: _searchPressed,
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              height: 50,
            ),
            Divider(),
            ListTile(
                title: Text("View"),
                trailing: DropdownButtonHideUnderline(
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
                          ),
                          DropdownMenuItem(
                            child: Text('History'),
                            value: 'History',
                          )
                        ],
                        onChanged: (String mode) {
                          setState(() => _mode = mode);
                        }))),
            Divider(),
            Container(
              height: 100,
            ),
            _getFilters(_mode)
          ],
        ),
      ),
      body: Container(child: _buildListView(_mode)),
      resizeToAvoidBottomPadding: false,
      floatingActionButton: _mode == "History"
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => _mode == "Items"
                          ? AddItem(site: widget.site)
                          : AddMember(site: widget.site)),
                );
              },
              child: Icon(Icons.add),
            ),
    );
  }
}
//End database page

//Adding a new item widgets
//For adding a new equipment/student
class AddItem extends StatefulWidget {
  AddItem({Key key, this.site}) : super(key: key);
  final String site;
  @override
  AddItemState createState() => AddItemState();
}

//Setting up AddItemWidget
class AddItemState extends State<AddItem> {
  final Timestamp dateNow =
      Timestamp.now(); //timetsamp of item creation in the database
  bool validateName = false; //boolean for determining if the name will be valid
  FirebaseFirestoreService
      fs; //declaring a instance of firestore to handle the transactions
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
  StatusWidget status = StatusWidget(
    title: 'Item Status',
  );
  //Status for checking an item in and out
  bool cameraView = false;

  @override
  //Setting up the widget, default purchased date is reformatted Timestamp of current time
  void initState() {
    print(widget.site);
    fs = FirebaseFirestoreService(widget.site);
    purchased
        .setString(DateFormat('MM-dd-yyyy').format(Timestamp.now().toDate()));
    super.initState();
  }

  @override
  //Scaffolding the item adding widget
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.note_add),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  //when icon is pressed, pops up the add item area
                  Navigator.pop(context);
                })
          ],
          title: Text("Add Item"),
        ),
        body: cameraView
            //Allows new qr code to be scanned for a added item, that way a item can be assigned a qr sticker if any are available
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new SizedBox(
                      width: 200.0,
                      height: 300.0,
                      child: new QrCamera(
                          front: frontCamera,
                          onError: (context, error) => Text(
                                error.toString(),
                                style: TextStyle(color: Colors.red),
                              ),
                          qrCodeCallback: (code) {
                            setState(() {
                              itemId.setString(code);
                              cameraView = false;
                            });
                          })),
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
                              //in item creation mode, when submit is pressed will create on firebase
                              if (name.value.isEmpty) {
                                setState(() {
                                  name.validate = false;
                                });
                                _showToast(context,
                                    'Error: You must enter item name.'); //must have a item name
                              } else if (itemId.value.isEmpty) {
                                _showToast(context,
                                    'Error: You must scan item code.'); //must have a id number for qr generation
                                //TODO:  add another else if for checking if the id exists in firebase???? and is nto alreaydy used for a student id???
                              } else {
                                try {
                                  await fs.createEquipment(
                                      //try to create the item
                                      name: name.value,
                                      itemID: itemId.value,
                                      itemType: itemType.value,
                                      purchased: dateNow,
                                      status: status.value,
                                      condition: condition.value,
                                      lastCheckedOut:
                                          dateNow, //default date last checked out to same as purchased date for new item
                                      notes: notes.value);
                                  await fs.updateItemTypes(
                                      itemType.value.toLowerCase());

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
//end equipment creation

//Adding a new patron to firebase
class AddMember extends StatefulWidget {
  AddMember({Key key, this.site}) : super(key: key);
  final String site;
  @override
  AddMemberState createState() => AddMemberState();
}

class AddMemberState extends State<AddMember> {
  final Timestamp dateNow = Timestamp
      .now(); //default timestamp is now....TODO: find out why we need this
  bool validateName = false;
  FirebaseFirestoreService fs;
  @override
  void initState() {
    //opening a firestore service for the correct class site
    fs = FirebaseFirestoreService(widget.site);
    super.initState();
  }

  //Setting up widget fields to collect new member info
  FieldWidget firstName =
      FieldWidget(title: 'First Name', hint: 'Member First Name');
  FieldWidget lastName =
      FieldWidget(title: 'Last Name', hint: 'Member Last Name');
  FieldWidget memberID = FieldWidget(
      title: 'Member ID',
      hint: 'A random ID will be generated if left empty',
      enabled: false);
  FieldWidget address =
      FieldWidget(title: 'Address', hint: 'Email address of Member');
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
                //Allowing new patron id codes from student IDs to be scanned when adding a member
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new SizedBox(
                      width: 200.0,
                      height: 300.0,
                      child: new QrCamera(
                          front: frontCamera,
                          onError: (context, error) => Text(
                                error.toString(),
                                style: TextStyle(color: Colors.red),
                              ),
                          qrCodeCallback: (code) {
                            setState(() {
                              memberID.setString(code);
                              cameraView = false;
                            });
                          })),
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
                            //when done filling info, add new patron to firestore
                            child: Text("Submit"),
                            onPressed: () async {
                              if (firstName.value.isEmpty) {
                                //must enter a first name field for new members
                                setState(() {
                                  firstName.validate = false;
                                });
                                _showToast(context,
                                    'Error: You must enter a member name.');
                              } else {
                                //TODO:  add check for memberID to make sure it is not used and is not a equipment ID already
                                try {
                                  await fs.createPatron(
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
//end new memeber/patron creation

class ViewItem extends StatefulWidget {
  ViewItem({Key key, this.item, this.site}) : super(key: key);
  final Equipment item;
  final String site;
  @override
  ViewItemState createState() => ViewItemState();
}

//view an equipment item and update variables
//Already has the equipment stored in the widget.item
class ViewItemState extends State<ViewItem> {
  final Timestamp dateNow =
      Timestamp.now(); //default timestamp is the current one
  bool validateName = false;
  bool editMode = false;
  FirebaseFirestoreService fs;
  @override
  void initState() {
    //fill all values
    fs = FirebaseFirestoreService(widget.site);
    condition.setString(widget.item.condition);
    itemId.setString(widget.item.itemID);
    itemType.setString(widget.item.itemType);
    name.setString(widget.item.name);
    notes.setString(widget.item.notes);
    status.setStatus(widget.item.status);
    purchased.setString(widget.item.thisPurchased);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  //Setting up item viewer
  FieldWidget condition = FieldWidget(
    title: 'Condition',
    hint: 'Item Condition:',
    enabled: false,
  );
  //Setting up viewer for equipment fields
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
  StatusWidget status = StatusWidget(title: 'Item Status', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons
                  .edit), //if entering edit mode, uses above FieldWidgets to edit content
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
                  status = StatusWidget(title: 'Item Status', enabled: true);
                  condition.setString(widget.item.condition);
                  itemId.setString(widget.item.itemID);
                  itemType.setString(widget.item.itemType);
                  name.setString(widget.item.name);
                  notes.setString(widget.item.notes);
                  purchased.setString(widget.item.thisPurchased);
                  status.setStatus(widget.item.status);
                });
              }),
          actions: <Widget>[
            IconButton(
                //closing edit mode
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
                //allow user to scan qr code to input updated qr
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new SizedBox(
                      width: 200.0,
                      height: 300.0,
                      child: new QrCamera(
                          front: frontCamera,
                          onError: (context, error) => Text(
                                error.toString(),
                                style: TextStyle(color: Colors.red),
                              ),
                          qrCodeCallback: (code) {
                            setState(() {
                              itemId.setString(code);
                              cameraView = false;
                            });
                          })),
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
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                      RaisedButton(
                                        child: Text(
                                            "Update"), //when update is pressed, update the equipment fields
                                        onPressed: () async {
                                          if (name.value.isEmpty) {
                                            setState(() {
                                              name = FieldWidget(
                                                title: 'Item Name',
                                                hint: 'Enter Item Name',
                                                validate: true,
                                                enabled: true,
                                              );
                                            });
                                            _showToast(context,
                                                'Error: You must enter an item name.');
                                          } else if ((itemId.value.isEmpty)) {
                                            _showToast(context,
                                                'Error: You must scan an item code.');
                                          } else {
                                            //TODO:  add itemID checks to make sure that it is not used in the equipemnt/patron classes already
                                            try {
                                              await fs.updateEquipment(
                                                  name: name.value,
                                                  itemID: itemId.value,
                                                  itemType: itemType.value,
                                                  purchased: dateNow,
                                                  status: status.value,
                                                  condition: condition.value,
                                                  lastCheckedOut:
                                                      dateNow, //set last checked out date to same as purchased date
                                                  notes: notes.value);
                                              await fs.updateItemTypes(
                                                  itemType.value.toLowerCase());
                                              Navigator.pop(context);
                                            } catch (e) {
                                              print(e.toString());
                                              _showToast(context, e.toString());
                                            }
                                          }
                                        },
                                      ),
                                      RaisedButton(
                                        color: Colors.red,
                                        child: Text("Delete"),
                                        onPressed: () async {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text("Delete Item"),
                                                    content: Text(
                                                        "Are you sure you want to delete this item? This will not reflect in the history logs and may unlink data."),
                                                    actions: <Widget>[
                                                      FlatButton(
                                                          child: Text("Delete"),
                                                          onPressed: () {
                                                            try {
                                                              fs.deleteEquipment(
                                                                  widget.item
                                                                      .itemID);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              print(
                                                                  e.toString());
                                                              _showToast(
                                                                  context,
                                                                  e.toString());
                                                            }
                                                          }),
                                                      FlatButton(
                                                          child: Text("Cancel"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }),
                                                    ]);
                                              });
                                        },
                                      ),
                                    ])
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
//end view/udpate equipment

//view/update member information
//Has the member information already from the list widgets above
class ViewMember extends StatefulWidget {
  ViewMember({Key key, this.mem, this.site}) : super(key: key);
  final Patrons mem; //has a Patrons class member
  final String site;
  @override
  ViewMemberState createState() => ViewMemberState();
}

class ViewMemberState extends State<ViewMember> {
  final Timestamp dateNow = Timestamp.now(); //TODO:  why do we need this???
  bool validateName = false;
  bool editMode = false;
  FirebaseFirestoreService fs;
  List<History>
      histories; //Will pull up the histories using a streamquery for this member
  StreamSubscription<QuerySnapshot> historySub;
  @override
  void initState() {
    fs = FirebaseFirestoreService(widget.site);
    historySub?.cancel();
    //Finding relevant histories
    this.historySub =
        fs.getMemberHistory(widget.mem.id).listen((QuerySnapshot snapshot) {
      final List<History> history = snapshot.documents
          .map((documentSnapshot) => History.fromMap(documentSnapshot.data))
          .toList();
      setState(() {
        this.histories = history;
      });
    });
    //Filling other member fields
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

  //Setting up FieldWidgets for editting member/patron variables
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
                editMode =
                    true; //if in edit mode, allow variables to be changed using above widgets
                setState(() {
                  id = FieldWidget(
                      title: 'ID',
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
                  id.setString(widget
                      .mem.id); //TODO:  add id checks for the members/patrons
                  firstName.setString(widget.mem.firstName);
                  lastName.setString(widget.mem.lastName);
                  address.setString(widget.mem.emailAddress);
                  phone.setString(widget.mem.phone);
                  notes.setString(widget.mem.notes);
                });
              }),
          actions: <Widget>[
            IconButton(
                //closing view mode
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
                  new SizedBox(
                      width: 200.0,
                      height: 300.0,
                      child: new QrCamera(
                          front: frontCamera,
                          onError: (context, error) => Text(
                                error.toString(),
                                style: TextStyle(color: Colors.red),
                              ),
                          qrCodeCallback: (code) {
                            setState(() {
                              id.setString(code);
                              cameraView = false;
                            });
                          })),
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
                                  //displaying history items associated with this member in a list
                                  child: Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Text("History",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.0))),
                                    Container(
                                        //displaying history items associated with the member
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
                                            return new Container(
                                                color: histories[index]
                                                            .timeCheckedInString !=
                                                        ''
                                                    ? Colors.green[200]
                                                    : Colors.red[200],
                                                child: ListTile(
                                                  title: Text(histories[index]
                                                      .itemName
                                                      .toString()),
                                                  trailing: Text(histories[
                                                          index]
                                                      .timeCheckedOutString),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ViewHistory(
                                                                  hist: histories[
                                                                      index])),
                                                    );
                                                  },
                                                ));
                                          },
                                        ))
                                  ],
                                ),
                              ))
                            ],
                          )),
                          editMode == false
                              ? Container()
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    RaisedButton(
                                      child: Text("Update"),
                                      onPressed: () async {
                                        if (firstName.value.isEmpty) {
                                          setState(() {
                                            firstName = FieldWidget(
                                                title: 'Item Name',
                                                hint: 'Enter Item Name',
                                                validate: true,
                                                enabled: true);
                                          });
                                          _showToast(context,
                                              'Error: You must enter item name.');
                                        } else {
                                          try {
                                            //print(id.value);
                                            await fs.updatePatrons(
                                                id.value,
                                                firstName.value,
                                                lastName.value,
                                                address.value,
                                                phone.value,
                                                notes.value);
                                            Navigator.pop(context);
                                          } catch (e) {
                                            print(e.toString());
                                            _showToast(context, e.toString());
                                          }
                                        }
                                      },
                                    ),
                                    RaisedButton(
                                      color: Colors.red,
                                      child: Text("Delete"),
                                      onPressed: () async {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                  title: Text("Delete Member"),
                                                  content: Text(
                                                      "Are you sure you want to delete this Member? This will not reflect in the history logs and may unlink data."),
                                                  actions: <Widget>[
                                                    FlatButton(
                                                        child: Text("Delete"),
                                                        onPressed: () {
                                                          try {
                                                            fs.deletePatron(
                                                                widget.mem.id);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            Navigator.pop(
                                                                context);
                                                          } catch (e) {
                                                            print(e.toString());
                                                            _showToast(context,
                                                                e.toString());
                                                          }
                                                        }),
                                                    FlatButton(
                                                        child: Text("Cancel"),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                  ]);
                                            });
                                      },
                                    )
                                  ],
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
//end user/Patron update

//view/update history
class ViewHistory extends StatefulWidget {
  ViewHistory({Key key, this.hist}) : super(key: key);
  final History hist;
  @override
  ViewHistoryState createState() => ViewHistoryState();
}

class ViewHistoryState extends State<ViewHistory> {
  final Timestamp dateNow = Timestamp
      .now(); //defaults to current date TODO: determine if we need this
  bool validateName = false;
  bool editMode = false;
  bool itemMode = false;
  bool memMode = false;
  @override
  void initState() {
    //initialize all history variables with the current firebase values
    itemID.setString(widget.hist.itemID);
    itemName.setString(widget.hist.itemName);
    memID.setString(widget.hist.memID);
    memName.setString(widget.hist.memName);
    timeCheckedIn.setString(widget.hist.timeCheckedInString);
    timeCheckedOut.setString(widget.hist.timeCheckedOutString);
    super.initState();
  }

  void updateWidget() {
    setState(() {});
  }

  //Setting up FieldWidgets for editing below
  FieldWidget itemID = FieldWidget(title: 'Item ID', hint: '', enabled: false);
  FieldWidget itemName =
      FieldWidget(title: 'Item Name', hint: '', enabled: false);
  FieldWidget memID = FieldWidget(title: 'Member ID', hint: '', enabled: false);
  FieldWidget memName =
      FieldWidget(title: 'Member Name', hint: '', enabled: false);
  FieldWidget timeCheckedIn =
      FieldWidget(title: 'Time Checked In', hint: '', enabled: false);
  FieldWidget timeCheckedOut =
      FieldWidget(title: 'Time Checked Out', hint: '', enabled: false);
  bool cameraView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
          title: editMode == false //Select view or edit history mode
              ? Text("History Details")
              : Text("Edit Details"),
        ),
        body: Builder(
            builder: (context) => Column(
                    //view history values
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                          child: ListView(
                        children: <Widget>[
                          itemID,
                          itemName,
                          memID,
                          memName,
                          timeCheckedIn,
                          timeCheckedOut
                        ],
                      )),
                    ])));
    //TODO: add edit mode here using the Field Widgets above
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
