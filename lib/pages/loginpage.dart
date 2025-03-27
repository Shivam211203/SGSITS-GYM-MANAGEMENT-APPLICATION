import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sgsits_gym/pages/loginUi.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  String text = "User Login";
  bool isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            switchInCurve: Curves.linear,
            child: Image.asset(
              text == "Admin Login"
                  ? "assets/Login_background.jpg"
                  : "assets/Login_background2.jpg",
              key: ValueKey<String>(text),
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.fill,
              color: Colors.white.withOpacity(0.2),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          LoginUi(
            isAdmin: isAdmin,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: GNav(
            mainAxisAlignment: MainAxisAlignment.center,
            color: Colors.blue[100],
            activeColor: Colors.white,
            tabs: [
              GButton(
                icon: Icons.account_circle_sharp,
                text: "User Login",
                onPressed: () {
                  setState(() {
                    text = "User Login";
                    isAdmin = false;
                  });
                },
              ),
              GButton(
                icon: Icons.manage_accounts_rounded,
                text: "Admin Login",
                onPressed: () {
                  setState(() {
                    text = "Admin Login";
                    isAdmin = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
