import 'dart:async';
import 'dart:math';

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

    // เรียกใช้งานเมธอด _checkAndDeleteExpiredShares ทุกๆ 1 นาที
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndDeleteExpiredShares();
    });
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
                'timestamp': DateTime.now().millisecondsSinceEpoch,
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

  // เพิ่มเมธอด _checkAndDeleteExpiredShares เพื่อตรวจสอบและลบการแชร์ที่หมดอายุ
  void _checkAndDeleteExpiredShares() async {
    try {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('share')
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.forEach((doc) async {
            Map<String, dynamic> shareData = doc.data() as Map<String, dynamic>;
            shareData.forEach((key, value) async {
              Map<String, dynamic> episodesData = value['episodes'];
              episodesData.forEach((episodeId, timestamp) async {
                int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
                int shareTimestamp = timestamp;

                // ตรวจสอบว่าหมดอายุหรือไม่ (ให้กำหนดเวลาหมดอายุตามที่ต้องการ)
                if ((currentTimestamp - shareTimestamp) > 24 * 60 * 60 * 1000) {
                  // 24 * 60 * 60 * 1000 หมายถึง 1 วัน
                  // ลบตอนที่มีการแชร์ที่หมดอายุ
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('share')
                      .doc(doc.id)
                      .update({
                    key: FieldValue.delete(),
                  });
                  print('ลบการแชร์ที่หมดอายุ: Episode ID: $episodeId');
                }
              });
            });
          });
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการตรวจสอบและลบการแชร์ที่หมดอายุ: $e');
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

  void _shareWithFriend(
      String friendEmail, String episodeId, DateTime sendTime) async {
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

          Map<String, dynamic> sharedWith = userData['share'] ?? {};

          if (sharedWith.containsKey(friendEmail)) {
            Map<String, dynamic> friendShareData = sharedWith[friendEmail];
            if (!friendShareData.containsKey(widget.episodeData['id'])) {
              friendShareData[widget.episodeData['id'].toString()] = {
                'episodes': {
                  episodeId: {
                    'sendTime': sendTime, // เพิ่มเวลาในข้อมูลของ Episode
                  },
                },
              };
            } else {
              if (!friendShareData[widget.episodeData['id']]['episodes']
                  .containsKey(episodeId)) {
                friendShareData[widget.episodeData['id']]['episodes']
                    [episodeId] = {
                  'sendTime': sendTime, // เพิ่มเวลาในข้อมูลของ Episode
                };
              } else {
                print('Episodes $episodeId already shared with friend.');
              }
            }
          } else {
            sharedWith[friendEmail] = {
              widget.episodeData['id'].toString(): {
                'episodes': {
                  episodeId: {
                    'sendTime': sendTime, // เพิ่มเวลาในข้อมูลของ Episode
                  },
                },
              },
            };
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'share': sharedWith});

          // เรียกใช้งาน _saveSharedEpisode เพื่อบันทึกข้อมูลในฟิลด์ purchasedEpisodes
          _saveSharedEpisode(friendEmail, episodeId, sendTime);
        }
      }
    } catch (e) {
      print('Error sharing with friend: $e');
    }
  }

  void _saveSharedEpisode(
      String friendEmail, String episodeId, DateTime sendTime) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String friendUid = querySnapshot.docs.first.id;

        DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        if (friendSnapshot.exists) {
          Map<String, dynamic>? friendData =
              friendSnapshot.data() as Map<String, dynamic>?;

          if (friendData != null &&
              friendData.containsKey('purchasedEpisodes')) {
            Map<String, dynamic>? purchasedEpisodesData =
                friendData['purchasedEpisodes'] as Map<String, dynamic>?;

            if (purchasedEpisodesData != null) {
              // บันทึก ID และตอนที่ซื้อไปยังฟิลด์ purchasedEpisodes ของเพื่อน
              if (purchasedEpisodesData.containsKey(widget.episodeData['id'])) {
                // ตรวจสอบว่ามีข้อมูลการซื้อของการ์ตูนนี้อยู่แล้วหรือไม่
                Map<String, dynamic> friendPurchasedEpisodes =
                    purchasedEpisodesData[widget.episodeData['id']]
                        as Map<String, dynamic>;

                // ตรวจสอบว่ามี ID และตอนที่ซื้ออยู่แล้วหรือไม่
                if (!friendPurchasedEpisodes.containsKey(episodeId)) {
                  // ถ้าไม่มีให้เพิ่ม ID และตอนที่ซื้อลงในฟิลด์ purchasedEpisodes ของเพื่อน
                  friendPurchasedEpisodes['episodes'][episodeId] = {
                    'episode': episodeId,
                    'sendTime': sendTime,
                  };
                  // อัพเดทตอนที่ซื้อของเพื่อนในฐานข้อมูล
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendUid)
                      .update({'purchasedEpisodes': purchasedEpisodesData});
                } else {
                  // ถ้ามีอยู่แล้วให้ไม่ต้องทำอะไร
                  print('Friend already has purchased episode: $episodeId');
                }
              } else {
                // ถ้ายังไม่มีข้อมูลการซื้อของการ์ตูนนี้ ให้สร้างฟิลด์ purchasedEpisodes ใหม่
                Map<String, dynamic> friendPurchasedEpisodes = {
                  episodeId: {
                    'episode': episodeId,
                    'sendTime': sendTime,
                  }
                };

                purchasedEpisodesData[widget.episodeData['id']] = {
                  'episodes': friendPurchasedEpisodes
                };

                // อัพเดทตอนที่ซื้อของเพื่อนในฐานข้อมูล
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .update({'purchasedEpisodes': purchasedEpisodesData});
              }
            } else {
              // ถ้ายังไม่มีฟิลด์ purchasedEpisodes ในข้อมูลของเพื่อน ให้สร้างใหม่
              Map<String, dynamic> friendPurchasedEpisodes = {
                episodeId: {
                  'episode': episodeId,
                  'sendTime': sendTime,
                },
              };
              // อัพเดทตอนที่ซื้อของเพื่อนในฐานข้อมูล
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendUid)
                  .update({
                'purchasedEpisodes': {
                  widget.episodeData['id']: {
                    'episodes': {
                      episodeId: friendPurchasedEpisodes,
                    }
                  }
                }
              });
            }
          } else {
            // ถ้ายังไม่มีข้อมูลการซื้อของเพื่อนเลย ให้สร้างฟิลด์ purchasedEpisodes ใหม่
            Map<String, dynamic> friendPurchasedEpisodes = {
              episodeId: {
                'episode': episodeId,
                'sendTime': sendTime,
              },
            };
            // อัพเดทตอนที่ซื้อของเพื่อนในฐานข้อมูล
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendUid)
                .update({
              'purchasedEpisodes': {
                widget.episodeData['id']: {'episodes': friendPurchasedEpisodes}
              }
            });
          }
        } else {
          print('User with UID $friendUid not found.');
        }
      } else {
        print('User with email $friendEmail not found.');
      }
    } catch (e) {
      print('Error saving shared episode: $e');
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
                            ),
                          ),
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
                                                          DateTime.now(),
                                                        );
                                                        _saveSharedEpisode(
                                                          showfriend[
                                                              friendIndex],
                                                          _purchasedEpisodesData[
                                                              index]['id'],
                                                          DateTime.now(),
                                                        );

                                                        // หลังจากเรียกใช้งานฟังก์ชันเสร็จสิ้น คุณสามารถปิดกล่องโต้ตอบได้
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
