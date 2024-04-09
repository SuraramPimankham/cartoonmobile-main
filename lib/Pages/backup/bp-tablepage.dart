import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cartoonmobile/Pages/detailpage.dart';

class MyTablePage extends StatefulWidget {
  const MyTablePage();

  @override
  _MyTablePageState createState() => _MyTablePageState();
}

class _MyTablePageState extends State<MyTablePage> {
  String activeButton = 'จ'; // กำหนดค่าเริ่มต้นให้ activeButton เป็น 'จ'
  Map<String, String> dayMap = {
    'จ': 'monday',
    'อ': 'tuesday',
    'พ': 'wednesday',
    'พฤ': 'thursday',
    'ศ': 'friday',
    'ส': 'saturday',
    'อา': 'sunday',
  };

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Firestore instance
  List<Map<String, dynamic>> storyData = [];

  @override
  void initState() {
    super.initState();
    fetchStoryData('จ'); // เรียกใช้งาน fetchStoryData เมื่อเริ่มต้น
  }

  Future<void> fetchStoryData(String day) async {
    try {
      final QuerySnapshot querySnapshot = await firestore
          .collection('storys')
          .where('day', isEqualTo: dayMap[day])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          storyData.clear(); // ล้างข้อมูล storyData ที่มีอยู่
        });

        querySnapshot.docs.forEach((doc) {
          storyData.add({
            'id': doc['id'],
            'author': doc['author'],
            'title': doc['title'],
            'imageUrl': doc['imageUrl'],
            'description': doc['description'],
          });
        });
      } else {
        setState(() {
          storyData.clear(); // ล้างข้อมูล storyData ในกรณีที่ไม่มีข้อมูล
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('กำหนดการการ์ตูน'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: [
              // ส่วนของปุ่มวัน
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('จ', activeButton == 'จ'),
                    _buildButton('อ', activeButton == 'อ'),
                    _buildButton('พ', activeButton == 'พ'),
                    _buildButton('พฤ', activeButton == 'พฤ'),
                    _buildButton('ศ', activeButton == 'ศ'),
                    _buildButton('ส', activeButton == 'ส'),
                    _buildButton('อา', activeButton == 'อา'),
                  ],
                ),
              ),
              // ส่วนแสดงรายการเรื่อง
              Container(
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.all(5),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      constraints: BoxConstraints(minHeight: 600),
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: storyData.map((data) {
                          return GestureDetector(
                            onTap: () {
                              print('ID: ${data['id']}');
                              print('Author: ${data['author']}');
                              print('Title: ${data['title']}');
                              print('ImageUrl: ${data['imageUrl']}');
                              print('Description: ${data['description']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPage(
                                    id: data['id'],
                                    author: data['author'],
                                    title: data['title'],
                                    imageUrl: data['imageUrl'],
                                    description: data['description'],
                                    recommendation: '',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 40) / 3,
                              height: 200,
                              child: Align(
                                alignment: Alignment.center,
                                child: Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            data['imageUrl'],
                                            fit: BoxFit.cover,
                                            height: 140,
                                            width: 100,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            data['title'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activeButton = text;
          fetchStoryData(text); // เรียกใช้งาน fetchStoryData เมื่อกดปุ่มวัน
        });
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color:
              isActive ? Colors.pink : const Color.fromARGB(255, 237, 123, 161),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
