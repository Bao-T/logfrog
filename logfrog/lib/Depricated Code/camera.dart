//import 'package:camera/camera.dart';
//import 'package:firebase_ml_vision/firebase_ml_vision.dart';
//import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
//import 'package:logfrog/firebase_service.dart'; //importing to generate history objects
//import 'detector_painters.dart';
//import 'utils.dart';
//
//
//
//void main() => runApp(MaterialApp(home: _MyHomePage()));
//
//class _MyHomePage extends StatefulWidget {
//  @override
//  _MyHomePageState createState() => _MyHomePageState();
//}
//
//
////creates a camera to scan barcodes with
////dependencies: camera/camera.dart
//class _MyHomePageState extends State<_MyHomePage> {
//  dynamic _scanResults; //barcode scan results
//  CameraController _camera; //creates a camera view for the user to see on the device screen
//  Detector _currentDetector = Detector.text; //Type of detector (Face, Text, Barcorde, etc.) being used by the camera
//  bool _isDetecting = false;
//  CameraLensDirection _direction = CameraLensDirection.back; //tells the program that we want to use the back camera, and not the front.
//
//  @override
//  void initState() {
//    super.initState();
//    _initializeCamera();
//  }
//
//  void _initializeCamera() async {
//    CameraDescription description = await getCamera(_direction);
//    ImageRotation rotation = rotationIntToImageRotation(
//      description.sensorOrientation, //makes sure that the orientation of the camera matches the current orientation of the device
//    );
//
//    //sets the default resolution for IOS devices
//    _camera = CameraController(
//      description,
//      defaultTargetPlatform == TargetPlatform.iOS //we are using an IOS device
//          ? ResolutionPreset.low //if the resolution of the IOS device is set to low by default, change the resolution to medium for the usage of the program
//          : ResolutionPreset.medium,
//    );
//    await _camera.initialize(); //initialize the camera
//
//    //returns the images that the camera is picking up to screen in a continuous stream
//    _camera.startImageStream((CameraImage image) {
//      if (_isDetecting) return; //if the camera is active, show the camera feed on the screen
//
//      _isDetecting = true;
//
//      //try catch block to catch errors and exceptions in the camera interface
//      //Actual camera scanning occurs here
//      detect(image, _getDetectionMethod(), rotation).then(
//            (dynamic result) {
//          setState(() {
//            _scanResults = result;
//          });
//          _isDetecting = false;
//        },
//      ).catchError(
//            (_) {
//          _isDetecting = false;
//        },
//      );
//    });
//  }
//
//  //setting up the barcode detection part of the program
//  HandleDetection _getDetectionMethod() {
////    final FirebaseVision mlVision = FirebaseVision.instance;
//
//    //TODO: Remove cases we don't need for our app (we should only be doing barcodes???)
//    switch (_currentDetector) {
//      case Detector.text: //use if the program will be detecting text //TODO: NOT USING?
//        return mlVision.textRecognizer().processImage;
//      case Detector.barcode: //use if the program will be detecting barcodes
//        return mlVision.barcodeDetector().detectInImage;
//      case Detector.label: //use if the program will be detecting objects //TODO: NOT USING?
//        return mlVision.imageLabeler().processImage;
//      case Detector.cloudLabel: //use if the program will be detecting clouds(?) //TODO: NOT USING?
//        return mlVision.cloudImageLabeler().processImage;
//      default:
//        assert(_currentDetector == Detector.face); //use if the program will be detecting human faces //TODO: NOT USING?
//        return mlVision.faceDetector().processImage;
//    }
//  }
//
//  //displays the results of the camera image detection
//  Widget _buildResults() {
//    const Text noResultsText = const Text('No results!'); //if nothing is being detected, print "No results!" to screen
//
//    //if no barcodes are being detected, if the camera has not been initialized, or if the camera does not exist in the program, return "No results!"
//    if (_scanResults == null ||
//        _camera == null ||
//        !_camera.value.isInitialized) {
//      return noResultsText;
//    }
//
//    CustomPainter painter;
//
//    //set the final height and width of the camera feed display on the screen
//    final Size imageSize = Size(
//      _camera.value.previewSize.height,
//      _camera.value.previewSize.width,
//    );
//
//    //depending on the detection type being used (faces, barcodes, etc), return results that make sense for the kind of detection being used
//    switch (_currentDetector) {
//      case Detector.barcode:
//        if (_scanResults is! List<Barcode>) return noResultsText;
//        painter = BarcodeDetectorPainter(imageSize, _scanResults);
//        break;
//      case Detector.face: //TODO : NOT USING???
//        if (_scanResults is! List<Face>) return noResultsText;
//        painter = FaceDetectorPainter(imageSize, _scanResults);
//        break;
//      case Detector.label: //TODO: NOT USING???
//        if (_scanResults is! List<ImageLabel>) return noResultsText;
//        painter = LabelDetectorPainter(imageSize, _scanResults);
//        break;
//      case Detector.cloudLabel: //TODO: NOT USING??
//        if (_scanResults is! List<ImageLabel>) return noResultsText;
//        painter = LabelDetectorPainter(imageSize, _scanResults);
//        break;
//      default:
//        assert(_currentDetector == Detector.text);
//        if (_scanResults is! VisionText) return noResultsText;
//        painter = TextDetectorPainter(imageSize, _scanResults);
//    }
//  //TODO: REMOVE SWITCH STATEMENT????
//    return CustomPaint(
//      painter: painter,
//    );
//  }
//
//  //Set the page styles that will be displayed
//  Widget _buildImage() {
//    return Container(
//      constraints: const BoxConstraints.expand(),
//      //if no camera is initialized, then initialize the camera
//      child: _camera == null
//          ? const Center(
//        child: Text(
//          'Initializing Camera...',
//          style: TextStyle(
//            color: Colors.green,
//            fontSize: 30.0,
//          ),
//        ),
//      )
//          : Stack(
//        fit: StackFit.expand,
//        children: <Widget>[
//          CameraPreview(_camera),
//          _buildResults(),
//        ],
//      ),
//    );
//  }
//
//  void _toggleCameraDirection() async {
//    if (_direction == CameraLensDirection.back) {
//      _direction = CameraLensDirection.front;
//    } else {
//      _direction = CameraLensDirection.back;
//    }
//
//    await _camera.stopImageStream();
//    await _camera.dispose();
//
//    setState(() {
//      _camera = null;
//    });
//
//    _initializeCamera();
//  }
//
//
//  //choose which detector the program will use
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('ML Vision Example'),
//        actions: <Widget>[
//          PopupMenuButton<Detector>(
//            onSelected: (Detector result) {
//              _currentDetector = result;
//            },
//            itemBuilder: (BuildContext context) => <PopupMenuEntry<Detector>>[
//              const PopupMenuItem<Detector>(
//                child: Text('Detect Barcode'),
//                value: Detector.barcode,
//              ),
//              const PopupMenuItem<Detector>(
//                child: Text('Detect Face'),
//                value: Detector.face,
//              ),
//              const PopupMenuItem<Detector>(
//                child: Text('Detect Label'),
//                value: Detector.label,
//              ),
//              const PopupMenuItem<Detector>(
//                child: Text('Detect Cloud Label'),
//                value: Detector.cloudLabel,
//              ),
//              const PopupMenuItem<Detector>(
//                child: Text('Detect Text'),
//                value: Detector.text,
//              ),
//            ],
//          ),
//        ],
//      ),
//      body: _buildImage(),
//      floatingActionButton: FloatingActionButton(
//        onPressed: _toggleCameraDirection,
//        child: _direction == CameraLensDirection.back
//            ? const Icon(Icons.camera_front)
//            : const Icon(Icons.camera_rear),
//      ),
//    );
//  }
//
//
//}