import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/camera_service.dart';


class MLKitService {
  // To build Singleton
  static final MLKitService _cameraServiceService = MLKitService._internal();

  final CameraService _cameraService = CameraService();
  late FaceDetector _faceDetector;


  factory MLKitService() {
    return _cameraServiceService;
  }
  // To build Singleton
  MLKitService._internal();


  // Getter for the attribute
  get faceDetector => _faceDetector;


  /// Initialize the Face Detector
  void init() {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      const FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
  }


  /// Returns the [image] data to do the process
  InputImageData _preProcess(CameraImage image){
    return InputImageData(
      imageRotation: _cameraService.rotation,
      inputImageFormat: InputImageFormatMethods.fromRawValue(image.format.raw)!,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      planeData: image.planes.map(
            (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList(),
    );
  }


  /// Get faces from an [image]
  Future<List<Face>> getFacesFromImage(CameraImage image) async {
    InputImageData _firebaseImageMetadata = _preProcess(image);

    // Transform the image input
    InputImage _firebaseVisionImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      inputImageData: _firebaseImageMetadata,
    );

    return await _faceDetector.processImage(_firebaseVisionImage);
  }
}
