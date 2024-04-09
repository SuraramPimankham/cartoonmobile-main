
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
// import 'package:cartoon/profile.dart';
import 'package:cartoonmobile/profile.dart';

class EpisodePage extends StatefulWidget {
  final String toonId;
  final String episodeId;
  final List<String> episodes;

  EpisodePage({
    required this.toonId,
    required this.episodeId,
    required this.episodes,
  });

  @override
  _EpisodePageState createState() => _EpisodePageState();
}

void main() {
  runApp(MaterialApp(
    home: EpisodePage(
      toonId: "",
      episodeId: 'yourEpisodeId',
      episodes: [],
    ),
  ));
}

class Comment {
  final String username;
  final String text;

  Comment({required this.username, required this.text});

  Map<String, dynamic> toMap() {
    return {'username': username, 'text': text};
  }
}

class _EpisodePageState extends State<EpisodePage> {
  List<Comment> comments = [];
  TextEditingController commentController = TextEditingController();
  int commentIndex = 1;
  bool isFavorite = false; //เก็บสถานะว่าผู้ใช้ได้กดปุ่ม "Favorite" หรือไม่
  int count = 0; //เก็บจำนวนครั้งที่ผู้ใช้กดปุ่ม "Favorite" โดยค่าเริ่มต้นคือ 0
  final GlobalKey commentKey = GlobalKey();
  User? _user;

