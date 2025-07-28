import 'package:flutter/material.dart';

void main() {
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

  void _handleUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _handleEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    print('➡️ vx: $vx, ⬇️ vy: $vy');

    final absVx = vx.abs();
    final absVy = vy.abs();

    VoteStatus newStatus = VoteStatus.none;

    // 최소 속도 임계값 (기준선)
    const velocityThreshold = 250;

    if (absVx > velocityThreshold || absVy > velocityThreshold) {
      if (absVx > absVy * 1.5) {
        // 수평 스와이프 우선
        if (vx > 0) {
          newStatus = VoteStatus.like;
        } else {
          newStatus = VoteStatus.dislike;
        }
      } else if (absVy > absVx * 1.5) {
        // 수직 스와이프 우선
        if (vy > 0) {
          newStatus = VoteStatus.hold;
        }
      } else {
        // 비율 애매 → 아무것도 선택하지 않음
        print('⚠️ ambiguous swipe angle');
      }
    }

    setState(() {
      _offset = Offset.zero;
      _status = newStatus;
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
