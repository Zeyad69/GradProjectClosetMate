import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:async';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wardrobe_helper/recommendation_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:wardrobe_helper/screens/test_recommened3.dart';

class HomePage extends StatefulWidget {
  String text = " ";
  //int currentIndex = 0;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  int _currentIndex = 0;
  final List<Widget> _children = [
    NewHomePageRecommended(),
    UploadPhotoScreen(),
    OutfitRecommendationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[800],
        title: Text('My Wardrobe'),
      ),
      body: _children[_currentIndex],
      backgroundColor: Colors.orange.shade400,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.orange.shade400,
        color: Colors.orange.shade800,
        onTap: onTabTapped,
        //index = _currentIndex,
        items: [
          Icon(Icons.home),
          Icon(Icons.photo_camera),
          Icon(Icons.shopping_bag_outlined),
          Icon(Icons.settings),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class WardrobeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Wardrobe Screen'),
    );
  }
}

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({super.key});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  String? clothesType;
  File? file;

  Future getFile() async {
    final pickedFile = await FilePicker.platform.pickFiles();
    if (pickedFile != null) {
      setState(() async {
        file = File(pickedFile.files.single.path!);
      });
    }
  }

  Future uploadCloth() async {
    if (file == null) {
      print('No File Selected');
      return;
    }

    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference reference = storage
          .ref()
          .child("clothes/${DateTime.now().millisecondsSinceEpoch.toString()}");

      // Check if reference already exists
      bool exists = false;
      try {
        await reference.getMetadata();
        exists = true;
      } catch (e) {
        print("File doesn't exist yet!");
      }

      if (!exists) {
        UploadTask uploadTask = reference.putFile(file!);
        TaskSnapshot storageTaskSnapshot = await uploadTask;
        String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        print("File already exists!");
        // handle error or return existing url
        return null;
      }
    } catch (error) {
      print("Error uploading file: $error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      //  child: Text('Upload Photo Screen'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField(
              dropdownColor: Colors.orange[800],
              value: clothesType,
              items: const [
                DropdownMenuItem(child: Text('T-Shirt'), value: 'T-Shirt'),
                DropdownMenuItem(child: Text('Top'), value: 'Top'),
                DropdownMenuItem(child: Text('Skirt'), value: 'Skirt'),
                DropdownMenuItem(child: Text('Trousers'), value: 'Trousers'),
                DropdownMenuItem(child: Text('Shirt'), value: 'Shirt'),
              ],
              onChanged: (value) {
                setState(() {
                  clothesType = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Clothes Type',
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                getFile();
              },
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: file == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          Icon(Icons.attach_file),
                          SizedBox(height: 10),
                          Text(
                            'Select File',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Icon(Icons.check),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                uploadCloth();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
              ),
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class OutfitRecommendationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Outfit Recommendation Screen'),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MaterialButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            color: Colors.white,
            child: Text('Sign Out'),
          )
        ],
      ),
    ));
  }
}
