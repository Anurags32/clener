import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StrickesScreen extends StatefulWidget {
  const StrickesScreen({super.key});

  @override
  State<StrickesScreen> createState() => _StrickesScreenState();
}

class _StrickesScreenState extends State<StrickesScreen> {
  int streakCount = 0;
  int longestStreak = 0;

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _fetchStreakData();
  }

  Future<void> _fetchStreakData() async {
    if (_auth.currentUser != null) {
      String userID = _auth.currentUser!.uid;
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('users').doc(userID).get();
      if (documentSnapshot.exists) {
        setState(() {
          streakCount = documentSnapshot['streakCount'] ?? 0;
          longestStreak = documentSnapshot['longestStreak'] ?? 0;
        });
      }
    }
  }

  Future<void> _updateStreak(bool hasRecordedRoutine) async {
    if (_auth.currentUser != null) {
      String userID = _auth.currentUser!.uid;
      DocumentReference userDocRef = _firestore.collection('users').doc(userID);

      if (hasRecordedRoutine) {
        setState(() {
          streakCount++;
          if (streakCount > longestStreak) {
            longestStreak = streakCount;
          }
        });
      } else {
        setState(() {
          streakCount = 0;
        });
      }

      await userDocRef.set({
        'streakCount': streakCount,
        'longestStreak': longestStreak,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Streaks',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Goal: ${longestStreak} streak days',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.18,
              width: MediaQuery.of(context).size.width * 2,
              decoration: const BoxDecoration(
                color: Color.fromARGB(68, 199, 165, 165),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Streak Days',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      streakCount.toString(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Daily Streak',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Text(
              '2',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    show: false,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 0),
                        FlSpot(1, 2),
                        FlSpot(2, 1),
                        FlSpot(3, 5),
                        FlSpot(4, 3),
                        FlSpot(5, 7),
                        FlSpot(6, 4),
                      ],
                      isCurved: true,
                      color: Color.fromARGB(68, 199, 165, 165),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color.fromARGB(68, 199, 165, 165),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Keep it up! Youre on a roll.',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
            const Spacer(),
            ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(350, 45),
                  backgroundColor: const Color.fromARGB(68, 199, 165, 165),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ))
          ],
        ),
      ),
    );
  }
}
