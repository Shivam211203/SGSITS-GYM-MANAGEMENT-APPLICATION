import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sgsits_gym/pages/signupPage.dart';
import 'package:permission_handler/permission_handler.dart';

class MembersHome extends StatefulWidget {
  const MembersHome({super.key});

  @override
  State<MembersHome> createState() => _MembersHomeState();
}

class _MembersHomeState extends State<MembersHome> {
  ImageProvider<Object>? _getImageFromBase64(String? base64String) {
    if (base64String == null) return null;
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  List<DocumentSnapshot> member_list = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Color _primaryColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      QuerySnapshot userCollection =
          await FirebaseFirestore.instance.collection("Users").get();
      setState(() {
        member_list = userCollection.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch members: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> filteredMembers = [];
    if (!_isLoading && _errorMessage == null) {
      filteredMembers = member_list.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String firstName = data['firstName']?.toString().toLowerCase() ?? '';
        String lastName = data['lastName']?.toString().toLowerCase() ?? '';
        String mobile = data['mobileNumber']?.toString().toLowerCase() ?? '';
        String memberId = data['memberId']?.toString().toLowerCase() ?? '';
        String searchable = '$firstName $lastName $mobile $memberId';
        return searchable.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Image.asset('assets/logo.jpeg'),
          ),
        ),
        title: const Text(
          "Manage Members",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Signuppage(
                      isAdmin: false,
                      isFromAdmin: true,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return Future.value(true);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8, left: 8, right: 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Members...',
                            prefixIcon:
                                Icon(Icons.search, color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: ListView.builder(
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final memberData = filteredMembers[index].data()
                                  as Map<String, dynamic>;
                              return _buildMemberCard(memberData);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> memberData) {
    final Timestamp? expiryTimestamp = memberData['planExpiry'];
    final Timestamp? renewalTimestamp = memberData['lastRenewal'];

    final DateTime? expiryDate = expiryTimestamp?.toDate();
    final DateTime? renewalDate = renewalTimestamp?.toDate();

    final bool isExpired =
        expiryDate == null || expiryDate.isBefore(DateTime.now());
    return Container(
      height: MediaQuery.of(context).size.height * 0.23,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey[100]!,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: 16, bottom: 5, left: 16, right: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: 18,
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              _getImageFromBase64(memberData['imageBase64']) ??
                                  AssetImage('assets/avtar.jpg'),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          memberData['firstName'][0].toUpperCase() +
                              memberData['firstName']
                                  .substring(1)
                                  .toLowerCase(),
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text("Mobile",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text(
                          memberData['mobileNumber'],
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text("Plan Status",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text(isExpired ? "Expired" : "Active",
                            style: TextStyle(
                                color: isExpired ? Colors.red : Colors.green,
                                fontSize: 11)),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MemberId",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          memberData['memberId'].toString().substring(0, 7),
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text("Last  Renewed",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text(
                          renewalDate != null
                              ? DateFormat('yyyy-MM-dd').format(renewalDate)
                              : "Not Available",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text("Plan Expiry",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text(
                            expiryDate != null
                                ? DateFormat('yyyy-MM-dd').format(expiryDate)
                                : "Not Available",
                            style: TextStyle(color: Colors.red, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildIconButton(
                        Icons.message, "whatsapp", Colors.green, memberData),
                    SizedBox(width: 30),
                    _buildIconButton(
                        Icons.autorenew, "renew", Colors.blue, memberData),
                    SizedBox(width: 30),
                    _buildIconButton(
                        Icons.call, "call", Colors.black, memberData),
                    SizedBox(width: 30),
                    _buildIconButton(
                        Icons.delete, "delete", Colors.red, memberData),
                    SizedBox(width: 15),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _buildStatusChip(
              isExpired ? 'Expired' : 'Active',
              isExpired ? Colors.red : Colors.green,
            ),
          ),
          Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () {
                  _showMoreDialog(memberData);
                },
                icon: Icon(Icons.more_vert),
              )),
        ],
      ),
    );
  }

// Add this helper method to show assignment dialogs
  void _showAssignmentDialog(BuildContext context, String field,
      String currentValue, String memberId) {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text("Assign ${field == 'assignedMeals' ? 'Meals' : 'Workouts'}"),
          content: TextFormField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter items separated by commas',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                List<String> items = controller.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                FirebaseFirestore.instance
                    .collection('Users')
                    .doc(memberId)
                    .update({
                  field: items,
                }).then((_) {
                  Navigator.pop(context);
                  _fetchMembers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "${field == 'assignedMeals' ? 'Meals' : 'Workouts'} updated successfully!")),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Error updating: ${error.toString()}")),
                  );
                });
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

// Update the _showMoreDialog function
  void _showMoreDialog(memberData) async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(memberData['memberId'])
        .get();
    Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;

    String? selectedIndex;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Manage ${memberData['firstName']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Action",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: selectedIndex,
                items: const [
                  DropdownMenuItem(
                    value: "Reset-Expiry",
                    child: Text("Reset Expiry"),
                  ),
                  DropdownMenuItem(
                    value: "Assign-meals",
                    child: Text("Assign meals"),
                  ),
                  DropdownMenuItem(
                    value: "Assign-workouts",
                    child: Text("Assign workouts"),
                  ),
                ],
                onChanged: (value) => selectedIndex = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (selectedIndex == "Reset-Expiry") {
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(memberData['memberId'])
                        .update({
                      'lastRenewal': DateTime.now(),
                      'planExpiry': DateTime.now(),
                    });
                    _fetchMembers();
                  } else if (selectedIndex == "Assign-meals") {
                    _showAssignmentDialog(
                      context,
                      'assignedMeals',
                      (userData['assignedMeals'] as List?)?.join(', ') ?? '',
                      memberData['memberId'],
                    );
                  } else if (selectedIndex == "Assign-workouts") {
                    _showAssignmentDialog(
                      context,
                      'assignedWorkouts',
                      (userData['assignedWorkouts'] as List?)?.join(', ') ?? '',
                      memberData['memberId'],
                    );
                  }
                },
                child: Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, Color color,
      Map<String, dynamic> memberData) {
    return InkWell(
      onTap: () {
        if (label == 'renew') {
          _showRenewalDialog(memberData);
        } else if (label == 'delete') {
          _deleteMember(memberData['memberId']);
        } else if (label == 'whatsapp') {
          _openWhatsApp(memberData['mobileNumber']);
        } else if (label == 'call') {
          _makePhoneCall(memberData['mobileNumber']);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenewalDialog(Map<String, dynamic> memberData) {
    String? selectedDuration;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Renew Plan for ${memberData['firstName']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Duration",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "1 month",
                    child: Text("1 Month"),
                  ),
                  DropdownMenuItem(
                    value: "3 months",
                    child: Text("3 Months"),
                  ),
                  DropdownMenuItem(
                    value: "6 months",
                    child: Text("6 Months"),
                  ),
                  DropdownMenuItem(
                    value: "12 months",
                    child: Text("12 Months"),
                  ),
                ],
                onChanged: (value) {
                  selectedDuration = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedDuration != null) {
                    _renewPlan(
                        memberData['memberId'], selectedDuration!, memberData);
                    Navigator.pop(context);
                  }
                },
                child: Text("Renew Plan"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _renewPlan(
      String memberId, String duration, Map<String, dynamic> memberData) {
    try {
      final DateTime now = DateTime.now().toUtc(); // Use UTC for consistency
      final Timestamp? expiryTimestamp = memberData['planExpiry'] as Timestamp?;
      final DateTime? currentExpiry = expiryTimestamp?.toDate();

      // Validate current expiry date
      if (currentExpiry != null && currentExpiry.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Plan already expired. Starting new plan.")),
        );
      }

      // Calculate new expiry date
      final DateTime newExpiry = _addDuration(
        currentExpiry != null && currentExpiry.isAfter(now)
            ? currentExpiry
            : now,
        duration,
      );

      // Update Firestore
      FirebaseFirestore.instance.collection('Users').doc(memberId).update({
        'planExpiry': Timestamp.fromDate(newExpiry), // Store as Timestamp
        'lastRenewal': Timestamp.fromDate(now),
      }).then((_) {
        _fetchMembers(); // Refresh the member list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Plan renewed successfully!")),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error renewing plan: $error")),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Check if the CALL_PHONE permission is granted
      if (await Permission.phone.request().isGranted) {
        String formattedPhoneNumber =
            phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
        String url = "tel:$formattedPhoneNumber";

        if (await canLaunch(url)) {
          await launch(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not make a call")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone call permission denied")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error making call: $e")),
      );
      print("Error making call: $e");
    }
  }

  DateTime _addDuration(DateTime startDate, String duration) {
    switch (duration) {
      case '1 month':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case '3 months':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case '6 months':
        return DateTime(startDate.year, startDate.month + 6, startDate.day);
      case '12 months':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  void _deleteMember(String? uid) {
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Member?'),
        content: SizedBox(
          height: 100,
          child: Column(
            children: [
              Text('Are you sure you want to delete this member?'),
              Text(
                'Deleting this will delete the user from database.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('Users').doc(uid).delete();
              Navigator.pop(context);
              _fetchMembers();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Function to open WhatsApp
  void _openWhatsApp(String phoneNumber) async {
    // Ensure the phone number is in international format
    String formattedPhoneNumber =
        phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    String url = "https://wa.me/$formattedPhoneNumber";

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }
}
