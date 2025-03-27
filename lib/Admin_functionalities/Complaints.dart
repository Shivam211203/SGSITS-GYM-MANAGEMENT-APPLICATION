import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Complaints extends StatefulWidget {
  const Complaints({super.key});

  @override
  State<Complaints> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<Complaints> {
  // Add this new method for showing the complaint dialog
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
                await FirebaseFirestore.instance.collection('complaints').add({
                  'complaints': '0 ${_controller.text.trim()}',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
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
                colors: [Colors.blue[600]!, Colors.blue[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
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
          "Complaints",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      // Add floating action button here
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddComplaintDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Add sorting by timestamp
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Complaints"));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data() as Map<String, dynamic>;
              final complaintText = data['complaints'];
              final isSolved = complaintText.startsWith('1');
              final complaintContent = complaintText.substring(2);

              return Dismissible(
                key: Key(document.id),
                background: Container(color: Colors.red),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(document.id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint deleted')));
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      complaintContent,
                      style: TextStyle(
                        fontSize: 16,
                        decoration:
                            isSolved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    // Add timestamp display
                    subtitle: data['timestamp'] != null
                        ? Text(
                            'Submitted: ${(data['timestamp'] as Timestamp).toDate().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: isSolved
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('complaints')
                                  .doc(document.id)
                                  .update({
                                'complaints': '1 $complaintContent',
                              });
                            },
                            child: const Text('Mark as Solved',
                                style: TextStyle(color: Colors.white)),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
