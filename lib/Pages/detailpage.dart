import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cartoonmobile/Pages/episode.dart';

// import 'package:shared_preferences/shared_preferences.dart';
import 'package:cartoonmobile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailPage extends StatefulWidget {
  final String id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String recommendation;

  DetailPage({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.recommendation,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool isFavorite = false;
  User? _user; // ทำให้ _user เป็น nullable
  late List<String> episodes = [];
  late List<String> episodeIds = [];
  String selectedEpisodeId = '';
  // bool isPressed = false;
  bool isPurchased = false;
  // int count = 0;

  @override
  void initState() {
    super.initState();
    // ตรวจสอบสถานะการล็อกอินของผู้ใช้
    _user = FirebaseAuth.instance.currentUser;
    fetchEpisodes();
  }

  // ตรวจสอบเรื่องราวที่ชื่นชอบ
  Stream<bool> checkFavoriteStory() {
    // สร้างและคืนค่า Stream จาก Firestore ที่ติดตาม user_favorite ของเอกสารนี้
    return FirebaseFirestore.instance
        .collection("storys")
        .doc(widget.id)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final userFavorite = snapshot.data()?['user_favorite'] as List;
        final userUid = FirebaseAuth.instance.currentUser?.uid;
        return userUid != null && userFavorite.contains(userUid);
      }
      return false; // ถ้าไม่มีเอกสารหรือไม่มีฟิล "user_favorite"
    });
  }

  // อัปเดตข้อมูลใน Firestore เมื่อผู้ใช้ทำการเพิ่มหรือลดคะแนน
  Future<void> updateRatingStoryAndUser(bool isFavorite) async {
    try {
      final uid_user = _user?.uid;

      // อ้างอิงไปยังเอกสารใน Firestore
      final storyRef =
          FirebaseFirestore.instance.collection("storys").doc(widget.id);

      final document = await storyRef.get();

      if (document.exists) {
        // ตรวจสอบว่าฟิล "user_favorite" มีอยู่ในเอกสารหรือไม่
        final userFavoriteExists =
            document.data()!.containsKey('user_favorite');

        // ตรวจสอบว่า UID ของผู้ใช้อยู่ในฟิล "user_favorite" หรือไม่
        final userFavorite = userFavoriteExists
            ? (document.data()!['user_favorite'] as List)
            : [];

        if (uid_user != null) {
          if (userFavorite.contains(uid_user)) {
            // UID ของผู้ใช้อยู่ใน "user_favorite", ดังนั้นลดคะแนน (-1) และลบ UID ออกจาก "user_favorite"
            await storyRef.update({
              'rating': FieldValue.increment(-1),
              'user_favorite': FieldValue.arrayRemove([uid_user])
            });

            // Update the user document in the "users" collection
            await FirebaseFirestore.instance
                .collection("users")
                .doc(uid_user)
                .update({
              'favorite': FieldValue.arrayRemove([widget.id])
            });

            // เช็คหมวดหมู่ของเรื่อง
            final categories = document.data()!['categories'];

            if (categories != null) {
              for (final category in categories) {
                final categoryField = 'score_$category';
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid_user)
                    .update({categoryField: FieldValue.increment(-1)});
              }
            }
          } else {
            // UID ของผู้ใช้ไม่อยู่ใน "user_favorite", ดังนั้นเพิ่มคะแนน (+1) และเพิ่ม UID เข้าไปใน "user_favorite"
            await storyRef.update({
              'rating': FieldValue.increment(1),
              'user_favorite': FieldValue.arrayUnion([uid_user])
            });

            // Update the user document in the "users" collection
            await FirebaseFirestore.instance
                .collection("users")
                .doc(uid_user)
                .update({
              'favorite': FieldValue.arrayUnion([widget.id])
            });

            // เช็คหมวดหมู่เรื่อง
            final categories = document.data()!['categories'];

            if (categories != null) {
              for (final category in categories) {
                final categoryField = 'score_$category';
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid_user)
                    .update({categoryField: FieldValue.increment(1)});
              }
            }
          }
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการอัปเดต rating และ favorite ใน Firestore: $e');
    }
  }

  // ติดตามการเปลี่ยนแปลงของคะแนน
  Stream<int> fetchRatingEP(String episodeId) {
    final episodeRef =
        FirebaseFirestore.instance.collection(widget.id).doc(episodeId);

    return episodeRef.snapshots().map((document) {
      if (document.exists) {
        final rating = document.data()?['rating'];
        if (rating != null && rating is int) {
          return rating;
        } else {
          return 0; // กำหนดค่าเริ่มต้นหากคะแนนไม่ใช่ int หรือเป็น null
        }
      } else {
        return 0; // กำหนดค่าเริ่มต้นหากไม่มีเอกสาร
      }
    }).handleError((error) {
      print('ข้อผิดพลาดในการดึงคะแนนจาก Firestore: $error');
      return 0; // กำหนดค่าเริ่มต้นในกรณีของข้อผิดพลาด
    });
  }

