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

  // 스와이프 우선 방향 결정
  if (vx.abs() > vy.abs()) {
    // 좌우 스와이프 우선
    if (vx > 300) {
      _status = VoteStatus.like;
    } else if (vx < -300) {
      _status = VoteStatus.dislike;
    }
  } else {
    // 위아래 스와이프 우선
    if (vy > 300) {
      _status = VoteStatus.hold;
    }
  }

  setState(() {
    _offset = Offset.zero;
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        '마음에 드시나요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
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
