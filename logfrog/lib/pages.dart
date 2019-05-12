import 'package:flutter/material.dart';
import "chartWidgets.dart"; //does this do anything???
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';
import 'equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets.dart'; //does this do anything???
//import 'package:audioplayers/audio_cache.dart';
import 'package:intl/intl.dart';
import 'patrons.dart';
import 'package:logfrog/services/authentication.dart';
import 'history.dart';
import "package:qr_mobile_vision/qr_camera.dart";

bool frontCamera = true;

String
    dataSite; //site for the user- tells firebase which initial document to access

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
  //static AudioCache player = new AudioCache();
  var ori = Orientation.portrait; //camera orientation
  //Setting up lists for dealing with end transactions
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  GestureDetector camera; //setting up camera
  Expanded userInfo;
  String
      currentMemberID; //member ID of student  (AKA patron) checking out equipment
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
    } else if (currentMemberID != null &&
        await fs.equipmentNotCheckedOut(code)) {
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
      //player.play(alarmAudioPath);
    } else {
      //If it has reached this point:  The barcode scanned was not a student id
      //There is no currentMemberID set or the equipment does not exist or it is in firebase as 'checked out'
      //We want to alert students if:
      //Case 1:  There is no currentMemberID and the scanned barcode was not for a known student
      if (currentMemberID == null) {
        //make widget which shows popup with "scan a member id"
      } else if (!(await fs.equipmentExists(code))) {
        //Case 2: Invalid equipment ID
        //make widget popup that shows "equipment qr code not recognized, cannot checkout. Check that this equipment is entered for the school site"
      } else if (!(await fs.equipmentNotCheckedOut(code))) {
        //Case 3: Equipment is shown as already checked out
        //make popup that shows "equipment is currently checked out.  Please checkin first."
      } else {
        //default case
        print("Unknown error as occured!");
      }
    }
  }

  // Popups for the error cases above
  //Adapted from: https://medium.com/@nils.backe/flutter-alert-dialogs-9b0bb9b01d28
  //input of error title and error message strings
  void _showDialog(String errorTitle, String errorText) {
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
                            dataSet.remove(dataList[index]); //Remove the code
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
                      color: Colors.green,
                      child: Text("Finish Transaction"),
                      onPressed: () {
                        //When button is pressed, will create history documents for each scanned item under the current user
                        finalTransaction(
                            currentMemberID, currentMemberName, dataList);
                        //Clearing transaction fields for next user
                        dataNameList.clear();
                        dataList.clear();
                        dataSet.clear();
                        currentMemberID =
                            null; //resetting currentMemberID to null to prevent other users from checking out under past user's name
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
  //static AudioCache player = new AudioCache();

  var ori = Orientation.portrait; //camera set up
  //Updating history variables
  Set<String> dataSet = {};
  List<String> dataList = [];
  List<String> dataNameList = [];
  List<Widget> dataWidget = [];
  //
  GestureDetector camera;
  //User info variables
  Expanded userInfo;
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
  Future validate(String code) async {
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
      fs.updateHistory(
          historyObj.documents[0].documentID,
          historyObj.documents[0].data["itemID"],
          historyObj.documents[0].data["itemName"],
          historyObj.documents[0].data["memID"],
          historyObj.documents[0].data["memName"],
          historyObj.documents[0].data["timeCheckedOut"],
          Timestamp.now());
    } else {
      print(
          "This item DNE or is currently not checked out yet."); //TODO: make a popup for this
    }
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
              width: 200.0,
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
                        validate(
                            code); //runs validate checks to set student doing scanning, set object being checked out, pop ups
                      }
                    });
                  }))),
    );

    //DO WE NEED THIS HERE?????  Userinfo is not necessary on checkin page  //TODO: delete????
    userInfo = Expanded(
        child: Card(
      margin: EdgeInsets.all(5.0),
      child: Center(child: Text("User Info")),
    ));
  }

  //Context for page while running
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //scaffolding layout
        appBar: AppBar(title: Text('Check-in')),
        body: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Scaffold(
                body: Column(children: [
              Expanded(
                  flex: 8,
                  child: Container(
                    //placing camera and userinfo square
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        camera,
                        userInfo
                      ], //Two children at top of page TODO: (possible we do not need userInfo here)
                    ),
                  )),
              Expanded(
                  flex: 10,
                  child: Card(
                      //list of items appearing at the bottom of the screen
                      child: ListView.builder(
                    itemCount: dataList.length,
                    itemBuilder: (context, int index) {
                      return Dismissible(
                          //Dismissible qr scanned will appear
                          key: Key(UniqueKey().toString()),
                          onDismissed: (direction) {
                            debugPrint(
                                index.toString() + " " + dataList[index]);
                            dataSet.remove(dataList[index]);
                            dataList.removeAt(index);
                            dataNameList.removeAt(index);
                          },
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
  final checkoutPeriod; //adding a allowed checkoutPeriod time frame (ex: 10 days) for equipment
  final referenceSite; //site name currently being accessed
  @override
  PageHomeState createState() => PageHomeState();
}

//Creating state of home page with statistics
class PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LogFrog')), //Display app name at top of app
      body: ListView(children: <Widget>[
        Card(child: Text(widget.referenceSite)), //displays site name at top
        Card(
            //Pie chart -> items in vs. items out vs. items out and late
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: <Widget>[
                  Text("Chart  1"),
                  Container(
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height / 4,
                      child: DonutAutoLabelChart.withSampleData()) //pie chart
                ]))),
        Card(
            child: Padding(
                //Bar chart ->  seperate items into types by keywords, then graph bars of in vs out
                padding: const EdgeInsets.all(16.0),
                child: Row(children: <Widget>[
                  Text("Chart  2"),
                  Container(
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height / 4,
                      child:
                          StackedFillColorBarChart.withSampleData()) //barchart
                ])))
      ]),
    );
  }
}