// ดึงคะแนน (rating) ของเรื่องราว (story) จาก Firestore
  Future<int> getRatingStory() async {
    try {
      final storyRef =
          FirebaseFirestore.instance.collection("storys").doc(widget.id);

      final document = await storyRef.get();
      if (document.exists) {
        final rating = document.data()?['rating'] as int;
        if (rating != null && rating is int) {
          return rating;
        } else {
          return 0; // ถ้าคะแนนไม่ใช่ int หรือเป็น null
        }
        // return rating ?? 0;
      }
      return 0; // ถ้าไม่มีเอกสารหรือไม่มีฟิล "rating"
    } catch (e) {
      print('Error fetching rating from Firestore: $e');
      return 0; // ในกรณีที่เกิดข้อผิดพลาด
    }
  }

  // ตรวจสอบสถานะการเข้าสู่ระบบของผู้ใช้
  Future<void> checkUserLoginStatus(bool isLocked, String episodeId) async {
    // ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่
    bool isLoggedIn = _user != null;

    if (isLoggedIn) {
      // มีการเข้าสู่ระบบ ให้ไปยังหน้า EpisodePage
      goToEpisodePage(episodeId);
    } else if (!isLoggedIn && !isLocked) {
      goToEpisodePage(episodeId);
    } else {
      // ถ้าตอนนี้มีการล็อค
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MyProfile(),
        ),
      );
    }
  }

  // นำทางไปยังหน้า EpisodePage โดยใช้ episodeId
  void goToEpisodePage(String episodeId) {
    // นำทางไปยังหน้า EpisodePage โดยใช้ episodeId
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpisodePage(
          toonId: widget.id,
          episodeId: episodeId,
          episodes: episodes,
        ),
      ),
    );
  }

  // ดึงข้อมูลของตอน (episodes) จาก Firestore โดยใช้ CollectionReference และ QuerySnapshot
  Future<void> fetchEpisodes() async {
    try {
      CollectionReference episodesCollection =
          FirebaseFirestore.instance.collection(widget.id);

      QuerySnapshot episodesSnapshot = await episodesCollection.get();

      if (episodesSnapshot.docs.isNotEmpty) {
        setState(() {
          episodes.clear();
          episodeIds.clear();
        });

        episodesSnapshot.docs.forEach((doc) {
          String episode_id = doc.id;
          String episode = doc['ep'];
          episodes.add('EP $episode');
          episodeIds.add(episode_id);
        });

        episodes.sort((a, b) {
          int aEpisodeNumber = int.parse(a.split(' ')[1]);
          int bEpisodeNumber = int.parse(b.split(' ')[1]);
          return bEpisodeNumber.compareTo(aEpisodeNumber);
        });
        episodeIds.sort((a, b) {
          int aEpisodeNumber = int.tryParse(a.split('EP ')[1]) ?? 0;
          int bEpisodeNumber = int.tryParse(b.split('EP ')[1]) ?? 0;
          return bEpisodeNumber.compareTo(aEpisodeNumber);
        });
      }
    } catch (e) {
      print('Error fetching episodes: $e');
    }
  }

