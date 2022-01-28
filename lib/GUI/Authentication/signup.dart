import 'dart:io';
import 'dart:math' as math;
import 'package:auth_via_tf_facial_recognition/GUI/Widget/auth_button.dart';
import 'package:auth_via_tf_facial_recognition/GUI/Widget/camera_header.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/camera_service.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/prediction_service.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/face_painter.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/ml_kit_service.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';


class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  SignupState createState() => SignupState();
}


class SignupState extends State<Signup> {
  final MLKitService _mlKitService = MLKitService();
  final CameraService _cameraService = CameraService();
  final PredictionService _predictionService = PredictionService();

  late Future _initializeControllerFuture;
  bool _detectingFaces = false;
  bool pictureTaken = false;
  bool cameraInitialized = false;

  // switches when the user press the camera
  bool _saveImage = false;
  bool _bottomSheetVisible = false;

  late String imagePath;
  late Size imageSize;
  late Face? faceDetected;


  @override
  /// Disposes of the service when the widget is disposed.
  void dispose() {
    super.dispose();

    _cameraService.dispose();
  }


  @override
  void initState() {
    super.initState();

    _startUp();
  }


  /// Initializes the camera & Starts detecting faces
  void _startUp() async {
    _initializeControllerFuture = _cameraService.init();
    await _initializeControllerFuture;

    setState(() {
      cameraInitialized = true;
    });

    _detectFaces();
  }


  /// Draws rectangles when faces detected
  void _detectFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {

        if (_detectingFaces) return; // if its currently busy

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces.isNotEmpty) {
            setState(() {
              faceDetected = faces[0];
            });

            if (_saveImage) {
              _saveImage = false;
              _predictionService.setCurrentPrediction(image, faceDetected!);
            }
          } else {
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print("SIGNUP DETECT FACES ERROR>>>>>>>>>>>>>>>>>>>> " + e.toString());
          _detectingFaces = false;
        }
      }
    });
  }


  /// Handles Capture Image button pressed event
  Future<void> onShot() async {
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('No face detected!'),
          );
        },
      );

      return;

    } else {
      _saveImage = true;

      await Future.delayed(const Duration(milliseconds: 500));
      await _cameraService.cameraController.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      XFile file = await _cameraService.takePicture();

      setState(() {
        _bottomSheetVisible = true;
        pictureTaken = true;
        imagePath = file.path;
      });

      return;
    }
  }


  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  void _reload() {
    setState(() {
      _bottomSheetVisible = false;
      cameraInitialized = false;
      pictureTaken = false;
    });

    _startUp();
  }


  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Stack(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (pictureTaken) {
                    return SizedBox(
                      width: width,
                      height: height,
                      child: Transform(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: Image.file(File(imagePath)),
                          ),
                          transform: Matrix4.rotationY(mirror)),
                    );
                  } else {
                    return Transform.scale(
                      scale: 1.0,
                      child: AspectRatio(
                        aspectRatio: MediaQuery.of(context).size.aspectRatio,
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.fitHeight,
                            child: SizedBox(
                              width: width,
                              height: width *
                                  _cameraService
                                      .cameraController.value.aspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  CameraPreview(
                                      _cameraService.cameraController
                                  ),
                                  ((){
                                    if(faceDetected != null){
                                      return CustomPaint(
                                        painter: FacePainter(
                                            face: faceDetected!,
                                            imageSize: imageSize),
                                      );
                                    }
                                    return Container();
                                  }())
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            CameraHeader(
              "SIGN UP",
              onBackPressed: _onBackPressed,
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? AuthButton(
                _initializeControllerFuture,
                onPressed: onShot,
                isLogin: false,
                reload: _reload,
              )
            : Container());
  }
}
