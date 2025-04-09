import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:sgsits_gym/Admin_functionalities/contactOwner.dart';
import 'package:sgsits_gym/HomePages/DetailsScreen.dart';
import 'package:sgsits_gym/mainHome.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:intl/intl.dart';

class Userhome extends StatefulWidget {
  const Userhome({Key? key}) : super(key: key);

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late Stream<DocumentSnapshot?> _userStream;
  late Stream<DocumentSnapshot> _announcementStream;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupStreams();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _setupStreams() {
    final userEmail = _auth.currentUser?.email;
    if (userEmail != null) {
      _userStream = _firestore
          .collection("Users")
          .where("email", isEqualTo: userEmail)
          .snapshots()
          .map((query) => query.docs.isNotEmpty ? query.docs.first : null);
    } else {
      _userStream = Stream.value(null);
    }
    _announcementStream =
        _firestore.collection("Announcements").doc("Announcements").snapshots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double calculatePlanProgress(DateTime? lastRenewal, DateTime? planExpiry) {
    if (lastRenewal == null || planExpiry == null) return 0.0;
    final now = DateTime.now().toUtc();
    final start = lastRenewal.toUtc();
    final end = planExpiry.toUtc();
    if (now.isAfter(end)) return 0;
    final totalDuration = end.difference(start).inSeconds;
    final elapsedDuration = now.difference(start).inSeconds;
    if (totalDuration <= 0) return 0.0;
    final progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    return 100 - (progress * 100).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      endDrawer: _buildDrawer(),
      body: _buildBody(context),
    );
  }