// Income รายได้ของเแต่ละรื่อง
  Future<void> addIncomeRecord(
      String? userId, String? storyId, String? title, String? episodeId) async {
    try {
      // ตรวจสอบว่าผู้ใช้ล็อกอินหรือไม่
      if (userId != null) {
        // ดึงข้อมูลเกี่ยวกับซื้อตอนล่าสุดจากคอลเล็กชัน "Income"
        QuerySnapshot incomeQuery = await FirebaseFirestore.instance
            .collection('Income')
            .where('storyId', isEqualTo: storyId)
            .limit(1)
            .get();

        // คำนวณรายได้ทั้งหมด (รวมทุกตอน)
        int totalCoins = incomeQuery.docs.isNotEmpty
            ? incomeQuery.docs.first['coin'] + 15
            : 15;
        // รับเวลาปัจจุบัน
        DateTime now = DateTime.now();

        // บันทึกหรืออัปเดตข้อมูลในคอลเล็กชัน "Income"
        if (incomeQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('Income')
              .doc(incomeQuery.docs.first.id)
              .update({'coin': totalCoins});
        } else {
          await FirebaseFirestore.instance.collection('Income').add({
            'storyId': storyId ?? '',
            'title': title ?? '',
            'coin': totalCoins,
            'PurchaseTime': now,
          });
        }

        print('คอลเล็กชัน "Income" ถูกสร้างเรียบร้อยแล้ว');
      } else {
        print('ไม่มีผู้ใช้ล็อกอิน');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการสร้างคอลเล็กชัน "Income": $e');
    }
  }

  // อัปเดตข้อมูลการซื้อของผู้ใช้ใน Firestore เมื่อมีการซื้อตอนใหม่
  Future<void> updatePurchasedEpisodes(String userId, String storyId,
      String storyTitle, String episodeId, DateTime purchaseTime) async {
    try {
      // อ้างอิงไปยังเอกสารผู้ใช้ในคอลเล็กชัน "users"
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // ดึงข้อมูลเอกสารผู้ใช้
      final userDoc = await userRef.get();

      // ตรวจสอบว่ามีเอกสารผู้ใช้หรือไม่
      if (userDoc.exists) {
        // ดึงข้อมูลตอนที่ซื้อมาจากเอกสารผู้ใช้
        final purchasedEpisodes =
            userDoc.data()?['purchasedEpisodes'] ?? <String, dynamic>{};

        // ตรวจสอบว่า storyId มีอยู่ใน purchasedEpisodes หรือไม่
        if (purchasedEpisodes.containsKey(storyId)) {
          // ดึงตอนที่ซื้อมาสำหรับเรื่องที่ระบุ
          final storyPurchases =
              purchasedEpisodes[storyId]['episodes'] ?? <String, dynamic>{};

          // ตรวจสอบว่า episodeId มีอยู่ในเรื่องหรือไม่
          if (storyPurchases.containsKey(episodeId)) {
            // ตอนถูกซื้อแล้ว, ไม่ต้องทำอะไร
          } else {
            // ตอนยังไม่ได้ซื้อ, เพิ่ม episodeId เข้าไปใน storyPurchases
            storyPurchases[episodeId] = {
              'episodeId': episodeId,
              'purchaseTime': purchaseTime,
            };
          }
        } else {
          // เรื่องยังไม่ได้ซื้อ, เพิ่มเรื่องใน purchasedEpisodes
          purchasedEpisodes[storyId] = {
            'episodes': {
              episodeId: {
                'episodeId': episodeId,
                'purchaseTime': purchaseTime,
              },
            },
          };
        }

        // อัปเดตเอกสารผู้ใช้ด้วยข้อมูล purchasedEpisodes ใหม่
        await userRef.update({'purchasedEpisodes': purchasedEpisodes});
      }
    } catch (e) {
      print('Error updating purchased episodes: $e');
    }
  }

  // ตรวจสอบว่าตอนที่ระบุได้ถูกซื้อไปแล้วหรือไม่
  Future<bool> isEpisodePurchased(
      String userId, String storyId, String episodeId) async {
    try {
      // อ้างอิงไปยังเอกสารผู้ใช้ในคอลเล็กชัน "users"
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // ดึงข้อมูลเอกสารผู้ใช้
      final userDoc = await userRef.get();

      // ตรวจสอบว่ามีเอกสารผู้ใช้หรือไม่
      if (userDoc.exists) {
        // ดึงข้อมูลตอนที่ซื้อมาจากเอกสารผู้ใช้
        final purchasedEpisodes =
            userDoc.data()?['purchasedEpisodes'] ?? <String, dynamic>{};

        // ตรวจสอบว่า storyId มีอยู่ใน purchasedEpisodes หรือไม่
        if (purchasedEpisodes.containsKey(storyId)) {
          // ดึงตอนที่ซื้อมาสำหรับเรื่องที่ระบุ
          final storyPurchases =
              purchasedEpisodes[storyId]['episodes'] ?? <String, dynamic>{};

          // ตรวจสอบว่า episodeId มีอยู่ในเรื่องหรือไม่
          if (storyPurchases.containsKey(episodeId)) {
            // ตอนถูกซื้อแล้ว
            return true;
          } else {
            // ตอนยังไม่ได้ซื้อ
            return false;
          }
        }
      }
    } catch (e) {
      print('Error checking purchased episodes: $e');
    }

    // เกิดข้อผิดพลาดหรือไม่มีข้อมูล
    print('Error or no data found');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('รายละเอียดเรื่อง'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(5),
              child: Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                color: Color.fromARGB(255, 235, 177, 196),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // image
                    Padding(
                      padding: EdgeInsets.all(2),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.imageUrl,
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Title: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Author
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Author: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.author,
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Description
                            Text(
                              'Description: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 300,
                              height: 200,
                              // color: Colors.white,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        widget.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                IconButton(
                                  icon: StreamBuilder<bool>(
                                    stream:
                                        checkFavoriteStory(), // สร้างฟังก์ชันนี้เพื่อรับ Stream ในการติดตามการกด Favorite
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Icon(
                                          Icons.favorite_border,
                                          color: Colors.white,
                                          size: 24,
                                        );
                                      } else {
                                        final isUserFavorite =
                                            snapshot.data ?? false;
                                        return Icon(
                                          isUserFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.white,
                                          size: 24,
                                        );
                                      }
                                    },
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isFavorite = !isFavorite;
                                    });

                                    updateRatingStoryAndUser(isFavorite);
                                  },
                                ),
                                FutureBuilder<int>(
                                  future: getRatingStory(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      '${snapshot.data ?? 0}',
                                      style: TextStyle(fontSize: 14),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                color: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: episodes.asMap().entries.map((entry) {
                    int episodeNumber =
                        int.tryParse(episodes[entry.key].split(' ')[1]) ?? 0;
                    // สั่ง lock Ep
                    bool isLocked = episodeNumber >= 2;

                    return Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color.fromARGB(255, 235, 177, 196),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () async {
                          String episode_id = episodeIds[entry.key];
                          // ตรวจสอบว่ามีตอนที่ซื้อแล้วหรือไม่
                          bool isPurchased = await isEpisodePurchased(
                              _user?.uid ?? '', widget.id, episode_id);

                          if (_user == null && !isLocked) {
                            setState(() {
                              selectedEpisodeId = episode_id;
                            });
                            goToEpisodePage(episode_id);
                          } else if (_user == null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MyProfile(),
                              ),
                            );
                          } else {
                            setState(() {
                              selectedEpisodeId = episode_id;
                            });

                            if (!isPurchased) {
                              if (isLocked) {
                                DocumentSnapshot userDoc =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user?.uid)
                                        .get();
                                int coins = userDoc['coin'] ?? 0;

                                if (coins >= 15) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('EP ที่ติด Icon Lock'),
                                        content:
                                            Text("ต้องการซื้อ EP นี้หรือไม่?"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('ยกเลิก'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text('ซื้อ'),
                                            onPressed: () async {
                                              await addIncomeRecord(
                                                  _user?.uid,
                                                  widget.id,
                                                  widget.title,
                                                  episode_id);

                                              await updatePurchasedEpisodes(
                                                _user?.uid ?? '',
                                                widget.id,
                                                widget.title,
                                                episode_id,
                                                DateTime.now(),
                                              );

                                              Navigator.of(context).pop();
                                              goToEpisodePage(episode_id);

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(_user?.uid ?? '')
                                                  .update({
                                                'coin':
                                                    FieldValue.increment(-15),
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('เงินไม่พอ'),
                                        content: Text(
                                            "คุณไม่มีเหรียญเพียงพอที่จะซื้อ EP นี้"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('ตกลง'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } else {
                                goToEpisodePage(episode_id);
                              }
                            } else {
                              goToEpisodePage(episode_id);
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection(widget.id)
                                  .doc(episodeIds[entry.key])
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 8,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    List<dynamic> imagesDynamic =
                                        snapshot.data?['images'] ?? [];
                                    List<String> images = imagesDynamic
                                        .map((e) => e.toString())
                                        .cast<String>()
                                        .toList();
                                    String imageUrl =
                                        images.isNotEmpty ? images[0] : '';

                                    if (imageUrl.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: Container(),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                            Column(
                              children: [
                                Text(
                                  ' ${episodeIds[entry.key]}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 9),
                                Row(
                                  children: [
                                    Icon(Icons.favorite, color: Colors.white),
                                    StreamBuilder<int>(
                                      stream:fetchRatingEP(episodeIds[entry.key]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text('เกิดข้อผิดพลาด: ${snapshot.error}');
                                        } else {
                                          final rating = snapshot.data;
                                          final displayRating = (rating != null) ? rating : 0;
                                          return Text('$displayRating');
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Spacer(),
                            if (isLocked)
                              StreamBuilder<bool>(
                                  stream: Stream.fromFuture(isEpisodePurchased(
                                      _user?.uid ?? '',
                                      widget.id,
                                      episodeIds[entry.key])),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      // สถานะการโหลด
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      // สถานะข้อผิดพลาด
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      // ข้อมูลที่ได้รับ
                                      bool isPurchased = snapshot.data ?? false;
                                      if (!isPurchased) {
                                        // ไม่ได้ซื้อ
                                        return Column(
                                          children: [
                                            Text('15',
                                                style: TextStyle(fontSize: 16)),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child: Icon(
                                                  Icons
                                                      .monetization_on_outlined,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // ซื้อแล้ว
                                        return SizedBox();
                                      }
                                    }
                                  })
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
