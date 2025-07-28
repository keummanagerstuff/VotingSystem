import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web, // 웹 전용이니까 이렇게!
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
    );
  }
}

enum VoteStatus { none, like, dislike, hold }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Offset _offset = Offset.zero;
  VoteStatus _status = VoteStatus.none;

  final velocityThreshold = 250;
  final voteKey = 'lastVote';

  void _handleUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _handleEnd(DragEndDetails details) async {
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final absVx = vx.abs();
    final absVy = vy.abs();

    VoteStatus newStatus = VoteStatus.none;

    if (absVx > velocityThreshold || absVy > velocityThreshold) {
      final ratio = absVx / absVy;

      if (ratio > 2) {
        newStatus = vx > 0 ? VoteStatus.like : VoteStatus.dislike;
      } else if (ratio < 0.5 && vy > 0) {
        newStatus = VoteStatus.hold;
      } else {
        print('⚠️ 대각선 스와이프 → 무시');
        return;
      }

      final newVote = newStatus.name;
      final prefs = await SharedPreferences.getInstance();
      final oldVote = prefs.getString(voteKey);

      if (oldVote == newVote) {
        print('🛑 동일 투표 무시');
      } else {
        await updateVote(newVote, oldVote);
        await prefs.setString(voteKey, newVote);
        print('✅ 투표 완료: $newVote (이전: $oldVote)');
      }

      setState(() {
        _offset = Offset.zero;
        _status = newStatus;
      });
    }
  }

  Future<void> updateVote(String newVote, String? oldVote) async {
    final ref = FirebaseFirestore.instance.collection('vote').doc('result');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? {};

      final updated = {
        'like': (data['like'] ?? 0) as int,
        'dislike': (data['dislike'] ?? 0) as int,
        'hold': (data['hold'] ?? 0) as int,
      };

      if (oldVote != null && updated.containsKey(oldVote)) {
        updated[oldVote] = updated[oldVote]! - 1;
      }

      updated[newVote] = (updated[newVote] ?? 0) + 1;

      transaction.set(ref, updated);
    });
  }

  String _statusText() {
    switch (_status) {
      case VoteStatus.like:
        return '👍 Like!';
      case VoteStatus.dislike:
        return '👎 Dislike!';
      case VoteStatus.hold:
        return '🤷 Hold!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _status != VoteStatus.none;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    _statusText(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              GestureDetector(
                onPanUpdate: _handleUpdate,
                onPanEnd: _handleEnd,
                child: Transform.translate(
                  offset: _offset,
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.75,
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '마음에 드시나요?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    '카드를 스와이프하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
