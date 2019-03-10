import 'dart:core';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

final BarcodeDetector barcodeDetector =
    FirebaseVision.instance.barcodeDetector();

typedef bool BarcodeFoundCallback(String code);

class LiveBarcodeScanner extends StatefulWidget {
  LiveBarcodeScanner({
    @required this.onBarcode,
  });
  final Set<String> codes = {};

  /// This will be called with newly found barcode
  /// and should return [true] if the scanning can stop
  final BarcodeFoundCallback onBarcode;

  @override
  _LiveBarcodeScannerState createState() => _LiveBarcodeScannerState();
}

class _LiveBarcodeScannerState extends State<LiveBarcodeScanner> {
  CameraController controller;
  List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();

    availableCameras().then((newCameras) {
      setState(() {
        cameras = newCameras;
        controller = CameraController(cameras[0], ResolutionPreset.medium);
        controller.initialize().then((_) async {
          if (!mounted) {
            return;
          }

          await controller.startImageStream(imageStreamHandler);

          setState(() {});
        });
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  dynamic imageStreamHandler(CameraImage image) async {
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(
        image.planes[0].bytes,
        FirebaseVisionImageMetadata(
          rawFormat: image.format.raw,
          size: Size(image.width.toDouble(), image.height.toDouble()),
          planeData: image.planes.map((plane) {
            return FirebaseVisionImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              width: plane.width,
              height: plane.height,
            );
          }).toList(),
        ));

    final List<Barcode> scannedBarcode =
        await barcodeDetector.detectInImage(visionImage);

    for (int i = 0; i < scannedBarcode.length; i++) {
      if (widget.onBarcode(scannedBarcode[i].rawValue)) {
        setState(() => widget.codes.add(scannedBarcode[i].rawValue));
        //debugPrint(codeString);

        /*
        controller.stopImageStream().catchError((e) {
          switch (e.runtimeType) {
            case CameraException:
              return;
            default:
              throw (e);
          }
        });*/

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    /*return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Transform.rotate(angle: -math.pi/2, child: CameraPreview(controller)));*/

    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child:
                Transform.rotate(angle: -math.pi / 2, child: CameraPreview(controller)));
      } else if (orientation == Orientation.landscape) {
        return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Transform.rotate(
                angle: 0, child: CameraPreview(controller)));
      }
    });
    /*
    return Column(
        children: [AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ), Text(codeString)] */
  }
}
