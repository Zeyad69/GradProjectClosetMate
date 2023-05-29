import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'recommended_outfits.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class NewHomePageRecommend extends StatefulWidget {
  @override
  _NewHomePageRecommendState createState() => _NewHomePageRecommendState();
}

class _NewHomePageRecommendState extends State<NewHomePageRecommend> {
  List<File> _imageFiles = [];
  List<String?> _outfits = [];
  bool _isLoading = false;

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

  // Future<void> _recommendOutfits() async {
  //   print('_recommendOutfits method called');
  //   if (_imageFiles.length < 2) {
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text('Error'),
  //           content: Text('Please upload at least two images.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   List<String> base64Images = [];

  //   for (var imageFile in _imageFiles) {
  //     final fileName = path.basename(imageFile.path);

  //     // Upload the image to Firebase Storage
  //     final storageRef =
  //         FirebaseStorage.instance.ref().child('images/$fileName');
  //     await storageRef.putFile(imageFile);

  //     // Get the download URL of the uploaded image from Firebase Storage
  //     final downloadUrl = await storageRef.getDownloadURL();

  //     // Download the image as bytes from Firebase Storage
  //     final response = await http.get(Uri.parse(downloadUrl));
  //     final imageBytes = response.bodyBytes;

  //     // Encode the image bytes as base64 and include them in the request body
  //     final base64Image = base64Encode(imageBytes);
  //     base64Images.add(base64Image);
  //   }

  //   // Send the images to the Flask server for prediction
  //   print('Sending images to Flask server...');
  //   final responseOutfit = await http.post(
  //     Uri.parse('http://10.0.2.2:5000/recommend-outfit'),
  //     body: {'image_bytes': jsonEncode(base64Images)},
  //   );
  //   print('Received response from Flask server');

  //   if (responseOutfit.statusCode == 200) {
  //     print("data gya");
  //     final data = jsonDecode(responseOutfit.body);
  //     print('Response data: $data');
  //     final outfits = data['outfits'];
  //     final images = data['image_bytes'];
  //     print('Outfits: $outfits');
  //     print('Images: $images');
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => RecommendedOutfitsPage(
  //           imageFiles: _imageFiles,
  //           outfits: outfits,
  //         ),
  //       ),
  //     );
  //   } else {
  //     print("error y3m");
  //     print('Response body: ${responseOutfit.body}');
  //     print('Response status code: ${responseOutfit.statusCode}');
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }
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

      // Encode the image bytes as base64 and include them in the request body
      final base64Image = base64Encode(imageBytes);
      base64Images.add(base64Image);
    }

    // Send the images to the Flask server for prediction
    print('Sending images to Flask server...');
    final responseOutfit = await http.post(
      Uri.parse('http://10.0.2.2:5000/recommend-outfit'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image_bytes_list': base64Images,
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

      final outfitsList = List<String>.from(outfits.map((outfit) => outfit.toString()));

      // Update the _outfits list with the recommended outfits
      if (outfits != null && outfits is Iterable) {
        setState(() {
          _outfits = List<String?>.from(outfits);
        });
      } else {
        // Handle the case where `outfits` is null or not an iterable.
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendedOutfitsPage(
            imageFiles: _imageFiles,
            outfits: outfitsList,
          ),
        ),
      );
    } else {
      print("error y3m");
      print('Response body: ${responseOutfit.body}');
      print('Response status code: ${responseOutfit.statusCode}');
    }

    setState(() {
      _isLoading = false;
    });
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
                        Text(_outfits[index] ?? ''),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recommendOutfits,
              child: Text('Recommend Outfits'),
            ),
            if (_isLoading) ...[
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
