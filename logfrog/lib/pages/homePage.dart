import 'package:flutter/material.dart';

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
// Creates the first page for the application
// Current creates a logo screen plus application instructions
//TODO: Creating state of home page with statistics
class PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("LogFrog")),
      body: Center(
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(padding: EdgeInsets.all(32.0), child: Image.asset('assets/'
                  'FrogLog_Clear.png', scale: 2,)),
              Text("Welcome to LogFrog Item Inventory System."),
              Padding(padding: EdgeInsets.all(16.0),
                child: Text("Add items and members on the database page. Make sure"
                    " you have compatible QR or Barcodes for your item/member. Use"
                    " our check-in and check-out pages to log the history of your "
                    "items."),
              )
            ],
          ),
        ),
      ),
    );
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