import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'recommended_outfits.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class NewHomePageRecommended extends StatefulWidget {
  @override
  _NewHomePageRecommendedState createState() => _NewHomePageRecommendedState();
}

class _NewHomePageRecommendedState extends State<NewHomePageRecommended> {
  List<File> _imageFiles = [];
  List<String?> _outfits = [];
  bool _isLoading = false;
  String? _selectedOutfitType;

  Future<void> _uploadImages() async {
    final picker = ImagePicker();
    final pickedFiles =
        await picker.pickMultiImage(imageQuality: 50, maxWidth: 500);

    if (pickedFiles != null) {
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _imageFiles.add(imageFile);
          _outfits.add(null);
        });

        final fileName = path.basename(pickedFile.path);

        // Upload the image to Firebase Storage
        final storageRef =
            FirebaseStorage.instance.ref().child('images/$fileName');
  await storageRef.putFile(imageFile);

        // Get the download URL of the uploaded image from Firebase Storage
        final downloadUrl = await storageRef.getDownloadURL();

        // Download the image as bytes from Firebase Storage
        final response = await http.get(Uri.parse(downloadUrl));
        final imageBytes = response.bodyBytes;

        // Encode the image bytes as base64 and include them in the request body
        final base64Image = base64Encode(imageBytes);
        print(base64Image);
      }
    }
  }

  Future<void> _recommendOutfits() async {
    print('_recommendOutfits method called');
    if (_imageFiles.length < 2) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please upload at least two images.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_selectedOutfitType == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please select an outfit type.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> base64Images = [];

    for (var imageFile in _imageFiles) {
      final fileName = path.basename(imageFile.path);

      // Upload the image to Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      await storageRef.putFile(imageFile);

      // Get the download URL of the uploaded image from Firebase Storage
      final downloadUrl = await storageRef.getDownloadURL();

      // Download the image as bytes from Firebase Storage
      final response = await http.get(Uri.parse(downloadUrl));
      final imageBytes = response.bodyBytes;

      // Encode the image bytes as base64 and include them inthe request body
      final base64Image = base64Encode(imageBytes);
      base64Images.add(base64Image);
    }

    // Send the images and outfit type to the Flask server for prediction
    print('Sending images and outfit type to Flask server...');
    final responseOutfit = await http.post(
      Uri.parse('http://10.0.2.2:5000/recommend-outfit'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image_bytes_list': base64Images,
        'outfit_type': _selectedOutfitType,
      }),
    );
    print('Received response from Flask server');

    if (responseOutfit.statusCode == 200) {
      print("data gya");
      final data = jsonDecode(responseOutfit.body);
      print('Response data: $data');
      final outfits = data['outfits'];
      final images = data['image_bytes'];
      print('Outfits: $outfits');
      print('Images: $images');

      final outfitsList =
          List<String>.from(outfits.map((outfit) => outfit.toString()));

      // Update the _outfits list with the recommended outfits
      if (outfits != null && outfits is Iterable) {
        setState(() {
          _outfits = List<String?>.from(outfits);
        });
      } else {
        // Handle the case where `outfits` is null or not anIterable
        setState(() {
          _outfits = List<String?>.filled(_imageFiles.length, null);
        });
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content:
                  Text('Failed to recommend outfits. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        _outfits = List<String?>.filled(_imageFiles.length, null);
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Failed to connect to the server. Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _chooseOutfitType(String outfitType) async {
    print('Selected outfit type: $outfitType');

    setState(() {
      _selectedOutfitType = outfitType;
      _outfits = List<String?>.filled(_imageFiles.length, null);
    });

    if (_imageFiles.isNotEmpty && _selectedOutfitType != null) {
      await _recommendOutfits();

      final outfitRecommendations = {
        'Casual': ['Jeans', 'Shirt'],
        'Formal Shirt': ['Suit', 'Dress Shoes', 'Tie'],
        'Sporty Shorts': ['Athletic Top', 'Running Shoes', 'Sweatband']
      };

      final random = Random();

      for (int i = 0; i < _imageFiles.length; i++) {
        final outfit = outfitRecommendations[_selectedOutfitType]?[
            random.nextInt(outfitRecommendations[_selectedOutfitType]!.length)];
        _outfits[i] = outfit;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outfit Recommender'),
        backgroundColor: Colors.orange.shade400,
      ),
      backgroundColor: Colors.orange.shade400,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _imageFiles.length,
                    itemBuilder: (ctx, i) => Stack(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.orange,
                            ),
                          ),
                          child: _imageFiles[i] != null
                              ? Image.file(
                                  _imageFiles[i],
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.camera_alt),
                        ),
                        if (_outfits[i] != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              color: Colors.black54,
                              child: Text(
                                _outfits[i]!,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _uploadImages,
                    style: ElevatedButton.styleFrom(
                        primary: Colors.orange.shade400),
                    child: Text('Upload Images'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final outfitType = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OutfitTypeScreen()),
                      );
                      if (outfitType != null) {
                        await _chooseOutfitType(outfitType);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        primary: Colors.orange.shade400),
                    child: Text('Choose Outfit Type'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _recommendOutfits,
                    style: ElevatedButton.styleFrom(
                        primary: Colors.orange.shade400),
                    child: Text('Recommend Outfits'),
                  ),
                ),
              ],
            ),
    );
  }
}

class OutfitTypeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Outfit Type'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'casual'),
              child: Text('Casual'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'formal'),
              child: Text('Formal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'sporty'),
              child: Text('Sporty'),
            ),
          ],
        ),
      ),
    );
  }
}
