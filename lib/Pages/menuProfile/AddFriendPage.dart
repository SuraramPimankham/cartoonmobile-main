import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ตัวแปร
  List<String> searchResults = [];
  List<String> showList = [];
  List<String> deFriend = [];

  @override
  void initState() {
    super.initState();
    displayFriendsList();
  }

  // ค้นหาผู้ใช้ตามชื่อผู้ใช้ที่ระบุใน searchText
  void searchFriend(String searchText) async {
    try {
      if (searchText.isNotEmpty) {
        _firestore
            .collection('users')
            .where('username', isEqualTo: searchText)
            .snapshots()
            .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          setState(() {
            searchResults =
                snapshot.docs.map((doc) => doc['username'] as String).toList();
          });
          // อัปเดตข้อมูลเพื่อนที่แสดงทันที
          displayFriendsList();
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      print('Error searching for friend: $e');
    }
  }

  // ฟังก์ชันเพิ่มเพื่อน
  void addFriend(String friendUsername) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String currentUserId = currentUser.uid;

        // ตรวจสอบว่ากำลังเพิ่มเพื่อนที่ไม่ใช่ตัวเอง
        if (friendUsername != currentUserId) {
          DocumentReference<Map<String, dynamic>> currentUserRef =
              _firestore.collection('users').doc(currentUserId);

          DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
              await currentUserRef.get();

          if (currentUserDoc.exists) {
            List<String> currentFriends =
                currentUserDoc.data()?['friends']?.cast<String>() ?? [];

            // ตรวจสอบว่า friendUsername ไม่ใช่ตัวเอง
            if (friendUsername != currentUserDoc.data()?['username']) {
              if (!currentFriends.contains(friendUsername)) {
                // หากทั้งสองเงื่อนไขนี้เป็นจริง
                currentFriends.add(friendUsername);
                // คำสั่งจะทำการเพิ่มเพื่อนลงในรายชื่อเพื่อนของผู้ใช้ปัจจุบัน
                await currentUserRef.update({'friends': currentFriends});

                print('Friend added successfully: $friendUsername');
                // แสดงว่าเพื่อนถูกเพิ่ม
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เพื่อน $friendUsername ถูกเพิ่มแล้ว'),
                  ),
                );
                // อัปเดตข้อมูลเพื่อนที่แสดงทันที
                displayFriendsList();
              } else {
                print('User $friendUsername is already a friend.');
                // จะแสดง SnackBar ว่าผู้ใช้เป็นเพื่อนอยู่แล้ว
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ผู้ใช้ $friendUsername เป็นเพื่อนอยู่แล้ว'),
                  ),
                );
              }
            } else {
              // แจ้งเตือนว่าไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('คุณไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้'),
                ),
              );
            }
          }
          // หาก friendUsername เป็นตัวเอง
        } else {
          // จะแสดง SnackBar ว่าไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('คุณไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding friend: $e');
    }
  }
  // แสดงรายการเพื่อน
  Future<void> displayFriendsList() async {
    try {
      // ดึงผู้ใช้ปัจจุบันด้วย FirebaseAuth
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // ดึง UID ของผู้ใช้ปัจจุบัน
        String currentUserId = currentUser.uid;
        // อ้างอิงไปยังเอกสารผู้ใช้ปัจจุบันในคอลเลกชัน 'users' ใน Firestore
        DocumentReference<Map<String, dynamic>> currentUserRef =
            _firestore.collection('users').doc(currentUserId);
        // ดึงสแนปช็อตของเอกสารผู้ใช้ปัจจุบัน
        DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
            await currentUserRef.get();
        // ตรวจสอบว่าเอกสารมีหรือไม่
        if (currentUserDoc.exists) {
          // ดึงรายการเพื่อนจากข้อมูลเอกสารผู้ใช้ปัจจุบัน
          List<String> currentFriends =
              currentUserDoc.data()?['friends']?.cast<String>() ?? [];

          // print('Current User ID: $currentUserId');
          // print('Current User Document Data: ${currentUserDoc.data()}');
          print('Current Friends: $currentFriends');

          // อัปเดต UI เพื่อแสดงรายการเพื่อน
          setState(() {
            showList = currentFriends;
          });
        }
      }
    } catch (e) {
      print('Error displaying friends list: $e');
    }
  }

// ฟังก์ชันลบเพื่อน
  Future<void> deleteFriend(String friendUsername) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String currentUserId = currentUser.uid;

        DocumentReference<Map<String, dynamic>> currentUserRef =
            _firestore.collection('users').doc(currentUserId);

        DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
            await currentUserRef.get();

        if (currentUserDoc.exists) {
          List<String> currentFriends =
              currentUserDoc.data()?['friends']?.cast<String>() ?? [];

          if (currentFriends.contains(friendUsername)) {
            currentFriends.remove(friendUsername);

            await currentUserRef.update({'friends': currentFriends});

            print('Friend deleted successfully: $friendUsername');

            // อัปเดต UI เพื่อแสดงรายการเพื่อนทันที
            setState(() {
              showList = currentFriends;
            });
          }
        }
      }
    } catch (e) {
      print('Error deleting friend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ป้อนชื่อเพื่อน',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        searchFriend(_searchController.text);
                      },
                      icon: Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: Container(
                height: 70,
                color: Colors.white,
                child: _searchController.text.isEmpty
                    ? Center(
                        child: Text(
                          '',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'ไม่พบข้อมูลผู้ใช้ที่ค้นหา',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  leading: Icon(Icons.person),
                                  // ผลลัพธ์
                                  title: Text(searchResults[index]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.person_add),
                                        onPressed: () {
                                          print(
                                              'Adding friend: ${searchResults[index]}');
                                          addFriend(searchResults[index]);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            searchResults = [];
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: showList.isEmpty
                    ? Center(
                        child: Text(
                          'ไม่พบเพื่อน',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: showList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.person),
                              title: Text(showList[index]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                 
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      print(
                                          'Deleting friend: ${showList[index]}');
                                      setState(() {
                                        deleteFriend(showList[index]);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
