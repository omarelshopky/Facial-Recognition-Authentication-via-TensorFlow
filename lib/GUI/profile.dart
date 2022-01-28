import 'dart:io';
import 'package:auth_via_tf_facial_recognition/GUI/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:auth_via_tf_facial_recognition/GUI/Widget/app_button.dart';


class Profile extends StatelessWidget {
  const Profile(this.username, {Key? key, required this.imagePath}) : super(key: key);
  final String username;
  final String imagePath;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFC7FFBE),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(imagePath)),
                    ),
                  ),
                  margin: const EdgeInsets.all(20),
                  width: 50,
                  height: 50,
                  // child: Transform(
                  //     alignment: Alignment.center,
                  //     child: FittedBox(
                  //       fit: BoxFit.cover,
                  //       child: Image.file(File(imagePath)),
                  //     ),
                  //     transform: Matrix4.rotationY(mirror)),
                ),
                Text(
                  'Hi ' + username + '!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFFC1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 30,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    '''If you think this project seems interesting and you want to contribute or need some help implementing it, dont hesitate and lets get in touch!''',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                  Divider(
                    height: 30,
                  ),
                ],
              ),
            ),
            const Spacer(),
            AppButton(
              text: "LOG OUT",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IntroScreen()),
                );
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              color: const Color(0xFFFF6161),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