//Settings page for viewing/adjusting site content
class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);
  //Login information for re-verifying user in app before allowing them to make edits
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
            ListTile(
              //two options in setting page
              title: Text("Manage Databases"), //enter management/edit mode
              onTap: () {},
            ),
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
  List<dynamic> itemTypes;
  List<Patrons> mems;
  List<History> hist;
  List<Equipment> filteredItems = new List();
  List<Patrons> filteredMems = new List();
  List<History> filteredHist = new List();
  List<Widget> itemFilters;
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

  //Listener for search bar, detects if there is text in the bar
  //If it is, sets the search text to the detected text
  DatabasePgState(String site) {
    dataSite = site;
    fs = new FirebaseFirestoreService(dataSite);
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
    this.itemTypeSub = fs.getItemTypes().listen((DocumentSnapshot snapshot){
      itemTypes = snapshot.data["ItemTypes"];
      itemTypesMenu.add(DropdownMenuItem(
        child: Text('All'),
        value: '',
      ));
      itemTypesMenu.add(DropdownMenuItem(
        child: Text('None'),
        value: '_null_',
      ));
      for(int i = 0; i< itemTypes.length; i++ ){
        itemTypesMenu.add(DropdownMenuItem(
          child: Text(itemTypes[i].toString()),
          value: itemTypes[i].toString(),
        ));
      }
    });
    print(itemTypesMenu.length.toString());
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
            hist[i].memName.toLowerCase().contains(_searchText.toLowerCase())) {
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
    if (filterType == "Items") {
      return Column(
        children: <Widget>[
          Center(child: Text("Filters")),
          Divider(),
          ListTile(
            title: Text('Item Type'),
            trailing: DropdownButtonHideUnderline(child: DropdownButton(value: itemType, items: itemTypesMenu, onChanged: (String type){
              setState(() {
                itemType = type;
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
      return Container();
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
          ? FloatingActionButton(
              child: Icon(Icons.filter_list),
              onPressed: () {},
            )
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
  FieldWidget status = FieldWidget(
      title: 'Item Status',
      hint:
          '(Available, Unavailable)'); //Status for checking an item in and out
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
    status.setString(widget.item.status);
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
  FieldWidget status = FieldWidget(
      title: 'Item Status', hint: '(Available, Unavailable)', enabled: false);
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
                  status = FieldWidget(
                      title: 'Item Status',
                      hint: '(Available, Unavailable)',
                      enabled: true);
                  condition.setString(widget.item.condition);
                  itemId.setString(widget.item.itemID);
                  itemType.setString(widget.item.itemType);
                  name.setString(widget.item.name);
                  notes.setString(widget.item.notes);
                  purchased.setString(widget.item.thisPurchased);
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
                                      child: Text("Update"),
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
                                                notes: notes.value);
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
                                    ),
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
