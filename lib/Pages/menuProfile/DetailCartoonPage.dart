import 'package:cartoonmobile/Pages/episode.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
    // print('Sharing with friend: $friendEmail');
    try {
      // เรียกใช้งาน firebase
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        // ดึงข้อมูลของผู้ใช้ที่เข้าสู่ระบบ
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        // สอบว่ามีข้อมูลของผู้ใช้ในเอกสารที่ได้รับมาหรือไม่
        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;

          // อ่านข้อมูลการแชร์ของผู้ใช้
          Map<String, dynamic> sharedWith = userData['share'] ?? {};

          // ตรวจสอบว่ามีข้อมูลการแชร์กับเพื่อนคนนี้หรือไม่
          if (sharedWith.containsKey(friendEmail)) {
            // เรียกใช้ฟังก์ชัน _deleteExpiredShare() เพื่อลบข้อมูลที่หมดอายุทุกครั้งที่มีการแชร์ใหม่
            // await _deleteExpiredShare(
            //     friendEmail, widget.episodeData['id'], episodeId);

            Map<String, dynamic> friendShareData = sharedWith[friendEmail];
            if (friendShareData.containsKey(widget.episodeData['id'])) {
              Map<String, dynamic> episodes =
                  Map.from(friendShareData[widget.episodeData['id']]);
              episodes['episode'][episodeId] = {
                episodeId: episodeId,
                'sendTime': Timestamp.now(),
                'expiration':
                    Timestamp.now().toDate().add(Duration(minutes: 1)),
                // 'expiration':
                // Timestamp.now().toDate().add(Duration(days: 3)),
              };
              friendShareData[widget.episodeData['id'].toString()]['episode'] =
                  episodes['episode'];
            } else {
              friendShareData[widget.episodeData['id'].toString()] = {
                'episode': {
                  episodeId: {
                    episodeId: episodeId,
                    'sendTime': Timestamp.now(),
                    'expiration':
                        Timestamp.now().toDate().add(Duration(minutes: 1)),
                    // 'expiration':
                    // Timestamp.now().toDate().add(Duration(days: 3)),
                  }
                },
              };
            }
          } else {
            sharedWith[friendEmail] = {
              widget.episodeData['id'].toString(): {
                'episode': {
                  episodeId: {
                    episodeId: episodeId,
                    'sendTime': Timestamp.now(),
                    'expiration':
                        Timestamp.now().toDate().add(Duration(minutes: 1)),
                    // 'expiration':
                    // Timestamp.now().toDate().add(Duration(days: 3)),
                  }
                },
              }
            };
          }

          // ตั้งเวลาเพื่อลบข้อมูลที่ตั้งไว้เมื่อครบกำหนด
          // Timer(Duration(minutes: 1), () async {
          //   await _deleteExpiredShare(
          //       friendEmail, widget.episodeData['id'], episodeId);
          // });

          // อัปเดตข้อมูลการแชร์ใน Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'share': sharedWith});

          // เรียกใช้งาน _saveSharedEpisode เพื่อบันทึกข้อมูลในฟิลด์ purchasedEpisodes
          _saveSharedEpisode(friendEmail, episodeId, context);
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแชร์: $e');
    }
  }

  Future<void> _deleteExpiredShare(
      String friendName, String episodeDataId, String episodeId) async {
    try {
      // ดึงข้อมูลของผู้ใช้ที่เข้าสู่ระบบ
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      // ตรวจสอบว่ามีข้อมูลของผู้ใช้ในเอกสารที่ได้รับมาหรือไม่
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // อ่านข้อมูลการแชร์ของผู้ใช้
        Map<String, dynamic> sharedWith = userData['share'] ?? {};

        // ตรวจสอบว่ามีข้อมูลการแชร์กับเพื่อนคนนี้หรือไม่
        if (sharedWith.containsKey(friendName)) {
          Map<String, dynamic> friendShareData = sharedWith[friendName];
          if (friendShareData.containsKey(episodeDataId)) {
            Map<String, dynamic> episodeData =
                friendShareData[episodeDataId.toString()];
            if (episodeData['episode'].containsKey(episodeId)) {
              // ลบข้อมูล episodeId ออกจาก map หากครบกำหนดแล้ว
              episodeData['episode'].remove(episodeId);

              // ถ้าไม่มี episode ใน map อื่นๆ ให้ลบ map นั้นออกจากข้อมูลการแชร์
              if (episodeData['episode'].isEmpty) {
                friendShareData.remove(episodeDataId);
              }

              // อัปเดตข้อมูลการแชร์ใน Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .update({'share': sharedWith});

              // บันทึก log เมื่อมีการลบข้อมูล
              print(
                  'Deleted expired share for friend: $friendName - Episode Data ID: $episodeDataId - Episode ID: $episodeId');
            }
          }
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการลบข้อมูลที่หมดอายุ: $e');
    }
  }

  void _saveSharedEpisode(
      String friendEmail, String episodeId, BuildContext context) async {
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
              if (!purchasedEpisodesData
                  .containsKey(widget.episodeData['id'])) {
                Map<String, dynamic> friendPurchasedEpisodes = {
                  episodeId: {
                    episodeId: episodeId,
                    'sendTime': Timestamp.now(),
                    'expiration':
                        Timestamp.now().toDate().add(Duration(minutes: 1)),
                  }
                };

                purchasedEpisodesData[widget.episodeData['id']] = {
                  'episodes': friendPurchasedEpisodes
                };

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .update({'purchasedEpisodes': purchasedEpisodesData});

                Timer(Duration(minutes: 1), () async {
                  await deleteExpiredEpisodes(
                      friendEmail, widget.episodeData['id'], episodeId);
                });
              } else {
                Map<String, dynamic>? friendPurchasedEpisodes =
                    purchasedEpisodesData[widget.episodeData['id']]['episodes']
                        as Map<String, dynamic>?;

                if (friendPurchasedEpisodes != null &&
                    !friendPurchasedEpisodes.containsKey(episodeId)) {
                  // เพิ่มตอนที่ผู้ใช้แชร์ลงในฐานข้อมูลของเพื่อน
                  friendPurchasedEpisodes[episodeId] = {
                    episodeId: episodeId,
                    'sendTime': Timestamp.now(),
                    'expiration':
                        Timestamp.now().toDate().add(Duration(minutes: 1)),
                  };
                  // อัพเดทข้อมูลใน Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendUid)
                      .update({'purchasedEpisodes': purchasedEpisodesData});

                  Timer(Duration(minutes: 1), () async {
                    await deleteExpiredEpisodes(
                        friendEmail, widget.episodeData['id'], episodeId);
                  });
                }
              }
            } else {
              Map<String, dynamic> friendPurchasedEpisodes = {
                episodeId: {
                  episodeId: episodeId,
                  'sendTime': Timestamp.now(),
                  'expiration':
                      Timestamp.now().toDate().add(Duration(minutes: 1)),
                }
              };

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendUid)
                  .update({
                'purchasedEpisodes': {
                  widget.episodeData['id']: {
                    'episodes': friendPurchasedEpisodes
                  }
                }
              });

              Timer(Duration(minutes: 1), () async {
                await deleteExpiredEpisodes(
                    friendEmail, widget.episodeData['id'], episodeId);
              });
            }
          } else {
            Map<String, dynamic> friendPurchasedEpisodes = {
              episodeId: {
                episodeId: episodeId,
                'sendTime': Timestamp.now(),
                'expiration':
                    Timestamp.now().toDate().add(Duration(minutes: 1)),
              }
            };

            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendUid)
                .update({
              'purchasedEpisodes': {
                widget.episodeData['id']: {'episodes': friendPurchasedEpisodes}
              }
            });

            Timer(Duration(minutes: 1), () async {
              await deleteExpiredEpisodes(
                  friendEmail, widget.episodeData['id'], episodeId);
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

  Future<void> deleteExpiredEpisodes(
      String friendEmail, episodeData, String episodeId) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (QueryDocumentSnapshot userSnapshot in querySnapshot.docs) {
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('purchasedEpisodes')) {
          Map<String, dynamic>? purchasedEpisodesData =
              userData['purchasedEpisodes'] as Map<String, dynamic>?;

          if (purchasedEpisodesData != null) {
            for (String cartoonId in purchasedEpisodesData.keys) {
              Map<String, dynamic>? episodesData =
                  purchasedEpisodesData[cartoonId]['episodes']
                      as Map<String, dynamic>?;

              if (episodesData != null) {
                List<String> expiredEpisodes = [];
                for (String episodeId in episodesData.keys) {
                  Map<String, dynamic>? episodeInfo =
                      episodesData[episodeId] as Map<String, dynamic>?;

                  if (episodeInfo != null &&
                      episodeInfo.containsKey('expiration')) {
                    Timestamp expiration =
                        episodeInfo['expiration'] as Timestamp;

                    // Check if current time is after the expiration time
                    if (DateTime.now().isAfter(expiration.toDate())) {
                      // If current time is after expiration time, add episodeId to the list of expired episodes
                      expiredEpisodes.add(episodeId);
                    }
                  }
                }

                // Remove expired episodes from the user's purchased episodes
                for (String episodeId in expiredEpisodes) {
                  episodesData.remove(episodeId);
                }

                // Update user's purchased episodes data
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userSnapshot.id)
                    .update({'purchasedEpisodes': purchasedEpisodesData});

                // Log deleted episodes
                print(
                    'Deleted expired episodes for user ${userSnapshot.id}: $expiredEpisodes');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error deleting expired episodes: $e');
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
                                                        _saveSharedEpisode(
                                                          showfriend[
                                                              friendIndex],
                                                          _purchasedEpisodesData[
                                                              index]['id'],
                                                          context,
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
