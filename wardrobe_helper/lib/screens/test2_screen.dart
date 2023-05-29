import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class ClothesUpload extends StatefulWidget {
  @override
  _ClothesUploadState createState() => _ClothesUploadState();
}

class _ClothesUploadState extends State<ClothesUpload> {
  String? clothesType;
  File? file;

  Future getFile() async {
    final pickedFile = await FilePicker.platform.pickFiles();
    if (pickedFile != null) {
      setState(() {
        file = File(pickedFile.files.single.path!);
      });
    }
  }

  Future uploadCloth() async {
    if (file == null) {
      print('No File Selected');
      return;
    }
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference reference =
        storage.ref().child("clothes/${DateTime.now().millisecondsSinceEpoch}");
    UploadTask uploadTask = reference.putFile(file!);
    TaskSnapshot storageTaskSnapshot = await uploadTask;
    String url = await storageTaskSnapshot.ref.getDownloadURL();

    FirebaseFirestore.instance
        .collection('Users')
        .doc('user_id')
        .collection('clothes')
        .add({
      'type': clothesType,
      'image_url': url,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Clothes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField(
              value: clothesType,
              items: [
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
              decoration: InputDecoration(
                labelText: 'Clothes Type',
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
                  border: Border.all(color: Colors.grey),
                ),
                child: file == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.attach_file),
                          SizedBox(height: 10),
                          Text('Select File'),
                        ],
                      )
                    : Icon(Icons.check),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                uploadCloth();
              },
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
