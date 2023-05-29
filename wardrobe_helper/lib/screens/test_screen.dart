import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClothUploader extends StatefulWidget {
  const ClothUploader({super.key});
  @override
  _ClothUploaderState createState() => _ClothUploaderState();
}

class _ClothUploaderState extends State<ClothUploader> {
  File? _image;
  String? _selectedClothType;
  final _picker = ImagePicker();
  List<String> _items = [];

  void _addItem(String imagePath) {
    setState(() {
      _items.add(imagePath);
    });
  }

  Future getImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  List<String> _clothTypes = ['T-shirt', 'Top', 'Skirt', 'Trousers', 'Shirt'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cloth Uploader'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: getImage,
              child: Text('Choose Image'),
            ),
            SizedBox(height: 10.0),
            DropdownButtonFormField(
              value: _selectedClothType,
              hint: Text('Select Cloth Type'),
              onChanged: (value) {
                setState(() {
                  _selectedClothType = value;
                });
              },
              items: _clothTypes.map((clothType) {
                return DropdownMenuItem(
                  value: clothType,
                  child: Text('$clothType'),
                );
              }).toList(),
            ),
            SizedBox(height: 10.0),
            _image == null
                ? Text('Please choose an image.')
                : Image.file(_image!),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _selectedClothType == null || _image == null
                  ? null
                  : () async {
                      FirebaseStorage firebaseStorage =
                          FirebaseStorage.instance;
                      Reference reference = firebaseStorage
                          .ref()
                          .child('cloths')
                          .child('${DateTime.now().toString()}.jpg');
                      await reference.putFile(_image!);
                      String imageUrl = await reference.getDownloadURL();
                      FirebaseFirestore firestore = FirebaseFirestore.instance;
                      firestore.collection('users').doc('<USER_ID>').update({
                        'cloths': FieldValue.arrayUnion([
                          {'type': _selectedClothType, 'imageUrl': imageUrl}
                        ])
                      });
                      Navigator.pop(context);
                    },
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
