import 'package:auth_via_tf_facial_recognition/GUI/Widget/app_text_field.dart';
import 'package:auth_via_tf_facial_recognition/GUI/intro_screen.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Model/user.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/camera_service.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/database.dart';
import 'package:auth_via_tf_facial_recognition/data_access_layer/Service/prediction_service.dart';
import 'package:auth_via_tf_facial_recognition/GUI/profile.dart';
import 'package:auth_via_tf_facial_recognition/GUI/Widget/app_button.dart';
import 'package:flutter/material.dart';



class AuthButton extends StatefulWidget {
  const AuthButton(this._initializeControllerFuture,
      {Key? key, required this.onPressed, required this.isLogin, required this.reload}) : super(key: key);
  final Future _initializeControllerFuture;
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  @override
  _AuthButtonState createState() => _AuthButtonState();
}


class _AuthButtonState extends State<AuthButton> {
  final PredictionService _predictionService = PredictionService();
  final DatabaseService _dataBaseService = DatabaseService();
  final CameraService _cameraService = CameraService();

  final TextEditingController _userTextEditingController = TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController = TextEditingController(text: '');

  User? _predictedUser;


  /// Creates a new user in the DB and reset the face data in prediction service
  Future _signUp(context) async {
    await _dataBaseService.saveData(
        _userTextEditingController.text,
        _passwordTextEditingController.text,
        _predictionService.predictedData
    );

    _predictionService.predictedData({});
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const IntroScreen()));
  }


  /// Checks the password of the detected user
  Future _login(context) async {
    if (_predictedUser!.password == _passwordTextEditingController.text) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Profile(
                    _predictedUser!.user,
                    imagePath: _cameraService.imagePath,
                  )
          )
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('Wrong password!'),
          );
        },
      );
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;

          // onShot event (takes the image and predict output)
          bool faceDetected = await widget.onPressed();

          if (faceDetected) {
            if (widget.isLogin) {
              var userAndPass = _predictionService.predict();
              if (userAndPass != "") {
                _predictedUser = User.fromDB(userAndPass);
              }
            }
            PersistentBottomSheetController bottomSheetController = Scaffold.of(context).showBottomSheet((context) => signSheet(context));
            bottomSheetController.closed.whenComplete(() => widget.reload());
          }
        } catch (e) {
          //print(e);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF0F0BDB),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'CAPTURE',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }


  Widget signSheet(context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && _predictedUser != null
              ? Text(
                'Welcome back, ' + _predictedUser!.user + '.',
                style: const TextStyle(fontSize: 20),
              )
              : widget.isLogin
                  ? const Text(
                    'User not found 😞',
                    style: TextStyle(fontSize: 20),
                  )
                  : Container(),
          Column(
            children: [
              !widget.isLogin
                  ? AppTextField(
                      controller: _userTextEditingController,
                      labelText: "Your Name",
                    )
                  : Container(),
              const SizedBox(height: 10),
              widget.isLogin && _predictedUser == null
                  ? Container()
                  : AppTextField(
                      controller: _passwordTextEditingController,
                      labelText: "Password",
                      isPassword: true,
                    ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              widget.isLogin && _predictedUser != null
                  ? AppButton(
                      text: 'LOGIN',
                      onPressed: () async {
                        _login(context);
                      },
                      icon: const Icon(
                        Icons.login,
                        color: Colors.white,
                      ),
                    )
                  : !widget.isLogin
                      ? AppButton(
                          text: 'SIGN UP',
                          onPressed: () async {
                            await _signUp(context);
                          },
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                        )
                      : Container(),
            ],
          ),
        ],
      ),
    );
  }

  
  @override
  void dispose() {
    super.dispose();
  }
}
