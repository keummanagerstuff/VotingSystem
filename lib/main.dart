import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: MyHomePage(),
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
  VoteStatus _status = VoteStatus.none;

  final voteKey = 'lastVote';

  Future<void> updateVote(VoteStatus newVote) async {
    final prefs = await SharedPreferences.getInstance();
    final oldVoteStr = prefs.getString('lastVote');
    final oldVote = _stringToVoteStatus(oldVoteStr);

    final isCancelling = oldVote == newVote;

    if (newVote != VoteStatus.none || oldVote != VoteStatus.none) {
      final ref = FirebaseFirestore.instance.collection('vote').doc('result');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};

        final updated = {
          'like': (data['like'] ?? 0) as int,
          'dislike': (data['dislike'] ?? 0) as int,
          'hold': (data['hold'] ?? 0) as int,
        };

        if (oldVote != VoteStatus.none) {
          updated[oldVote.name] = (updated[oldVote.name] ?? 0) - 1;
        }

        if (!isCancelling && newVote != VoteStatus.none) {
          updated[newVote.name] = (updated[newVote.name] ?? 0) + 1;
        }

        transaction.set(ref, updated);
      });
    }

    if (isCancelling) {
      await prefs.remove('lastVote');
    } else {
      await prefs.setString('lastVote', newVote.name);
    }

    setState(() {
      _status = isCancelling ? VoteStatus.none : newVote;
    });
  }

  VoteStatus _stringToVoteStatus(String? value) {
    switch (value) {
      case 'like':
        return VoteStatus.like;
      case 'dislike':
        return VoteStatus.dislike;
      case 'hold':
        return VoteStatus.hold;
      default:
        return VoteStatus.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final voteOptions = [
      {
        'image': 'assets/images/1f44d.png',
        'text': 'Yes!',
        'key': VoteStatus.like
      },
      {
        'image': 'assets/images/1f914.png',
        'text': 'Hmmm..',
        'key': VoteStatus.hold
      },
      {
        'image': 'assets/images/1f44e.png',
        'text': 'Nope',
        'key': VoteStatus.dislike
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: voteOptions.map((vote) {
              final VoteStatus voteKey = vote['key'] as VoteStatus;
              final bool isSelected = _status == voteKey;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => updateVote(voteKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: screenWidth - 120,
                    height: (screenHeight - 120) / 3,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vote['text'].toString(),
                          style: GoogleFonts.notoSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Image.asset(vote['image'].toString())
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
