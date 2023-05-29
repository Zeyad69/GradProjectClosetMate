import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  List<File> _imageFiles = [];
  List<String> _outfits = [];

  Future<void> _uploadImages() async {
    final picker = ImagePicker();
    final pickedFiles =
        await picker.pickMultiImage(imageQuality: 50, maxWidth: 500);

    if (pickedFiles != null) {
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _imageFiles.add(imageFile);
        });

        final fileName = path.basename(pickedFile.path);
        final storageRef =
            FirebaseStorage.instance.ref().child('images/$fileName');
        await storageRef.putFile(imageFile);

        final downloadUrl = await storageRef.getDownloadURL();

        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/recommend-outfits'),
          body: {'image_url': downloadUrl},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _outfits.add(data['outfit']);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fashion MNIST App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imageFiles.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Image.file(
                          _imageFiles[index],
                          height: 100,
                          width: 100,
                        ),
                        SizedBox(width: 10),
                        Text(_outfits.isNotEmpty ? _outfits[index] : ''),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _uploadImages,
              child: Text('Upload Images'),
            ),
          ],
        ),
      ),
    );
  }
}
