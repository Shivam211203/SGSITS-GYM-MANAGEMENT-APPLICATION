import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sgsits_gym/pages/signupPage.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminsHome extends StatefulWidget {
  const AdminsHome({super.key});

  @override
  State<AdminsHome> createState() => _AdminsHomeState();
}

class _AdminsHomeState extends State<AdminsHome> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _admins = [];
  String _searchQuery = '';
  String? _error;
  final Color _primaryColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("Admins").get();

      setState(() {
        _admins = snapshot.docs;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load admins: ${e.toString()}";
      });
    }
  }

  Widget _buildAdminCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data["email"];
    final name = '${data['firstName']} ${data['lastName']}';
    final phone = data['mobileNumber'] ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.12,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            Row(
              children: [
                _buildIconButton(Icons.call, "call", _primaryColor, phone),
                const SizedBox(width: 16),
                _buildIconButton(Icons.delete, "delete", Colors.red, email),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, Color color, String value) {
    return InkWell(
      onTap: () {
        if (label == 'delete') {
          _deleteAdmin(value);
        } else if (label == 'call') {
          _makeCall(value);
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

  Future<void> _deleteAdmin(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Permanently delete this admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('Admins')
            .doc(email)
            .delete();

        await _fetchAdmins();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _admins.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final search = _searchQuery.toLowerCase();
      return doc.id.toLowerCase().contains(search) ||
          '${data['firstName']} ${data['lastName']}'
              .toLowerCase()
              .contains(search) ||
          (data['mobileNumber']?.toString().contains(search) ?? false);
    }).toList();

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
          "Manage Admins",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Signuppage(
                  isAdmin: true,
                  isFromAdmin: true,
                ),
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
                hintText: 'Search admins...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _fetchAdmins,
                    child: ListView.builder(
                      itemCount: filteredAdmins.length,
                      itemBuilder: (_, i) => _buildAdminCard(filteredAdmins[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
