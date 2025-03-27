import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class Announcements extends StatefulWidget {
  const Announcements({super.key});

  @override
  State<Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  final Stream<DocumentSnapshot> _announcementsStream = FirebaseFirestore
      .instance
      .collection("Announcements")
      .doc("Announcements")
      .snapshots();

  Future<void> _addAnnouncement() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Announcement"),
        content: TextField(controller: textController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("Announcements")
                    .doc("Announcements")
                    .update({
                  "Announcements": FieldValue.arrayUnion([textController.text])
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(int index, List currentAnnouncements) async {
    final doc = FirebaseFirestore.instance
        .collection("Announcements")
        .doc("Announcements");

    final List currentList = List.from(currentAnnouncements);
    if (index >= 0 && index < currentList.length) {
      int originalIndex = currentList.length - 1 - index;
      currentList.removeAt(originalIndex);
      await doc.update({"Announcements": currentList});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Announcements",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _announcementsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final List announcementList =
              List.from((data?['Announcements'] as List? ?? []).reversed);

          return Column(
            children: [
              Expanded(
                child: announcementList.isEmpty
                    ? const Center(child: Text("No Announcements Yet"))
                    : ListView.builder(
                        itemCount: announcementList.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: Key(announcementList[index]),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.red[800],
                              child: const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                            onDismissed: (direction) async {
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content:
                                      const Text("Delete this announcement?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _deleteAnnouncement(
                                    index, data?['Announcements'] ?? []);
                              }
                            },
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Marquee(
                                      text: announcementList[index],
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      velocity: 50.0,
                                      blankSpace: 150,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  child: GestureDetector(
                    onTap: _addAnnouncement,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 50,
                      width: double.infinity,
                      child: const Center(
                        child: Text(
                          "Add New Announcement",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
