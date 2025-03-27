import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:sgsits_gym/Admin_functionalities/Admins_homes.dart';
import 'package:sgsits_gym/Admin_functionalities/Complaints.dart';
import 'package:sgsits_gym/Admin_functionalities/announcements.dart';
import 'package:sgsits_gym/Admin_functionalities/contactOwner.dart';
import 'package:sgsits_gym/Admin_functionalities/members_Home.dart';
import 'package:sgsits_gym/mainHome.dart';

class Adminhome extends StatefulWidget {
  const Adminhome({Key? key}) : super(key: key); // Corrected key

  @override
  State<Adminhome> createState() => _AdminhomeState();
}

class _AdminhomeState extends State<Adminhome> {
  QuerySnapshot? details;
  String? firstName;
  String? mobileNumber;
  String? lastName;
  String email = FirebaseAuth.instance.currentUser!.email.toString();
  String? announcement;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  void onBackPress() {
    Navigator.pop(context);
  }

  Future<void> onRefresh() async {
    setState(() {
      announcement = null;
      firstName = null;
      lastName = null;
      mobileNumber = null;
    });

    await getUserDetails();
  }

  Future<void> getUserDetails() async {
    try {
      // Force fresh data by using source: Source.server
      final details = await FirebaseFirestore.instance
          .collection("Admins")
          .where("email", isEqualTo: FirebaseAuth.instance.currentUser!.email)
          .get(GetOptions(source: Source.server));

      final announcementSnapshot = await FirebaseFirestore.instance
          .collection("Announcements")
          .doc("Announcements")
          .get(GetOptions(source: Source.server));

      if (announcementSnapshot.exists) {
        final announcementsList =
            announcementSnapshot.get("Announcements") as List<dynamic>;
        setState(() {
          announcement = announcementsList.isNotEmpty
              ? announcementsList.last.toString()
              : "No announcements";
        });
      } else {
        setState(() => announcement = "No announcements");
      }

      if (details.docs.isNotEmpty) {
        final doc = details.docs.first;
        setState(() {
          mobileNumber = doc.get("mobileNumber") as String?;
          firstName = doc.get("firstName") as String?;
          lastName = doc.get("lastName") as String?;
        });
      }
    } catch (e) {
      print("Error fetching admin details: $e");
      setState(() => announcement = "Error loading announcements");
    }
  }

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
          "Welcome, ${firstName ?? 'Admin'}!",
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
                leading: Icon(Icons.logout, color: Colors.blue),
                title: Text("Logout"),
                onTap: () async {
                  try {
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Mainhome()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logout failed: ${e.toString()}")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content:
                  const Text("Do you want to go back to the login screen?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Mainhome()),
                      (route) => false,
                    );
                  },
                  child: const Text("Yes"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No"),
                ),
              ],
            ),
          );
          return false;
        },
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: announcement != null
                              ? Marquee(
                                  text: announcement!,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  velocity: 50.0,
                                  blankSpace: 20.0,
                                )
                              : const CircularProgressIndicator(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Choose What You Wanna Do Today!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            "Manage Members",
                            Icons.people_outline,
                            Colors.blue[600]!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MembersHome()),
                              );
                            },
                          ),
                          _buildActionCard(
                            "Add User/Admin",
                            Icons.person_add_outlined,
                            Colors.blue[700]!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MembersHome()),
                              );
                            },
                          ),
                          _buildActionCard(
                            "Announcements",
                            Icons.announcement_outlined,
                            Colors.blue[800]!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Announcements()),
                              );
                            },
                          ),
                          _buildActionCard(
                            "Complaints",
                            Icons.report_problem_outlined,
                            Colors.blue[900]!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Complaints()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    "or Manage Admins {requires admin key}",
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildButton("Manage Admins", () {
                    TextEditingController keyController =
                        TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Enter Admin Key"),
                        content: TextField(
                          controller: keyController,
                          decoration:
                              const InputDecoration(hintText: "Admin Key"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              try {
                                DocumentSnapshot snap = await FirebaseFirestore
                                    .instance
                                    .collection("AdminKey")
                                    .doc("Admin-key")
                                    .get();

                                if (!snap.exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Admin key not found!")),
                                  );
                                  return;
                                }

                                Map<String, dynamic>? _adminKeyMap =
                                    snap.data() as Map<String, dynamic>?;

                                if (_adminKeyMap != null &&
                                    keyController.text == _adminKeyMap["Key"]) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminsHome()),
                                  );
                                } else {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Invalid Admin Key!")),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Error: ${e.toString()}")),
                                );
                              }
                            },
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildButton("Contact Owner", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ContactOwner();
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
