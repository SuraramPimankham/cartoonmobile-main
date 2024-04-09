import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cartoonmobile/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cartoonmobile/screen/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCoinsPage extends StatefulWidget {
  final String? email;

  AddCoinsPage({this.email});

  @override
  _AddCoinsPageState createState() => _AddCoinsPageState();
}

class _AddCoinsPageState extends State<AddCoinsPage> {
  String? email;
  String? username;
  int user_coins = 0;

  @override
  void initState() {
    super.initState();
    email = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data found for this email'));
          } else {
            final userData =
                snapshot.data!.docs[0].data() as Map<String, dynamic>;
            username = userData['username'];
            user_coins = userData['coin'];
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 100.0,
                    color: Colors.black,
                    child: Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color.fromARGB(255, 241, 129, 166),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('User: $username',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              Text(' : $user_coins coin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Color.fromARGB(255, 241, 129, 166),
                      child: GridView(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        scrollDirection: Axis.vertical,
                        children: [
                          //25 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 25 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 25;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('25 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 50 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 50 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 50;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('50 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 75 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 75 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 75;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('75 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 100 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 100 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 100;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('100 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 125 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 125 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 125;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('125 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 150 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 150 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 150;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('150 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 175 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 175 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 175;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('175 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 200 coins
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 5, 0, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        Text(
                                          ' : 200 coins',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int coinsToAdd = 200;
                                      // ค้นหาเอกสารที่มีฟิลด์ 'email' เท่ากับ 'email' ที่ส่งมา
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get()
                                          .then((QuerySnapshot? querySnapshot) {
                                        // ใส่ ? เพื่อระบุว่า querySnapshot อาจเป็น null
                                        querySnapshot?.docs.forEach(
                                            (QueryDocumentSnapshot? document) {
                                          // ใส่ ? เพื่อระบุว่า document อาจเป็น null
                                          if (document != null) {
                                            int currentCoins = document[
                                                'coin']; // ใส่ ! เพื่อระบุว่า document ไม่เป็น null
                                            int newCoins =
                                                currentCoins + coinsToAdd;

                                            // อัปเดตค่าเหรียญใน Firebase Firestore
                                            String documentId = document.id;
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(documentId)
                                                .update({
                                              'coin': newCoins
                                            }).then((_) {
                                              print('Coins added successfully');
                                            }).catchError((error) {
                                              print(
                                                  'Error adding coins: $error');
                                            });
                                          }
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.pink,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('200 บาท',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          }
        },
      ),
    );
  }

  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
}
