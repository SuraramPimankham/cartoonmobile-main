import 'dart:async';
import 'dart:ui';
import 'package:cartoonmobile/screen/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> signUp(String? email, String? password) async {
    try {
      await _auth
          .createUserWithEmailAndPassword(
        email: email ?? '',
        password: password ?? '',
      )
          .then((userCredential) async {
        // บันทึกข้อมูลลง Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'email': email,
          'password': password,
          'coin': 0,
          'username': email,
          'favorite': [],
          'score_action': 0,
          'score_comedy': 0,
          'score_fantasy': 0,
          'score_romance': 0,
          'score_horror': 0,
          // เพิ่มข้อมูลอื่น ๆ ที่คุณต้องการบันทึกลง Firestore
        });

        // สำเร็จ: ไม่มีข้อผิดพลาด
        return null;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      // จัดการข้อผิดพลาดจาก Firebase Authentication ได้ที่นี่
      return errorMessage;
    }
  }

  Future<String?> signIn(String? email, String? password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email ?? '',
        password: password ?? '',
      );
      return null;
    } on FirebaseAuthException catch (e) {
      print('Error: $e');
      return e.message;
    }
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'E-Toon',
      logo: AssetImage('images/logo1.png'),
      onLogin: (data) async {
        return await signIn(data.name, data.password);
      },
      onSignup: (data) async {
        return await signUp(data.name, data.password);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
      },
      onRecoverPassword: (name) async {
        return await _recoverPassword(name);
      },
    );
  }
}
