import 'package:cartoonmobile/Pages/episode.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailCartoonpage extends StatefulWidget {
  final Map<String, dynamic> episodeData;

  const DetailCartoonpage({Key? key, required this.episodeData})
      : super(key: key);

  @override
  State<DetailCartoonpage> createState() => _DetailCartoonpageState();
}

class _DetailCartoonpageState extends State<DetailCartoonpage> {
  late Map<String, dynamic>
      _episodeDetails; // เก็บรายละเอียดของตอนการ์ตูนที่จะแสดงบนหน้า
  List<String> showfriend = [];
  List<String> docIds = []; //เก็บ ID ของเอกสารใน Firestore

  User? _user; //เก็บข้อมูลของผู้ใช้ที่ล็อกอิน
  List<Map<String, dynamic>> _purchasedEpisodesData =
      []; //เก็บข้อมูลของตอนที่ผู้ใช้ซื้อจาก Firestore.

  @override
  void initState() {
    super.initState();
    _episodeDetails = {};
    _fetchEpisodeDetails(widget.episodeData['id']); //เพื่อดึงข้อมูลตอนการ์ตูน
    _fetchFriends();
    _purchasedEpisodesData
        .sort((a, b) => int.parse(a['id']).compareTo(int.parse(b['id'])));
  }

  // ดึงข้อมูลเกี่ยวกับตอนที่ซื้อของผู้ใช้จาก Firestore
  void _fetchEpisodeDetails(String episodeId) async {
    try {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> purchasedEpisodes =
              userData['purchasedEpisodes'] ?? {};

          print('ดึงข้อมูลตอนที่ซื้อ: $purchasedEpisodes');

          List<Map<String, dynamic>> episodesData = [];

          if (purchasedEpisodes.containsKey(episodeId)) {
            Map<String, dynamic> seriesData =
                purchasedEpisodes[episodeId] as Map<String, dynamic>;
            Map<String, dynamic> episodes =
                seriesData['episodes'] as Map<String, dynamic>;

            episodes.forEach((key, value) {
              episodesData.add({
                'id': key,
                'title': '$episodeId $key',
              });
            });
          } else {
            print('ผู้ใช้ยังไม่ได้ซื้อตอนที่มี ID: $episodeId');
          }

          setState(() {
            _purchasedEpisodesData = episodesData;
          });
          print('อัพเดตข้อมูลตอนที่ซื้อ: $_purchasedEpisodesData');
        } else {
          print('ไม่พบข้อมูลผู้ใช้.');
        }
      } else {
        print('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ.');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูลตอน: $e');
    }
  }

  // เปลี่ยนหน้าแอปพลิเคชันไปยังหน้า EpisodePage
  void goToEpisodePage(String episodeId) {
    print('User is navigating to EpisodePage for episode: $episodeId');
    // ใช้ Navigator เพื่อทำการนำผู้ใช้ไปยังหน้า EpisodePage
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpisodePage(
          toonId:
              widget.episodeData['id'], // ส่ง ID ของการ์ตูนไปยัง EpisodePage
          episodeId: episodeId, // ส่ง ID ของตอนที่ผู้ใช้เลือกไปยัง EpisodePage
          episodes: _purchasedEpisodesData
              .map((episode) => episode['id']
                  .toString()) // ส่งรายการ ID ของตอนทั้งหมดที่ซื้อไปยัง EpisodePage
              .toList(),
        ),
      ),
    );
  }

  // ฟังก์ชันเพื่อดึงข้อมูลเพื่อน
  void _fetchFriends() async {
    try {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          List<dynamic> friends = userData['friends'] ?? [];

          print('ข้อมูลเพื่อน : $friends');

          setState(() {
            showfriend = friends.cast<String>().toList();
          });
          print('อัพเดดข้อมูลเพื่อน : $showfriend');
        } else {
          print('ไม่พบข้อมูลผู้ใช้.');
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูลเพื่อน: $e');
    }
  }

// เพิ่มข้อมูลเพื่อบันทึกการแชร์ไปยัง Firestore
  void _shareEpisode(String episodeId, String friendName) async {
    try {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        // สร้างข้อมูลที่จะบันทึกลงใน Firestore
        Map<String, dynamic> shareData = {
          'episodeId': episodeId,
          'sharedBy': _user!.uid, // บันทึก UID ของผู้ใช้ที่แชร์
          'sharedTo': friendName, // บันทึกชื่อเพื่อนที่ได้รับการแชร์
          'timestamp': DateTime.now(), // บันทึกเวลาที่แชร์
        };

        // เพิ่มข้อมูลลงในคอลเลกชัน "share" ใน Firestore
        await FirebaseFirestore.instance.collection('share').add(shareData);

        print('แชร์สำเร็จ: $shareData');
      } else {
        print('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ.');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแชร์: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_episodeDetails['title'] ?? 'หน้ารายละเอียด'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'ตอนที่ซื้อ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _purchasedEpisodesData.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      goToEpisodePage(_purchasedEpisodesData[index]['id']);
                    },
                    child: Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey, // สีของไอคอน
                            ),
                            child: Icon(
                              Icons.bookmark,
                              color: Colors.pink, // สีของไอคอน
                              size: 30, // ขนาดของไอคอน
                            ),
                          ),
                          Expanded(
                              child: ListTile(
                            title: Text(
                              ' ${_purchasedEpisodesData[index]['id']}',
                            ),
                          )),
                          IconButton(
                            icon: Icon(Icons.share),
                            onPressed: () {
                              print(
                                  'docid: ${_purchasedEpisodesData[index]['id']}');
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  double screenHeight =
                                      MediaQuery.of(context).size.height;
                                  double screenWidth =
                                      MediaQuery.of(context).size.width;

                                  return AlertDialog(
                                    contentPadding: EdgeInsets.all(16.0),
                                    title: Column(
                                      children: [
                                        Text(
                                          'ต้องการแชร์',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                            ' ${_purchasedEpisodesData[index]['id']}'),
                                        Container(
                                          height: screenHeight *
                                              0.5, // 80% ของความสูงหน้าจอ
                                          width: screenWidth *
                                              0.8, // 80% ของความกว้างหน้าจอ
                                          color: Colors.white,
                                          child: ListView.builder(
                                              itemCount: showfriend.length,
                                              itemBuilder: (context, index) {
                                                return Card(
                                                  child: ListTile(
                                                    leading: Icon(Icons.person),
                                                    title:
                                                        Text(showfriend[index]),
                                                    trailing: IconButton(
                                                      icon: Icon(Icons.send),
                                                      onPressed: () {
                                                        _shareEpisode(
                                                            _purchasedEpisodesData[
                                                                index]['id'],
                                                            showfriend[index]);
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
