import 'package:firebase_project/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

class ImageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Storage')),
      body: ImageGridView(),
    );
  }
}

class ImageGridView extends StatefulWidget {
  @override
  _ImageGridViewState createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> imageURLs = [];
  List<String> videoURLs = [];
  int imageCount = 0;
  int videoCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            pickImageOrVideo(context);
          },
          child: Text('Pick Images/Videos'),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Images: $imageCount'),
            SizedBox(width: 20),
            Text('Videos: $videoCount'),
          ],
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: imageURLs.length + videoURLs.length,
            itemBuilder: (context, index) {
              Widget gridTile;
              if (index < imageURLs.length) {
                gridTile = Image.network(imageURLs[index]);
              } else {
                final videoIndex = index - imageURLs.length;
                gridTile = VideoPlayerWidget(videoURL: videoURLs[videoIndex]);
              }
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: gridTile,
              );
            },
          ),
        ),
      ],
    );
  }


  Future<void> uploadVideoToFirebase(BuildContext context, File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('videos/$fileName');
      await ref.putFile(file);
      String downloadURL = await ref.getDownloadURL();
      setState(() {
        videoURLs.add(downloadURL);
        videoCount++;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> uploadImageToFirebase(BuildContext context, File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('images/$fileName');
      await ref.putFile(file);
      String downloadURL = await ref.getDownloadURL();
      setState(() {
        imageURLs.add(downloadURL);
        imageCount++;
      });
    } catch (e) {
      print(e.toString());
    }
  }
  Future<void> pickImageOrVideo(BuildContext context) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 50,
                  );
                  if (pickedFile != null) {
                    File file = File(pickedFile.path);
                    await uploadImageToFirebase(context, file);
                  } else {
                    final pickedVideo = await picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    if (pickedVideo != null) {
                      File file = File(pickedVideo.path);
                      await uploadVideoToFirebase(context,file);
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Take a video'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickVideo(source: ImageSource.camera);
                  if (pickedFile != null) {
                    File file = File(pickedFile.path);
                    if (file.existsSync()) {
                      await uploadVideoToFirebase(context, file);
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a picture'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    File file = File(pickedFile.path);
                    if (file.existsSync()) {
                      await uploadImageToFirebase(context,file);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}