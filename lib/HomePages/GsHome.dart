import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sgsits_gym/HomePages/adminhome.dart';
import 'package:sgsits_gym/HomePages/userHome.dart';
import 'package:sgsits_gym/pages/loginpage.dart';

class Gshome extends StatefulWidget {
  Gshome({required this.items, super.key});
  final List<Widget> items;
  @override
  State<Gshome> createState() => _GshomeState();
}

class _GshomeState extends State<Gshome> {
  bool _isLoading = false;
  Future<bool> _checkAuthentication() async {
    _isLoading = true;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Userhome(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Adminhome(),
            ),
          );
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    } else {
      return false;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      return true;
    }
    return false;
  }

  int _currIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
      child: Column(
        children: [
          Text(
            "\"Welcome To SGSITS GYMNASIUM\"",
            style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontSize: 15),
          ),
          SizedBox(
            height: 20,
          ),
          Column(
            children: [
              CarouselSlider(
                items: widget.items,
                options: CarouselOptions(
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currIndex = index;
                    });
                  },
                  height: MediaQuery.of(context).size.height * 0.43,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  autoPlayInterval: Duration(seconds: 2),
                  autoPlayAnimationDuration: Duration(milliseconds: 1000),
                  enableInfiniteScroll: true,
                  viewportFraction: 0.8,
                  initialPage: 0,
                  disableCenter: false,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.items.map((image) {
                  int index = widget.items.indexOf(image);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.blue[800]!,
                            width: 1), // Changed to blue
                        color: index == _currIndex
                            ? Colors.blue[600]!
                            : Colors.white,
                        shape: BoxShape.circle),
                  );
                }).toList(),
              )
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Text(
            textAlign: TextAlign.center,
            "\" Lets Get Fit With SGSITS Gym\" ",
            style: TextStyle(
                color: Colors.blue[800], // Changed to blue
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 15),
          ),
          SizedBox(
            height: 3,
          ),
          Text(
            textAlign: TextAlign.center,
            " If you are new Here Please Contact +917489474338 \n Or login by Tapping Below Button",
            style: TextStyle(
                color: Colors.grey[700], // Changed to grey
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 13),
          ),
          SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () async {
              bool value = await _checkAuthentication();
              if (value == false) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => Loginpage()));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[800]!
                    ], // Changed to blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50)),
              height: 50,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                        "Go to Login Page",
                        style: TextStyle(
                          color: Colors.white, // Changed to white
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
