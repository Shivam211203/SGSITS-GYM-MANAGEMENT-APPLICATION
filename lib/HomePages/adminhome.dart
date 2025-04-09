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
  const Adminhome({super.key});

  @override
  State<Adminhome> createState() => _AdminhomeState();
}

class _AdminhomeState extends State<Adminhome> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late Stream<DocumentSnapshot?> _adminStream;
  late Stream<DocumentSnapshot> _announcementStream;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    final userEmail = _auth.currentUser?.email;
    if (userEmail != null) {
      _adminStream = _firestore
          .collection("Admins")
          .where("email", isEqualTo: userEmail)
          .snapshots()
          .map((query) => query.docs.isNotEmpty ? query.docs.first : null);
    } else {
      _adminStream = Stream.value(null);
    }
    _announcementStream =
        _firestore.collection("Announcements").doc("Announcements").snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Mainhome()));
      });
      return const SizedBox();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      endDrawer: _buildDrawer(),
      body: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              content:
                  const Text("Do you want to go back to the login screen?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No"),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Mainhome()),
              (route) => false,
            );
          }
          return false;
        },
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[800]!, Colors.black],
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
          child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
        ),
      ),
      title: StreamBuilder<DocumentSnapshot?>(
        stream: _adminStream,
        builder: (context, snapshot) {
          final name = snapshot.data?.data() != null
              ? (snapshot.data!.data() as Map<String, dynamic>)['firstName']
                      as String? ??
                  'Admin'
              : 'Admin';
          return Text(
            "Welcome, $name!",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          );
        },
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[800]!, Colors.black],
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
                  child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ProBody Line Gym',
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
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () async {
              try {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Mainhome()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout failed: ${e.toString()}")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: _announcementStream,
          builder: (context, snapshot) {
            final announcements =
                snapshot.data?.get("Announcements") as List<dynamic>?;
            final text = announcements?.isNotEmpty ?? false
                ? announcements!.last.toString()
                : "No announcements";

            return Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Marquee(
                      text: snapshot.hasData ? text : "Loading...",
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500),
                      velocity: 50.0,
                      blankSpace: 20.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          "Choose What You Wanna Do Today!",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                  const Color.fromARGB(255, 184, 5, 2),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MembersHome())),
                ),
                _buildActionCard(
                  "Add User/Admin",
                  Icons.person_add_outlined,
                  const Color.fromARGB(255, 157, 3, 3),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MembersHome())),
                ),
                _buildActionCard(
                  "Announcements",
                  Icons.announcement_outlined,
                  const Color.fromARGB(255, 103, 1, 1),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Announcements())),
                ),
                _buildActionCard(
                  "Complaints",
                  Icons.report_problem_outlined,
                  const Color.fromARGB(255, 102, 1, 1),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Complaints())),
                ),
              ],
            ),
          ),
        ),
        Text(
          "or Manage Admins {requires admin key}",
          style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        _buildButton("Manage Admins", _showAdminKeyDialog),
        const SizedBox(height: 10),
        _buildButton("Contact Owner", () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ContactOwner()));
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      color: Colors.white),
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
            colors: [Colors.red[800]!, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _showAdminKeyDialog() {
    final TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Admin Key"),
        content: TextField(
          controller: keyController,
          decoration: const InputDecoration(hintText: "Admin Key"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final snap = await _firestore
                    .collection("AdminKey")
                    .doc("Admin-key")
                    .get();
                if (!snap.exists) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Admin key not found!")),
                    );
                  }
                  return;
                }

                final adminKeyMap = snap.data() as Map<String, dynamic>?;
                if (adminKeyMap != null &&
                    keyController.text == adminKeyMap["Key"]) {
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminsHome()));
                  }
                } else {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid Admin Key!")),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
