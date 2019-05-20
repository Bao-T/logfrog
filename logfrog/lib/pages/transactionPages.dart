import 'package:flutter/material.dart';
import 'package:logfrog/firebase_service.dart';
import 'package:logfrog/classes/equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audio_cache.dart';
import "package:qr_mobile_vision/qr_camera.dart";

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
  Text memNameWidget = Text("");
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
          memNameWidget = Text(currentMemberName);
          userInfo = Expanded(
              child: Card(
            margin: EdgeInsets.all(5.0),
            child: Center(child: memNameWidget),
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
    for (int i = 0; i < dataList.length; i += 1) {
      print(i);
      print(dataList);
      String itemID = dataList[i];
      print(itemID);
      await Firestore.instance
          .collection('Objects')
          .document(widget.site)
          .collection('Items')
          .document(itemID)
          .get()
          .then((item) {
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
      });
    }
    setState(() {
      currentMemberID = "";
      memNameWidget = Text("");
      currentMemberName = "";
      userInfo = Expanded(
          child: Card(
        margin: EdgeInsets.all(5.0),
        child: Center(child: memNameWidget),
      ));
      dataSet.clear();
      dataList.clear();
      dataNameList.clear();
      dataWidget.clear();
    });

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
//                                currentMemberID = "";
//                                currentMemberName = "";
//                                dataSet.clear();
//                                dataList.clear();
//                                dataNameList.clear();
//                                dataWidget.clear();
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
