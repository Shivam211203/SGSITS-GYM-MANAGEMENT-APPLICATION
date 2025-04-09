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
  final _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _membersStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Color _primaryColor = const Color.fromARGB(255, 117, 3, 3);

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  void _setupRealTimeListener() {
    _membersStream = _firestore.collection("Users").snapshots();
  }

  ImageProvider<Object>? _getImageFromBase64(String? base64String) {
    if (base64String == null) return const AssetImage('assets/avtar.jpg');
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      return const AssetImage('assets/avtar.jpg');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Image.asset('assets/logo.jpeg'),
          ),
        ),
        title:
            const Text("Manage Members", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    Signuppage(isAdmin: false, isFromAdmin: true),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Members...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                          color: Colors.red[800], fontWeight: FontWeight.w500),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data!.docs;
                final filteredMembers = members.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchable = [
                    data['firstName']?.toString().toLowerCase() ?? '',
                    data['lastName']?.toString().toLowerCase() ?? '',
                    data['mobileNumber']?.toString().toLowerCase() ?? '',
                    data['memberId']?.toString().toLowerCase() ?? '',
                  ].join(' ');
                  return searchable.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) => _buildMemberCard(
                    filteredMembers[index].data() as Map<String, dynamic>,
                    filteredMembers[index].id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> memberData, String docId) {
    final expiryDate = (memberData['planExpiry'] as Timestamp?)?.toDate();
    final renewalDate = (memberData['lastRenewal'] as Timestamp?)?.toDate();
    final isExpired = expiryDate?.isBefore(DateTime.now()) ?? true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      _getImageFromBase64(memberData['imageBase64']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name',
                          '${memberData['firstName']} ${memberData['lastName']}'),
                      _buildInfoRow('Mobile', memberData['mobileNumber']),
                      _buildInfoRow('Status', isExpired ? 'Expired' : 'Active',
                          color: isExpired ? Colors.red : Colors.green),
                      _buildInfoRow('Member ID',
                          memberData['memberId'].toString().substring(0, 7)),
                      _buildInfoRow(
                          'Last Renewed',
                          renewalDate != null
                              ? DateFormat('yyyy-MM-dd').format(renewalDate)
                              : 'N/A'),
                      _buildInfoRow(
                          'Plan Expiry',
                          expiryDate != null
                              ? DateFormat('yyyy-MM-dd').format(expiryDate)
                              : 'N/A',
                          color: Colors.red),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMoreDialog(memberData, docId),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(Icons.message, 'whatsapp', Colors.green,
                    () => _openWhatsApp(memberData['mobileNumber'])),
                _buildIconButton(Icons.autorenew, 'renew', Colors.blue,
                    () => _showRenewalDialog(memberData, docId)),
                _buildIconButton(Icons.call, 'call', Colors.black,
                    () => _makePhoneCall(memberData['mobileNumber'])),
                _buildIconButton(Icons.delete, 'delete', Colors.red,
                    () => _deleteMember(docId)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color ?? Colors.grey)),
        ],
      ),
    );
  }

  void _showMoreDialog(Map<String, dynamic> memberData, String docId) {
    String? selectedAction;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Manage ${memberData['firstName']}"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Select Action"),
          value: selectedAction,
          items: const [
            DropdownMenuItem(
                value: "Reset-Expiry", child: Text("Reset Expiry")),
            DropdownMenuItem(
                value: "Assign-meals", child: Text("Assign Meals")),
            DropdownMenuItem(
                value: "Assign-workouts", child: Text("Assign Workouts")),
          ],
          onChanged: (value) => selectedAction = value,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              switch (selectedAction) {
                case "Reset-Expiry":
                  _firestore.collection('Users').doc(docId).update({
                    'lastRenewal': Timestamp.now(),
                    'planExpiry': Timestamp.now(),
                  });
                  break;
                case "Assign-meals":
                  _showAssignmentDialog('assignedMeals',
                      memberData['assignedMeals']?.join(', ') ?? '', docId);
                  break;
                case "Assign-workouts":
                  _showAssignmentDialog('assignedWorkouts',
                      memberData['assignedWorkouts']?.join(', ') ?? '', docId);
                  break;
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(String field, String currentValue, String docId) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text("Assign ${field == 'assignedMeals' ? 'Meals' : 'Workouts'}"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
              hintText: 'Enter items separated by commas'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final items = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              _firestore.collection('Users').doc(docId).update({field: items});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRenewalDialog(Map<String, dynamic> memberData, String docId) {
    String? duration;
    DateTime? customDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Renew Plan for ${memberData['firstName']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: duration,
                decoration: const InputDecoration(labelText: "Select Duration"),
                items: const [
                  DropdownMenuItem(value: "1 month", child: Text("1 Month")),
                  DropdownMenuItem(value: "3 months", child: Text("3 Months")),
                  DropdownMenuItem(value: "6 months", child: Text("6 Months")),
                  DropdownMenuItem(
                      value: "12 months", child: Text("12 Months")),
                  DropdownMenuItem(value: "custom", child: Text("Custom Date")),
                ],
                onChanged: (value) async {
                  setState(() => duration = value);
                  if (value == "custom") {
                    final date = await _selectCustomDate(context);
                    setState(() => customDate = date);
                  }
                },
              ),
              if (duration == "custom")
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    customDate != null
                        ? "Selected: ${DateFormat('yyyy-MM-dd').format(customDate!)}"
                        : "No date selected",
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                if (duration != null) {
                  _renewPlan(
                      docId,
                      duration == "custom" && customDate != null
                          ? customDate!
                          : duration!);
                  Navigator.pop(context);
                }
              },
              child: const Text("Renew"),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _selectCustomDate(BuildContext context) => showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 30)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );

  void _renewPlan(String docId, dynamic durationOrDate) {
    final now = DateTime.now();
    DateTime newExpiry = durationOrDate is DateTime
        ? durationOrDate
        : _addDuration(now, durationOrDate as String);

    _firestore.collection('Users').doc(docId).update({
      'planExpiry': Timestamp.fromDate(newExpiry),
      'lastRenewal': Timestamp.fromDate(now),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan renewed successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error renewing plan: $error")),
      );
    });
  }

  DateTime _addDuration(DateTime startDate, String duration) {
    final months = {
      '1 month': 1,
      '3 months': 3,
      '6 months': 6,
      '12 months': 12,
    };
    return DateTime(
      startDate.year,
      startDate.month + (months[duration] ?? 1),
      startDate.day,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse("tel:+91$phoneNumber");
    if (await Permission.phone.request().isGranted && await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to make call")),
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final url = Uri.parse("https://wa.me/+91$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }

  void _deleteMember(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member?'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _firestore.collection('Users').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
