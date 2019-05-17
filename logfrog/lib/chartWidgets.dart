import 'package:flutter/material.dart';

/// Donut chart with labels example. This is a simple pie chart with a hole in
/// the middle.
///
///
/// Adapted from: https://fluttersensei.com/posts/the-toobox-charts-for-flutter/
///
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';


//Graphing Data class for preparing item numbers in pages.dart graphing page
class GraphingData {
  final String title;
  final int itemNumber;
  final charts.Color color;

  GraphingData(this.title, this.itemNumber, Color color) : this.color = new charts.Color(r: color.red, g: color.green, b: color.blue, a: color.alpha, );//y: color.yellow);

}

//pie chart used in pages.dart for graphing all available items of a given type
class DonutAutoLabelChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  DonutAutoLabelChart(this.seriesList, {this.animate});


  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(seriesList,
        animate: animate,
        // Configure the width of the pie slices to 60px. The remaining space in
        // the chart will be left as a hole in the center.
        //
        // [ArcLabelDecorator] will automatically position the label inside the
        // arc if the label will fit. If the label will not fit, it will draw
        // outside of the arc with a leader line. Labels can always display
        // inside or outside using [LabelPosition].
        //
        // Text style for inside / outside can be controlled independently by
        // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
        //
        // Example configuring different styles for inside/outside:
        //       new charts.ArcLabelDecorator(
        //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
        //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 60,
            arcRendererDecorators: [new charts.ArcLabelDecorator()]));
  }

}


/// Example of a stacked bar chart with three series, each rendered with
/// different fill colors.
class StackedFillColorBarChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  StackedFillColorBarChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      seriesList,
      animate: animate,
      // Configure a stroke width to enable borders on the bars.
      defaultRenderer: new charts.BarRendererConfig(
          groupingType: charts.BarGroupingType.stacked, strokeWidthPx: 2.0),
    );
  }
}

