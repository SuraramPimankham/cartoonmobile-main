
import 'package:cartoonmobile/Pages/menuProfile/AddCoinsPage.dart';
import 'package:cartoonmobile/Pages/menuProfile/AddFriendPage.dart';
import 'package:cartoonmobile/Pages/menuProfile/MyCartoonsPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cartoonmobile/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cartoonmobile/screen/home.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cartoonmobile/Pages/homepage.dart';

class MyProfilePage extends StatefulWidget {
  final String? email;

  MyProfilePage({this.email});

  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  void signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // ล้างข้อมูลการลงชื่อเข้าใช้
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('email');

      // เมื่อคลิกที่ไอคอน "ออกจากระบบ" ให้นำทางไปยังหน้า Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } catch (e) {
      print("Error during sign out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // จำนวนแท็บที่คุณต้องการ
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.power_settings_new),
              onPressed: () {
                signOut(context);
              },
            ),
          ],
          flexibleSpace: Container(
            alignment: Alignment.center,
            child: Container(
              width: 60,
              height: 60,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'images/logo1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'เติมเงิน'),
              Tab(text: 'การ์ตูนของฉัน'),
              Tab(text: 'เพื่อน'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AddCoinsPage(email: widget.email ?? ""),
            MyCartoonsPage(),
            AddFriendPage(),
          ],
        ),
      ),
    );
  }
}
