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

          setState(() {
            showfriend = friends.cast<String>().toList();
          });
        } else {
          print('ไม่พบข้อมูลผู้ใช้.');
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูลเพื่อน: $e');
    }
  }

  void _shareWithFriend(String friendEmail, String episodeId) async {
    print('Sharing with friend: $friendEmail');
    try {
      // เรียกใช้งาน firebase
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // ดึงข้อมูลของผู้ใช้ที่เข้าสู่ระบบ
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // ตรวจสอบว่ามีข้อมูลของผู้ใช้ในเอกสารที่ได้รับมาหรือไม่
        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;

          // อ่านข้อมูลการแชร์ของผู้ใช้
          Map<String, dynamic> sharedWith = userData['share'] ?? {};

          // ค้นหาเพื่อนที่ต้องการแชร์ด้วยอีเมล
          QuerySnapshot friendSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: friendEmail)
              .get();

          if (friendSnapshot.docs.isNotEmpty) {
            String friendUid = friendSnapshot.docs.first.id;
            print('Friend Email: $friendEmail, Friend UID: $friendUid');

            // ตรวจสอบว่ามีข้อมูลการแชร์กับเพื่อนคนนี้หรือไม่
            if (sharedWith.containsKey(friendEmail)) {
              // ตรวจสอบว่ามีข้อมูล episode ของเพื่อนหรือยัง
              Map<String, dynamic> friendShareData = sharedWith[friendEmail];
              if (!friendShareData.containsKey(widget.episodeData['id'])) {
                // ถ้าไม่มีข้อมูล episode ของเพื่อน ให้เพิ่มข้อมูลใหม่ลงไป
                friendShareData[widget.episodeData['id'].toString()] = {
                  'episodes': {
                    episodeId: episodeId,
                  },
                };
              } else {
                // ถ้ามีข้อมูล episode ของเพื่อนคนนี้อยู่แล้ว ให้เพิ่ม episodeId เข้าไปใน map ที่มีอยู่แล้ว
                Map<String, dynamic> episodes =
                    Map.from(friendShareData[widget.episodeData['id']]);
                episodes['episodes'][episodeId] = episodeId;
                friendShareData[widget.episodeData['id'].toString()]
                    ['episodes'] = episodes['episodes'];
              }
            } else {
              // ถ้ายังไม่มีการแชร์ เริ่มต้นการแชร์โดยเพิ่มข้อมูลใหม่
              sharedWith[friendEmail] = {
                widget.episodeData['id'].toString(): {
                  'episodes': {
                    episodeId: episodeId,
                  },
                }
              };
            }

            // อัปเดตข้อมูลการแชร์ใน Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'share': sharedWith});
          } else {
            print('ไม่พบเพื่อนที่มีอีเมล: $friendEmail');
          }
        }
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
                                              itemBuilder:
                                                  (context, friendIndex) {
                                                return Card(
                                                  child: ListTile(
                                                    leading: Icon(Icons.person),
                                                    title: Text(showfriend[
                                                        friendIndex]),
                                                    trailing: IconButton(
                                                      icon: Icon(Icons.send),
                                                      onPressed: () {
                                                        // เรียกใช้งานฟังก์ชัน _shareWithFriend
                                                        _shareWithFriend(
                                                          showfriend[
                                                              friendIndex], // ส่งชื่อเพื่อนที่ถูกเลือกไปยังฟังก์ชัน
                                                          _purchasedEpisodesData[
                                                                  index][
                                                              'id'], // ส่ง StoryId ที่เกี่ยวข้องกับตอนที่ซื้อ
                                                        );

                                                        // หลังจากเรียกใช้งานฟังก์ชันเสร็จสิ้น คุณอาจต้องทำอย่างอื่นต่อไป เช่น ปิดกล่องโต้ตอบ (AlertDialog)
                                                        Navigator.of(context)
                                                            .pop();
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
