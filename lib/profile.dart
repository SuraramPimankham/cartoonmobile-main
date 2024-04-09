import 'package:cartoonmobile/screen/login.dart';
import 'package:flutter/material.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 172, 167, 167), // สีพื้นหลังหน้าจอ
      body: Center(
        child: Container(
          width: 300, // กำหนดความกว้างของ Container
          height: 400, // กำหนดความสูงของ Container
          decoration: BoxDecoration(
            color:
                Color.fromARGB(255, 241, 129, 166), // สีพื้นหลังของ Container
            borderRadius: BorderRadius.circular(16), // สัดส่วนขอบของ Container
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('images/logo1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16), // เพิ่มระยะห่างระหว่างรูปภาพและข้อความ
              Text(
                'E-Toon',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              SizedBox(height: 16), // เพิ่มระยะห่างระหว่างข้อความและปุ่ม

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        return LoginPage();
                      },
                    ),
                  );
                },
                child: Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
