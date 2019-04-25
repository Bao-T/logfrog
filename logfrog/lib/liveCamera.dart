//https://github.com/mskrip/live_barcode_scanner/blob/master/lib/live_barcode_scanner.dart
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

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
        controller = CameraController(cameras[0], ResolutionPreset.high);
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
        setState(() => widget.codes.add(scannedBarcode[i].rawValue)); //this is where the barcodes are generated
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
    return AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Transform.scale(scale: 1, child: Transform.rotate(angle: 0, child: CameraPreview(controller))));
  }
}


class BarcodeScanner extends StatefulWidget {
  BarcodeScanner({
    @required this.onBarcode,
  });
  final Set<String> codes = {};

  /// This will be called with newly found barcode
  /// and should return [true] if the scanning can stop
  final BarcodeFoundCallback onBarcode;

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  CameraController controller;
  List<CameraDescription> cameras;
  bool barcodeFound = false;
  @override
  void initState() {
    super.initState();

    availableCameras().then((newCameras) {
      setState(() {
        cameras = newCameras;
        controller = CameraController(cameras[0], ResolutionPreset.high);
        controller.initialize().then((_) async {
          if (!mounted) {
            return;
          }

          await controller.startImageStream(imageStreamHandler);
          print("finished");
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
        controller.stopImageStream().catchError((e) {
          switch (e.runtimeType) {
            case CameraException:
              return;
            default:
              throw (e);
          }
        }
        );
        break;
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
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Transform.scale(scale: 1, child: Transform.rotate(angle: 0, child: CameraPreview(controller))));
  }
}