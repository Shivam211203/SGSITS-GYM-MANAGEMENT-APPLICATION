import 'package:flutter/material.dart';
import 'package:sgsits_gym/Admin_functionalities/contactOwner.dart';
import 'package:sgsits_gym/HomePages/GsHome.dart';
import 'package:sgsits_gym/pages/loginpage.dart';

class Mainhome extends StatefulWidget {
  const Mainhome({super.key});

  @override
  State<Mainhome> createState() => _MainhomeState();
}

class _MainhomeState extends State<Mainhome> {
  final List<Widget> itemss = [
    _buildItem("assets/gym2.jpg", "Imported Machines ", Colors.white),
    _buildItem("assets/gym3.jpg", "Better Environment", Colors.white),
    _buildItem("assets/gym1.jpg", "Workout Essentials", Colors.white),
    _buildItem("assets/gym4.jpg", "Champion Trainers", Colors.white),
    _buildItem("assets/gym.jpg", "Well Developed Architecture", Colors.white),
  ];

  static Widget _buildItem(String img, String caption, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        children: [
          Image.asset(img, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            "\"$caption\"",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Image.asset(
              'assets/logo.jpeg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          "PRO BODY LINE GYM",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[900]!, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/logo.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PRO BODY LINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile(context, Icons.home, "Home", Mainhome()),
            _drawerTile(context, Icons.person, "Login Screen", Loginpage()),
            _drawerTile(context, Icons.info, "About Us", ContactOwner()),
            _drawerTile(
                context, Icons.contact_mail, "Contact Us", ContactOwner()),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Gshome(items: itemss),
      ),
    );
  }

  ListTile _drawerTile(
      BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
