import 'package:cartoonmobile/Pages/detailpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyFavoritePage extends StatefulWidget {
  const MyFavoritePage({Key? key}) : super(key: key);

  @override
  State<MyFavoritePage> createState() => _MyFavoritePageState();
}

class _MyFavoritePageState extends State<MyFavoritePage> {
  // tab ด้านบน
  final List<Tab> myTabs = <Tab>[
    Tab(text: 'all '),
    Tab(text: 'action'),
    Tab(text: 'comedy'),
    Tab(text: 'fantasy'),
    Tab(text: 'horror'),
    Tab(text: 'romance'),
  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  String uid = '';

  @override
  void initState() {
    super.initState();
    final user = auth.currentUser;
    if (user != null) {
      uid = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      // เช็คการเข้าสู่ระบบ
      return Center(
        child: Text('ท่านยังไม่มีการเข้าสู่ระบบ'),
      );
    }

    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('รายการที่มีการถูกใจ'),
          bottom: TabBar(
            tabs: myTabs,
            isScrollable: true,
          ),
        ),
        body: TabBarView(
          children: List.generate(myTabs.length, (index) {
            return buildGridView(index == 0 ? 'all' : myTabs[index].text!, uid);
          }),
        ),
      ),
    );
  }

  Widget buildGridView(String category, String uid) {
    // ดึงรายการถูกใจ
    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${userSnapshot.error}'));
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
        }

        List<dynamic> favoriteIds = userSnapshot.data!['favorite'] ?? [];

        return FutureBuilder<QuerySnapshot>(
          // ดึง favoriteIds
          future: firestore
              .collection('storys')
              .where('id', whereIn: favoriteIds.isNotEmpty ? favoriteIds : [''])
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }

            List<Map<String, dynamic>> filteredStories = snapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .where((story) => (category == 'all' ||
                    (story['categories'] as List).contains(category)))
                .toList();

            if (!snapshot.hasData || filteredStories.isEmpty) {
              return Center(child: Text('ไม่พบรายการที่ถูกใจ'));
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: filteredStories.length,
              itemBuilder: (BuildContext context, int index) {
                final storyData = filteredStories[index];

                double imageWidth = 200;
                double imageHeight = 150;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          id: storyData['id'],
                          title: storyData['title'],
                          author: storyData['author'],
                          description: storyData['description'],
                          imageUrl: storyData['imageUrl'],
                          recommendation: '',
                        ),
                      ),
                    );
                    print('Card tapped: ${storyData['id']}');
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 40) / 3,
                    height: 200,
                    child: Align(
                      alignment: Alignment.center,
                      child: Card(
                        elevation: 1,
                        child: Container(
                          width: 200,
                          height: 200,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    storyData['imageUrl'],
                                    fit: BoxFit.cover,
                                    height: 140,
                                    width: 100,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      storyData['title'],
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
