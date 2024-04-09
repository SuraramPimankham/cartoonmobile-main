
import 'package:cartoonmobile/Pages/menuProfile/DetailCartoonPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyCartoonsPage extends StatefulWidget {
  const MyCartoonsPage({Key? key}) : super(key: key);

  @override
  State<MyCartoonsPage> createState() => _MyCartoonsPageState();
}

class _MyCartoonsPageState extends State<MyCartoonsPage> {
  late User? _user;
  late List<Map<String, dynamic>> _purchasedEpisodesData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _purchasedEpisodesData = [];

    // ตรวจสอบว่าผู้ใช้เข้าสู่ระบบหรือไม่
    if (_user != null) {
      _fetchPurchasedEpisodes();
    }
  }

  // ดึงข้อมูลตอนที่ซื้อจาก Firestore
  void _fetchPurchasedEpisodes() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> purchasedEpisodes =
            userData['purchasedEpisodes'] ?? {};

        print('Fetched purchased episodes data: $purchasedEpisodes');

        List<Map<String, dynamic>> episodesData = [];

        // Loop through episodes in purchasedEpisodes
        for (var entry in purchasedEpisodes.entries) {
          String episodeId = entry.key;

          // ดึงข้อมูลที่เกี่ยวข้องกับคอลเลกชัน 'เรื่องราว' โดยใช้ EpisodeId
          DocumentSnapshot storySnapshot = await FirebaseFirestore.instance
              .collection('storys')
              .doc(episodeId)
              .get();

          if (storySnapshot.exists) {
            Map<String, dynamic> storyData =
                storySnapshot.data() as Map<String, dynamic>;
            String imageUrl = storyData['imageUrl'] ?? '';

            episodesData.add({
              'id': episodeId,
              'title': storyData['title'] ?? 'ไม่พบชื่อตอน',
              'image': imageUrl,
            });
          } else {
            print('Story with ID $episodeId does not exist.');
          }
        }

        setState(() {
          _purchasedEpisodesData = episodesData;
        });
        print('Updated purchased episodes data: $_purchasedEpisodesData');
      } else {
        print('User snapshot does not exist.');
      }
    } catch (e) {
      print('Error fetching purchased episodes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('รายการ'),
                subtitle: const Text('การ์ตูนของฉัน'),
              ),
              if (_purchasedEpisodesData.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchasedEpisodesData.length,
                  itemBuilder: (context, index) {
                    var episodeData = _purchasedEpisodesData[index];

                    return GestureDetector(
                      onTap: () {
                        // ไปที่ Detail CartoonPage เมื่อแตะ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailCartoonpage(episodeData: episodeData),
                          ),
                        );
                      },
                      child: Card(
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: episodeData['image'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        episodeData['image'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                    episodeData['title'] ?? 'ไม่พบชื่อตอน'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_purchasedEpisodesData.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('ไม่มีการ์ตูนที่ซื้อ'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
