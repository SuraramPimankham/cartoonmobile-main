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
  late Map<String, dynamic> _episodeDetails;
  List<Map<String, dynamic>> episodesData = [];
  List<String> docIds = [];
  User? _user;
  List<Map<String, dynamic>> _purchasedEpisodesData = [];

  @override
  void initState() {
    super.initState();
    _episodeDetails = {};
    _fetchEpisodeDetails(widget.episodeData['id']);
  }

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
                'timestamp': value,
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

  void goToEpisodePage(String episodeId) {
    print('User is navigating to EpisodePage for episode: $episodeId');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpisodePage(
          toonId: widget.episodeData['id'],
          episodeId: episodeId,
          episodes: _purchasedEpisodesData
              .map((episode) => episode['id'].toString())
              .toList(),
        ),
      ),
    );
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
                      child: GestureDetector(
                        child: Row(
                          children: [
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(
                                      'ชื่อ: ${_purchasedEpisodesData[index]['title']}',
                                    ),
                                    subtitle: _purchasedEpisodesData[index]
                                                .containsKey('image') &&
                                            _purchasedEpisodesData[index]
                                                ['image'] is List &&
                                            (_purchasedEpisodesData[index]
                                                    ['image'] as List)
                                                .isNotEmpty
                                        ? Container(
                                            height: 60,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  (_purchasedEpisodesData[index]
                                                          ['image'] as List)
                                                      .length,
                                              itemBuilder:
                                                  (context, imageIndex) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: Image.network(
                                                    (_purchasedEpisodesData[
                                                            index]['image']
                                                        as List)[imageIndex],
                                                    height: 50,
                                                    width: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
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
