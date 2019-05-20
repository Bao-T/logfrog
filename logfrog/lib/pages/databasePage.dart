import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:logfrog/firebase_service.dart';
import 'package:logfrog/classes/equipment.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logfrog/classes/patrons.dart';
import 'package:logfrog/classes/history.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:logfrog/pages/historyPages.dart';
import 'package:logfrog/pages/memberPages.dart';
import 'package:logfrog/pages/itemPages.dart';



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
  Timestamp endDate = Timestamp.now();
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


  //Main UI Builder
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

}
//End database page
