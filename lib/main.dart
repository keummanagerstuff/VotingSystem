import 'dart:math';

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
  runApp(VotePage());
}

enum VoteStatus { none, like, dislike, hold }

class VotePage extends StatefulWidget {
  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  Offset _offset = Offset.zero;
  bool _isDragging = false;
  VoteStatus _status = VoteStatus.none;

  final velocityThreshold = 250;
  final voteKey = 'lastVote';

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      _isDragging = true;
    });
  }

  void _onPanEnd(DragEndDetails details) async {
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final absVx = vx.abs();
    final absVy = vy.abs();
    final ratio = absVx / (absVy == 0 ? 1 : absVy);

    VoteStatus newStatus = VoteStatus.none;

    if ((absVx > velocityThreshold || absVy > velocityThreshold)) {
      if (ratio > 2) {
        newStatus = vx > 0 ? VoteStatus.like : VoteStatus.dislike;
      } else if (ratio < 0.5 && vy > 0) {
        newStatus = VoteStatus.hold;
      } else {
        print('⚠️ 대각선 방향 → 무시');
      }
    }

    if (newStatus != VoteStatus.none) {
      final newVote = newStatus.name;
      final prefs = await SharedPreferences.getInstance();
      final oldVote = prefs.getString(voteKey);

      if (oldVote == newVote) {
        print('🛑 동일한 투표 → 무시');
      } else {
        await updateVote(newVote, oldVote);
        await prefs.setString(voteKey, newVote);
        print('✅ 투표 완료: $newVote (이전: $oldVote)');
      }

      setState(() {
        _status = newStatus;
        _offset = Offset(1000 * (vx > 0 ? 1 : -1), 0); // 날아가는 효과
      });

      // 카드 날아간 후 다시 초기화
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        _offset = Offset.zero;
        _isDragging = false;
      });
    } else {
      // 복귀
      setState(() {
        _offset = Offset.zero;
        _isDragging = false;
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
        updated[oldVote] = max(0, updated[oldVote]! - 1);
      }
      updated[newVote] = (updated[newVote] ?? 0) + 1;
      transaction.set(ref, updated);
    });
  }

  String get _statusText {
    switch (_status) {
      case VoteStatus.like:
        return '👍 Like!';
      case VoteStatus.dislike:
        return '👎 Dislike!';
      case VoteStatus.hold:
        return '🤷 Hold!';
      default:
        return '카드를 스와이프 해주세요';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusText, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              transform: Matrix4.translationValues(
                _offset.dx,
                _offset.dy,
                0,
              ),
              curve: Curves.easeOut,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.65,
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '이 항목이 마음에 드시나요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