  void _showAddComplaintDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Complaint'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Enter your complaint here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_controller.text.trim().isNotEmpty) {
                await _firestore.collection('complaints').add({
                  'complaints': '0 ${_controller.text.trim()}',
                  'timestamp': FieldValue.serverTimestamp(),
                  'userEmail': _auth.currentUser?.email,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      toolbarHeight: 70,
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
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
          ),
        ),
      ),
      title: StreamBuilder<DocumentSnapshot?>(
        stream: _userStream,
        builder: (context, snapshot) {
          final name = snapshot.data?.data() != null
              ? (snapshot.data!.data() as Map<String, dynamic>)['firstName']
                      as String? ??
                  'User'
              : 'User';
          return Text(
            "Welcome, $name!",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          );
        },
      ),
      actions: [
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            );
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF0F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot?>(
          stream: _userStream,
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final assignedWorkouts =
                List<String>.from(data?['assignedWorkouts'] ?? []);
            final assignedMeals =
                List<String>.from(data?['assignedMeals'] ?? []);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[900]!, Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Image.asset('assets/logo.jpeg',
                              fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'GS Gym',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                    Icons.home_rounded, "Home", () => Navigator.pop(context)),
                _buildDrawerItem(Icons.person_rounded, "Register a Complaint",
                    _showAddComplaintDialog),
                _buildDrawerItem(
                    Icons.fitness_center_rounded,
                    "Workouts",
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailsScreen(
                                  items: assignedWorkouts, title: "Workouts")),
                        )),
                _buildDrawerItem(
                    Icons.restaurant_rounded,
                    "Meals",
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailsScreen(
                                  items: assignedMeals, title: "Meals")),
                        )),
                _buildDrawerItem(
                    Icons.info_rounded,
                    "Contact Us",
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ContactOwner()),
                        )),
                _buildDrawerItem(Icons.logout_rounded, "Logout", () async {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Mainhome()),
                      (route) => false,
                    );
                  }
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text("Do you want to go back to the login screen?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Mainhome()),
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
            _buildAnnouncementBanner(),
            Expanded(
              child: FadeTransition(
                opacity: _animation,
                child: SafeArea(child: _buildDashboardCard(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _announcementStream,
      builder: (context, snapshot) {
        final announcements =
            snapshot.data?.get("Announcements") as List<dynamic>?;
        final text = announcements?.isNotEmpty ?? false
            ? announcements!.last.toString()
            : "No announcements";

        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Marquee(
                  text: text,
                  style: const TextStyle(
                      color: Colors.deepOrange, fontWeight: FontWeight.w500),
                  velocity: 50.0,
                  blankSpace: 20.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('User data not found'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final base64Image = data['imageBase64'] as String?;
        final firstName = data['firstName'] as String? ?? 'User';
        final lastName = data['lastName'] as String? ?? '';
        final mobileNumber = data['mobileNumber'] as String? ?? 'N/A';
        final lastRenewal = (data['lastRenewal'] as Timestamp?)?.toDate();
        final planExpiry = (data['planExpiry'] as Timestamp?)?.toDate();
        final progress = calculatePlanProgress(lastRenewal, planExpiry);

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: 2,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSection(base64Image),
                  const SizedBox(height: 32),
                  _buildProgressIndicator(progress, lastRenewal, planExpiry),
                  const SizedBox(height: 32),
                  _buildMemberDetailsGrid(
                      data, firstName, lastName, mobileNumber),
                  const SizedBox(height: 32),
                  _buildNavigationButtons(context, data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(String? base64Image) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.red[100]!, blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: ClipOval(
              child: base64Image != null
                  ? Image.memory(
                      base64Decode(base64Image),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.blue.shade50,
                        child: Icon(Icons.person,
                            size: 60, color: Colors.blue.shade300),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: Colors.blue.shade50,
                      child: Icon(Icons.person,
                          size: 60, color: Colors.blue.shade300),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
      double progress, DateTime? lastRenewal, DateTime? planExpiry) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Membership Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 90, 1, 10),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularStepProgressIndicator(
                      totalSteps: 100,
                      currentStep: progress.toInt(),
                      stepSize: 10,
                      selectedColor: Colors.red.shade200,
                      unselectedColor: Colors.white,
                      padding: 0,
                      width: 120,
                      height: 120,
                      selectedStepSize: 14,
                      roundedCap: (_, __) => true,
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${progress.toInt()}%",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800]),
                          ),
                          Text("Remaining",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressDetailItem(
                      "Start Date",
                      lastRenewal != null
                          ? DateFormat('dd MMM yyyy').format(lastRenewal)
                          : "N/A",
                      Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressDetailItem(
                      "End Date",
                      planExpiry != null
                          ? DateFormat('dd MMM yyyy').format(planExpiry)
                          : "N/A",
                      Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressDetailItem(
                      "Days Left",
                      planExpiry != null
                          ? "${planExpiry.difference(DateTime.now()).inDays} days"
                          : "N/A",
                      Icons.timer_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetailItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1),
            ],
          ),
          child: Icon(icon, color: Colors.red, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800])),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberDetailsGrid(Map<String, dynamic> data, String firstName,
      String lastName, String mobileNumber) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Member Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 107, 2, 2),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildDetailItem(Icons.person_outline_rounded, "Member Name",
                  "$firstName $lastName"),
              _buildDetailItem(
                  Icons.credit_card_rounded,
                  "Member ID",
                  data['memberId']?.toString().substring(0, 8).toUpperCase() ??
                      "N/A"),
              _buildDetailItem(Icons.phone_rounded, "Mobile", mobileNumber),
              _buildDetailItem(Icons.email_rounded, "Email",
                  _auth.currentUser?.email ?? "N/A"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
      BuildContext context, Map<String, dynamic> data) {
    final assignedWorkouts = List<String>.from(data['assignedWorkouts'] ?? []);
    final assignedMeals = List<String>.from(data['assignedMeals'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "View Your Plans",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 87, 2, 4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                "View Meals",
                Icons.restaurant_rounded,
                const Color.fromARGB(255, 105, 1, 1),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DetailsScreen(items: assignedMeals, title: "Meals")),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                "View Workouts",
                Icons.fitness_center_rounded,
                const Color.fromARGB(255, 89, 1, 1),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailsScreen(
                          items: assignedWorkouts, title: "Workouts")),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
