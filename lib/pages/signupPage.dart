import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import 'package:sgsits_gym/HomePages/adminhome.dart';
import 'package:sgsits_gym/HomePages/userHome.dart'; // For Base64 encoding/decoding

class Signuppage extends StatefulWidget {
  const Signuppage({super.key, required this.isAdmin, this.isFromAdmin});
  final bool isAdmin;
  final bool? isFromAdmin;
  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final keyController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileNumberController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  String? firstNameError,
      lastNameError,
      mobileNumberError,
      emailError,
      passwordError,
      adminKeyError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    keyController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    mobileNumberController.dispose();
    super.dispose();
  }

  bool isValid(String mobileNumber) =>
      RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber);

  void validateMobileNumber(String mobileNumber) {
    if (RegExp(r'[a-zA-Z]').hasMatch(mobileNumber)) {
      mobileNumberError = "Number should not contain alphabets";
    } else if (!isValid(mobileNumber)) {
      mobileNumberError = "Mobile Number should be 10 digits";
    } else {
      mobileNumberError = null;
    }
  }

  void validateEmailId(String email) {
    if (!email.contains('@') || !email.contains('.')) {
      emailError = "Please enter a valid email address";
      return;
    }

    List<String> parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      emailError = "Please enter a valid email address";
      return;
    }

    List<String> domainParts = parts[1].split('.');
    if (domainParts.length < 2 || domainParts.last.length < 2) {
      emailError = "Please enter a valid email address";
    } else {
      emailError = null;
    }
  }

  void validatePassword(String password) {
    if (password.length <= 8) {
      passwordError = "Password should be at least 8 digits";
    } else {
      passwordError = null;
    }
  }

  void validateFirstName() {
    if (firstNameController.text.contains(RegExp(r'[0-9]'))) {
      firstNameError = "Name should not contain numbers";
    } else {
      firstNameError = null;
    }
  }

  void validateLastName() {
    if (lastNameController.text.contains(RegExp(r'[0-9]'))) {
      lastNameError = "Name should not contain numbers";
    } else {
      lastNameError = null;
    }
  }

  void validateFields() {
    setState(() {
      firstNameError =
          firstNameController.text.isEmpty ? "First Name is required" : null;
      lastNameError =
          lastNameController.text.isEmpty ? "Last Name is required" : null;
      validateMobileNumber(mobileNumberController.text);
      validateEmailId(emailController.text);
      validatePassword(passwordController.text);
      if (widget.isAdmin) {
        adminKeyError =
            keyController.text.isEmpty ? "Admin Key is required" : null;
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final sizeInBytes = await file.length();
      const maxSize = 1048576;

      if (sizeInBytes > maxSize) {
        _showErrorDialog(
            "Image size exceeds 1 MB. Please choose a smaller image.");
        return;
      }

      setState(() {
        _image = file;
      });
    }
  }

  // Function to encode image to Base64
  Future<String?> _encodeImageToBase64(File? image) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  bool _isSigningUp = false;

  Future<void> signup() async {
    setState(() {
      _isSigningUp = true;
    });

    validateFields();
    if ([
      firstNameError,
      lastNameError,
      mobileNumberError,
      emailError,
      passwordError,
      adminKeyError
    ].any((e) => e != null)) {
      setState(() {
        _isSigningUp = false;
      });
      return;
    }

    try {
      if (widget.isAdmin) {
        DocumentSnapshot adminKeyDoc = await FirebaseFirestore.instance
            .collection('AdminKey')
            .doc('Admin-key')
            .get();
        if (!adminKeyDoc.exists || keyController.text != adminKeyDoc["Key"]) {
          throw FirebaseAuthException(
              code: "invalid-admin-key",
              message: "Invalid Admin Key. Please enter the correct key.");
        }
      }
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      final String uid = userCred.user!.uid;

      String? base64Image;
      if (_image != null) {
        base64Image = await _encodeImageToBase64(_image);
      }

      await FirebaseFirestore.instance
          .collection(widget.isAdmin ? "Admins" : "Users")
          .doc(uid)
          .set({
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "mobileNumber": mobileNumberController.text.trim(),
        "email": emailController.text.trim(),
        if (!widget.isAdmin) ...{
          "imageBase64": base64Image,
          "subscribed": false,
          "planExpiry": null,
          "lastRenewal": null,
          "memberId": uid,
          "assignedMeals": null,
          "assignedWorkouts": null,
        },
      });

      if (widget.isFromAdmin != null && widget.isFromAdmin!) {
        FirebaseAuth.instance.signOut();
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => widget.isAdmin ? Adminhome() : Userhome()));
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      _showErrorDialog(e.message ?? "An unknown error occurred");
    } catch (e) {
      _showErrorDialog("An unknown error occurred");
    } finally {
      setState(() {
        _isSigningUp = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? "Admin Signup" : "User Signup",
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[100],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[800]),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[200],
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  Text("Image should be less than 1 mb",
                      style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  Text(
                    "Please fill below entries for ${widget.isAdmin ? "Admin" : "User"}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: firstNameController,
                    label: "First Name",
                    errorText: firstNameError,
                    icon: Icons.person_outline,
                    onChanged: (value) {
                      validateFirstName();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: lastNameController,
                    label: "Last Name",
                    errorText: lastNameError,
                    icon: Icons.person_outline,
                    onChanged: (value) {
                      validateLastName();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: mobileNumberController,
                    label: "Mobile Number",
                    errorText: mobileNumberError,
                    icon: Icons.phone,
                    onChanged: (value) {
                      validateMobileNumber(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    label: "Email",
                    errorText: emailError,
                    icon: Icons.email,
                    onChanged: (value) {
                      validateEmailId(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    label: "Password",
                    errorText: passwordError,
                    icon: Icons.lock,
                    obscureText: true,
                    onChanged: (value) {
                      validatePassword(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Visibility(
                    visible: widget.isAdmin,
                    child: _buildTextField(
                      controller: keyController,
                      label: "Admin Key",
                      errorText: adminKeyError,
                      icon: Icons.vpn_key,
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSigningUp
                          ? null
                          : signup, // Disable button while loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isSigningUp
                          ? SizedBox(
                              // Ensure the CircularProgressIndicator has a size
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required IconData icon,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
      ),
      obscureText: obscureText,
      onChanged: onChanged,
    );
  }
}