  late List<String> images = [];
  double? _ratingBarValue;
  final scrollController = AutoScrollController();
  bool _isBarsVisible = true;
  bool sliverAppBarPinned = true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _user = FirebaseAuth.instance.currentUser;
    fetchImages();
    fetchComments();
  }

  Future<int> getRatingFromFirestore(String toonId, String episodeId) async {
    try {
      final episodeRef =
          FirebaseFirestore.instance.collection(toonId).doc(episodeId);

      final document = await episodeRef.get();
      if (document.exists) {
        final rating = document.data()?['rating'] as int;
        return rating ?? 0;
      }
      return 0; // ถ้าไม่มีเอกสารหรือไม่มีฟิล "rating"
    } catch (e) {
      print('Error fetching rating from Firestore: $e');
      return 0; // ในกรณีที่เกิดข้อผิดพลาด
    }
  }

  // storyrating
  Stream<bool> checkIfUserIsFavoriteStream(String toonId, String episodeId) {
    // สร้างและคืนค่า Stream จาก Firestore ที่ติดตาม user_favorite ของเอกสารนี้
    return FirebaseFirestore.instance
        .collection(toonId)
        .doc(episodeId)
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

  Future<void> fetchComments() async {
    try {
      final episodeRef = FirebaseFirestore.instance
          .collection(widget.toonId)
          .doc(widget.episodeId);

      final document = await episodeRef.get();
      if (document.exists) {
        final commentsData = document.data()?['list_comments'] as List?;
        if (commentsData != null) {
          setState(() {
            comments = commentsData
                .map((comment) => Comment(
                      username: comment['uid'] ?? 'ไม่ระบุ',
                      text: comment['comment'] ?? '',
                    ))
                .toList();
          });
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงความคิดเห็นจาก Firestore: $e');
    }
  }

  // update RatingInfirebsto
  Future<void> updateRatingInFirestore(
      String toonId, String episodeId, bool isFavorite) async {
    try {
      final uid_user = _user?.uid;

      // อ้างอิงไปยังเอกสารใน Firestore
      final episodeRef =
          FirebaseFirestore.instance.collection(toonId).doc(episodeId);

      final document = await episodeRef.get();

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
            await episodeRef.update({
              'rating': FieldValue.increment(-1),
              'user_favorite': FieldValue.arrayRemove([uid_user])
            });
          } else {
            // UID ของผู้ใช้ไม่อยู่ใน "user_favorite", ดังนั้นเพิ่มคะแนน (+1) และเพิ่ม UID เข้าไปใน "user_favorite"
            await episodeRef.update({
              'rating': FieldValue.increment(1),
              'user_favorite': FieldValue.arrayUnion([uid_user])
            });
          }
        }
      }
    } catch (e) {
      print(
          'เกิดข้อผิดพลาดในการอัปเดต rating และ user_favorite ใน Firestore: $e');
    }
  }

  // comment
  Future<void> updateRatingAndCommentInFirestore(
      String toonId, String episodeId, bool isFavorite, String comment) async {
    try {
      final uidUser = _user?.uid;

      // อ้างอิงไปยังเอกสารใน Firestore
      final episodeRef =
          FirebaseFirestore.instance.collection(toonId).doc(episodeId);

      final document = await episodeRef.get();

      if (document.exists) {
        // ตรวจสอบว่าฟิล "user_favorite" มีอยู่ในเอกสารหรือไม่
        final userFavoriteExists =
            document.data()!.containsKey('user_favorite');

        // ตรวจสอบว่า UID ของผู้ใช้อยู่ในฟิล "user_favorite" หรือไม่
        final userFavorite = userFavoriteExists
            ? (document.data()!['user_favorite'] as List)
            : [];

        if (uidUser != null) {
          if (userFavorite.contains(uidUser)) {
            // UID ของผู้ใช้อยู่ใน "user_favorite", ดังนั้นลดคะแนน (-1) และลบ UID ออกจาก "user_favorite"
            await episodeRef.update({
              'rating': FieldValue.increment(-1),
              'user_favorite': FieldValue.arrayRemove([uidUser]),
            });
          } else {
            // UID ของผู้ใช้ไม่อยู่ใน "user_favorite", ดังนั้นเพิ่มคะแนน (+1) และเพิ่ม UID เข้าไปใน "user_favorite"
            await episodeRef.update({
              'rating': FieldValue.increment(1),
              'user_favorite': FieldValue.arrayUnion([uidUser]),
            });
          }

          // เพิ่ม comment และ uid ของผู้ใช้ลงใน field 'list_comments'
          await episodeRef.update({
            'list_comments': FieldValue.arrayUnion([
              {
                'uid': _user?.email,
                'comment': comment,
              },
            ]),
          });
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการอัปเดต rating และ comment ใน Firestore: $e');
    }
  }

  // epsisode
  Future<void> epsisodeID_FilterNext() async {
    String episodeIdString = widget.episodeId.split(RegExp(r'[0-9]'))[0];
    int episodeIdNumber =
        int.parse(widget.episodeId.replaceAll(RegExp(r'[^0-9]'), ''));
    int nextEpisodeIdNumber = episodeIdNumber + 1;
    String nextEpisodeId = '$episodeIdString$nextEpisodeIdNumber';

    widget.episodes.sort((a, b) {
      int aEpisodeNumber = int.parse(a.split(' ')[1]);
      int bEpisodeNumber = int.parse(b.split(' ')[1]);
      return aEpisodeNumber
          .compareTo(bEpisodeNumber); // Sort in ascending order
    });

    int currentIndex = widget.episodes.indexWhere((episode) {
      int episodeNumber = int.parse(episode.split(' ')[1]);
      return episodeNumber == episodeIdNumber;
    });
    if (_user == null &&
        episodeIdNumber > 0 &&
        episodeIdNumber <= 2 &&
        currentIndex < widget.episodes.length - 1) {
      print('1');
      // Navigate to the next episode
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EpisodePage(
            toonId: widget.toonId,
            episodeId: nextEpisodeId,
            episodes: widget.episodes,
          ),
        ),
      );
    } else if (_user == null &&
        episodeIdNumber > 0 &&
        episodeIdNumber > 2 &&
        currentIndex < widget.episodes.length - 1) {
      print('2');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MyProfile(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EpisodePage(
            toonId: widget.toonId,
            episodeId: nextEpisodeId,
            episodes: widget.episodes,
          ),
        ),
      );
    }
  }

  Future<void> epsisodeID_FilterBack() async {
    String episodeIdString = widget.episodeId.split(RegExp(r'[0-9]'))[0];
    int episodeIdNumber =
        int.parse(widget.episodeId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (episodeIdNumber > 1) {
      int nextEpisodeIdNumber = episodeIdNumber - 1;
      String nextEpisodeId = '$episodeIdString$nextEpisodeIdNumber';
      // Navigate to the next episode
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EpisodePage(
            toonId: widget.toonId,
            episodeId: nextEpisodeId,
            episodes: widget.episodes,
          ),
        ),
      );
    } else {}
  }

  Future<void> fetchImages() async {
    try {
      DocumentSnapshot episodeSnapshot = await FirebaseFirestore.instance
          .collection(widget.toonId)
          .doc(widget.episodeId)
          .get();

      if (episodeSnapshot.exists) {
        setState(() {
          images = List.from(episodeSnapshot['images']);
        });
      }
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  void _onScroll() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        _isBarsVisible = false;
        sliverAppBarPinned = false;
      });
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        _isBarsVisible = true;
        sliverAppBarPinned = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isBarsVisible = !_isBarsVisible;
            sliverAppBarPinned = _isBarsVisible;
          });
        },
        child: CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            // appbar บน
            SliverAppBar(
              floating: false,
              pinned: sliverAppBarPinned,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.episodeId}',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                background: Container(
                  color: const Color.fromARGB(255, 222, 150, 174),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.all(0),
                    child: AutoScrollTag(
                      key: ValueKey(index),
                      controller: scrollController,
                      index: index,
                      child: Image.network(images[index]),
                    ),
                  );
                },
                childCount: images.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  AutoScrollTag(
                    key: ValueKey('top'),
                    controller: scrollController,
                    index: 0,
                    child: GestureDetector(
                      onTap: () {
                        scrollController.scrollToIndex(
                          0,
                          preferPosition: AutoScrollPosition.begin,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            'ไปที่ด้านบนสุด',
                            style: TextStyle(
                              fontFamily: 'Readex Pro',
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Column(
                  //   mainAxisSize: MainAxisSize.max,
                  //   children: [
                  //     Padding(
                  //       padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.max,
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Text(
                  //             'Score',
                  //             style: TextStyle(
                  //               fontFamily: 'Readex Pro',
                  //               color: Colors.white,
                  //               fontSize: 20,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                      // Row(
                      //   mainAxisSize: MainAxisSize.max,
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     RatingBar.builder(
                      //       onRatingUpdate: (newValue) =>
                      //           setState(() => _ratingBarValue = newValue),
                      //       itemBuilder: (context, index) => Icon(
                      //         Icons.star_rounded,
                      //         color: Color.fromARGB(255, 224, 231, 125),
                      //       ),
                      //       direction: Axis.horizontal,
                      //       initialRating: _ratingBarValue ?? 2,
                      //       unratedColor: Color(0x4D151313),
                      //       itemCount: 5,
                      //       itemSize: 40,
                      //       glowColor: Colors.white,
                      //     ),
                      //   ],
                      // ),
                  //   ],
                  // ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              key: commentKey,
              child: Container(
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Comment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(comments[index].username),
                          subtitle: Text(comments[index].text),
                        );
                      },
                    ),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ความคิดเห็นของคุณ...',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          Comment newComment = Comment(
                            username: 'ผู้ใช้ ${comments.length + 1}',
                            text: commentController.text,
                          );
                          // อัปเดต rating, favorite และเพิ่ม comment ลงใน Firestore
                          updateRatingAndCommentInFirestore(
                            widget.toonId,
                            widget.episodeId,
                            isFavorite,
                            newComment.text,
                          );
                          setState(() {
                            comments.add(newComment);
                            commentController.clear();
                            // commentIndex++;
                          });
                        }
                      },
                      child: Text('Submit Comment'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      // appbar ล่าง
      bottomNavigationBar: _isBarsVisible
          ? BottomAppBar(
              color: Color.fromARGB(255, 222, 150, 174),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: StreamBuilder<bool>(
                            stream: checkIfUserIsFavoriteStream(
                                widget.toonId,
                                widget
                                    .episodeId), // สร้างฟังก์ชันนี้เพื่อรับ Stream ในการติดตามการกด Favorite
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
                                final isUserFavorite = snapshot.data ?? false;
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

                            updateRatingInFirestore(
                                widget.toonId, widget.episodeId, isFavorite);
                          },
                        ),
                        FutureBuilder<int>(
                          future: getRatingFromFirestore(
                              widget.toonId, widget.episodeId),
                          builder: (context, snapshot) {
                            return Text(
                              '${snapshot.data ?? 0}',
                              style: TextStyle(fontSize: 16),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
