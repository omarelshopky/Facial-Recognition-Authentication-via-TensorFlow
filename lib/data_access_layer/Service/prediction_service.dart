import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/database.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/image_converter.dart';


class PredictionService {
  // To build Singleton
  static final PredictionService _faceNetService = PredictionService._internal();

  final DatabaseService _databaseService = DatabaseService();
  late Interpreter _interpreter;
  late List _predictedData;
  double threshold = 1.0;


  factory PredictionService() {
    return _faceNetService;
  }
  // To build Singleton
  PredictionService._internal();


  // Getter & Setter for the attribute
  get predictedData => _predictedData;
  set predictedData(val) => _predictedData = val;

  /// Loads the Deep Learning model from storage
  Future loadModel() async {
    Delegate delegate;

    try {
      if(Platform.isAndroid){
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
                isPrecisionLossAllowed: false,
                inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
                inferencePriority1: TfLiteGpuInferencePriority.minLatency,
                inferencePriority2: TfLiteGpuInferencePriority.auto,
                inferencePriority3: TfLiteGpuInferencePriority.auto
            )
        );
      }else{ // IOS
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              waitType: TFLGpuDelegateWaitType.active
          ),
        );
      }

      _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite', options: InterpreterOptions()..addDelegate(delegate));
    } catch (e) {
      // print(e);
    }
  }


  /// Crops the [detectedFace] from the [image]
  _cropFace(CameraImage image, Face detectedFace, {double offset = 10.0}) {
    imglib.Image convertedImage = ImageConverter.convertCameraImage(image);
    double x = detectedFace.boundingBox.left - offset;
    double y = detectedFace.boundingBox.top - offset;
    double w = detectedFace.boundingBox.width + offset;
    double h = detectedFace.boundingBox.height + offset;

    return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  }


  /// Transforms an [image] to List of data
  Float32List imageToByteListFloat32(imglib.Image image) {
    // input size = 112
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);

        // mean: 128 & std: 128
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }


  /// Crops the [detectedFace] then transforms it to model input
  List _preProcess(CameraImage image, Face detectedFace) {
    imglib.Image croppedImage = _cropFace(image, detectedFace);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    return  imageToByteListFloat32(img);
  }


  /// Passes the image to the prediction model to get its output
  void setCurrentPrediction(CameraImage image, Face face) {
    List input = _preProcess(image, face);

    // Reshapes input and output to model format
    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    // Runs and transforms the data
    _interpreter.run(input, output);
    output = output.reshape([192]);

    _predictedData = List.from(output);
  }


  /// Do inference on the previous output
  String predict() {
    /// search closer user prediction if exists
    return _searchResult(_predictedData);
  }


  /// Searches about the result in the DB
  String _searchResult(List predictedData) {
    Map<String, dynamic> data = _databaseService.db;

    /// if no faces saved
    if (data.isEmpty) return "";

    double minDist = 999, currDist = 0.0;
    String result = "";

    /// search the closest result
    for (String label in data.keys) {
      currDist = _euclideanDistance(data[label], predictedData);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        result = label;
      }
    }
    return result;
  }


  /// Returns the sqrt of the Euclidean Distance between two lists [e1] & [e2]
  double _euclideanDistance(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }
}
