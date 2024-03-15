import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkincareScreen extends StatefulWidget {
  @override
  _SkincareScreenState createState() => _SkincareScreenState();
}

class _SkincareScreenState extends State<SkincareScreen> {
  bool cleanserSelected = false;
  bool tonerSelected = false;
  bool moisturizerSelected = false;
  bool sunscreenSelected = false;
  bool lipBalmSelected = false;
  int streakCount = 0;
  int longestStreak = 0;

  Map<String, DateTime?> uploadTimes = {
    'Cleanser': null,
    'Toner': null,
    'Moisturizer': null,
    'Sunscreen': null,
    'Lip Balm': null,
  };

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;

  // @override
  // void initState() {
  //   super.initState();
  //   _fetchStreakData();
  // }

  // Future<void> _fetchStreakData() async {
  //   if (_auth.currentUser != null) {
  //     String userID = _auth.currentUser!.uid;
  //     DocumentSnapshot documentSnapshot =
  //         await _firestore.collection('users').doc(userID).get();
  //     if (documentSnapshot.exists) {
  //       setState(() {
  //         streakCount = documentSnapshot['streakCount'] ?? 0;
  //         longestStreak = documentSnapshot['longestStreak'] ?? 0;
  //       });
  //     }
  //   }
  // }

  // Future<void> _updateStreak(bool hasRecordedRoutine) async {
  //   if (_auth.currentUser != null) {
  //     String userID = _auth.currentUser!.uid;
  //     DocumentReference userDocRef = _firestore.collection('users').doc(userID);

  //     if (hasRecordedRoutine) {
  //       setState(() {
  //         streakCount++;
  //         if (streakCount > longestStreak) {
  //           longestStreak = streakCount;
  //         }
  //       });
  //     } else {
  //       setState(() {
  //         streakCount = 0;
  //       });
  //     }

  //     await userDocRef.set({
  //       'streakCount': streakCount,
  //       'longestStreak': longestStreak,
  //     }, SetOptions(merge: true));
  //   }
  // }
  DateTime? uploadTime;
  Future<void> uploadImageAndStoreURL(String stepName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print('Error: No image picked.');
      return;
    }

    if (_auth.currentUser == null) {
      print('Error: User not authenticated.');
      return;
    }

    String userID = _auth.currentUser!.uid;
    String imageName = 'skincare_${DateTime.now().millisecondsSinceEpoch}.png';
    Reference storageReference =
        _storage.ref().child('skincare_images').child(userID).child(imageName);

    try {
      await storageReference.putFile(File(pickedFile.path));

      String downloadURL = await storageReference.getDownloadURL();

      await _firestore.collection('skincare_images').doc(userID).set({
        'image_url': downloadURL,
        'timestamp': DateTime.now(),
      });

      setState(() {
        uploadTimes[stepName] = DateTime.now();
        cleanserSelected = true;
        tonerSelected = true;
        moisturizerSelected = true;
        sunscreenSelected = true;
        lipBalmSelected = true;
      });

      // await _updateStreak(true);

      print('Image uploaded and URL stored successfully.');
    } catch (error) {
      print('Error uploading image: $error');

      await Future.delayed(Duration(seconds: 5));
      await uploadImageAndStoreURL(stepName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Daily Skincare',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildSkincareStep(
                'Cleanser', 'Cetaphil Gentle Skin Cleanser', cleanserSelected),
            buildSkincareStep(
                'Toner', 'Thayers Witch Hazel Toner', tonerSelected),
            buildSkincareStep(
                'Moisturizer', 'Kiehl Ultra Facial Cream', moisturizerSelected),
            buildSkincareStep('Sunscreen', 'Supergoop Unseen Sunscreen SPF 40',
                sunscreenSelected),
            buildSkincareStep(
                'Lip Balm', 'Glossier Birthday Balm Dotcom', lipBalmSelected),
          ],
        ),
      ),
    );
  }

  Widget buildSkincareStep(String stepName, String product, bool isSelected) {
    DateTime? uploadTime = uploadTimes[stepName];
    return GestureDetector(
      onTap: () {
        setState(() {
          switch (stepName) {
            case 'Cleanser':
              cleanserSelected = !cleanserSelected;
              break;
            case 'Toner':
              tonerSelected = !tonerSelected;
              break;
            case 'Moisturizer':
              moisturizerSelected = !moisturizerSelected;
              break;
            case 'Sunscreen':
              sunscreenSelected = !sunscreenSelected;
              break;
            case 'Lip Balm':
              lipBalmSelected = !lipBalmSelected;
              break;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Checkbox(
              activeColor: const Color.fromARGB(155, 247, 205, 205),
              checkColor: Colors.black54,
              value: isSelected,
              onChanged: (newValue) {
                setState(() {
                  switch (stepName) {
                    case 'Cleanser':
                      cleanserSelected = newValue ?? false;
                      break;
                    case 'Toner':
                      tonerSelected = newValue ?? false;
                      break;
                    case 'Moisturizer':
                      moisturizerSelected = newValue ?? false;
                      break;
                    case 'Sunscreen':
                      sunscreenSelected = newValue ?? false;
                      break;
                    case 'Lip Balm':
                      lipBalmSelected = newValue ?? true;
                      break;
                  }
                  _storeSkincareRoutine();
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product,
                    style: const TextStyle(
                        fontSize: 12, color: Color.fromARGB(255, 136, 49, 64)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                uploadImageAndStoreURL(stepName);
              },
              child:
                  Image.asset("assets/8d57dad007688ab9d40ab672ea9eaeac 1.png"),
            ),
            if (uploadTime != null) ...[
              const SizedBox(width: 8),
              Text(
                '${uploadTime.hour.toString().padLeft(2, '0')}:${uploadTime.minute.toString().padLeft(2, '0')}', // Displaying only the time
                style: const TextStyle(
                    fontSize: 12, color: Color.fromARGB(255, 136, 49, 64)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _storeSkincareRoutine() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('cleanserSelected', cleanserSelected);
    prefs.setBool('tonerSelected', tonerSelected);
    prefs.setBool('moisturizerSelected', moisturizerSelected);
    prefs.setBool('sunscreenSelected', sunscreenSelected);
    prefs.setBool('lipBalmSelected', lipBalmSelected);
  }
}
