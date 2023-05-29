import 'dart:io';
import 'package:flutter/material.dart';

class RecommendedOutfitsPage extends StatelessWidget {
  final List<File> imageFiles;
  final List<String> outfits;

  RecommendedOutfitsPage({
    required this.imageFiles,
    required this.outfits,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommended Outfits'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: imageFiles.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Image.file(
                        imageFiles[index],
                        height: 200,
                        width: 200,
                      ),
                      SizedBox(height: 10),
                      Text(outfits[index]),
                      SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}