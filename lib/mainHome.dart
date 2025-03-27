import 'package:flutter/material.dart';
import 'package:sgsits_gym/Admin_functionalities/contactOwner.dart';
import 'package:sgsits_gym/HomePages/GsHome.dart';
import 'package:sgsits_gym/pages/loginpage.dart';

class Mainhome extends StatefulWidget {
  Mainhome({super.key});

  @override
  State<Mainhome> createState() => _MainhomeState();
}

class _MainhomeState extends State<Mainhome> {
  List<Widget>? itemss = [
    Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          border: Border.all(color: Colors.black, width: 1)),
      child: Column(
        children: [
          Image.asset(
            "assets/gym2.jpg",
            fit: BoxFit.contain,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "\"Better Equipments\"",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          )
        ],
      ),
    ),
    Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          border: Border.all(color: Colors.black, width: 1)),
      child: Column(
        children: [
          Image.asset(
            "assets/gym.jpg",
            fit: BoxFit.contain,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "\"Better Hygiene\"",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          )
        ],
      ),
    ),
    Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          border: Border.all(color: Colors.black, width: 1)),
      child: Column(
        children: [
          Image.asset(
            "assets/gym2.jpg",
            fit: BoxFit.contain,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "\"Certified Trainers\"",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          )
        ],
      ),
    ),
    Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          border: Border.all(color: Colors.black, width: 1)),
      child: Column(
        children: [
          Image.asset(
            "assets/gym3.jpg",
            fit: BoxFit.contain,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "\"Less Cost\"",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          )
        ],
      ),
    ),
    Container(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)),
            border: Border.all(color: Colors.black, width: 1)),
        child: Column(children: [
          Image.asset(
            "assets/gym.jpg",
            fit: BoxFit.contain,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "\"Well Developed Architecture\"",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          )
        ]))
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Colors.blue[100],
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
        title: Text(
          "Welcome, To GS Gym!",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Builder(
          builder: (context) => ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
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
                    SizedBox(height: 10),
                    Text(
                      'GS Gym',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.blue),
                title: Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Mainhome(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text("Login Screen"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Loginpage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text("About Us"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactOwner()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_mail, color: Colors.blue),
                title: Text("Contact Us"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactOwner()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Gshome(items: itemss!),
    );
  }
}
