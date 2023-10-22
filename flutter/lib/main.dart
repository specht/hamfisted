import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hamfisted/service_locator.dart';
import 'package:provider/provider.dart';

import 'data.dart';

const GREEN = Color(0xff73a946);
const RED = Color(0xff992413);
const PRIMARY = Color(0xff1d5479);

const List DECAY = [
  1000 * 60 * 60 * 24 * 21,
  1000 * 60 * 60 * 24 * 14,
  1000 * 60 * 60 * 24 * 7,
  1000 * 60 * 60 * 24 * 3
];

class ListWithDecay {
  ListWithDecay(int this.decay);
  int decay = 0;
  List<String> entries = [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupServiceLocator();
  // LicenseRegistry.addLicense(() async* {
  //   final license = await rootBundle.loadString('fonts/OFL.txt');
  //   yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  // });
  await GlobalData.instance.launchGlobalData;
  runApp(ChangeNotifierProvider<GlobalData>.value(
      value: GlobalData.instance, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      title: 'Amateurfunkprüfung',
      theme: ThemeData(
        // useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PRIMARY, //Color.fromARGB(255, 5, 70, 123),
        ),
        textTheme: GoogleFonts.alegreyaSansTextTheme(textTheme),
      ),
      home: const Overview(),
      routes: {
        '/overview': (context) => const Overview(),
        '/quiz': (context) => Quiz(),
      },
    );
  }
}

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  void clearProgress() async {
    await GlobalData.box.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String hid = '';
    try {
      if (ModalRoute.of(context) != null) {
        hid = (ModalRoute.of(context)!.settings.arguments ?? '').toString();
      }
    } catch (e) {}
    List<Widget> cards = [];

    int now = DateTime.now().millisecondsSinceEpoch;
    for (var subhid in (GlobalData.questions!['children'][hid] ?? [])) {
      // <1w, <2w, <3w, <4w, rest
      List<int> countForDuration = [0, 0, 0, 0, 0];
      for (String qid
          in (GlobalData.questions!['questions_for_hid'][subhid] ?? [])) {
        int ts = GlobalData.box.get("t/$qid") ?? 0;
        int diff = now - ts;
        int slot = 4;
        if (diff < DECAY[0]) slot = 3;
        if (diff < DECAY[1]) slot = 2;
        if (diff < DECAY[2]) slot = 1;
        if (diff < DECAY[3]) slot = 0;
        countForDuration[slot] += 1;
      }
      String label = GlobalData.questions!['headings'][subhid];
      cards.add(
        InkWell(
          child: Card(
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                        decoration: BoxDecoration(
                          color: Color.lerp(PRIMARY, Colors.white, 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Text(
                              "${(GlobalData.questions!['questions_for_hid'][subhid] ?? []).length}",
                              style: GoogleFonts.alegreyaSans(
                                  fontSize: 14, color: Colors.black87)),
                        )),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int k = 0; k <= 4; k++)
                        if (countForDuration[k] > 0)
                          Flexible(
                            flex: countForDuration[k],
                            child: LinearProgressIndicator(
                              backgroundColor: const Color(0x20000000),
                              color: Color.lerp(PRIMARY, Colors.white, k / 5),
                              value: 1.0,
                            ),
                          ),
                    ]),
              ),
            ),
          ),
          onTap: () {
            if (GlobalData.questions!['children'][subhid] != null) {
              Navigator.of(context)
                  .pushNamed('/overview', arguments: subhid)
                  .then((value) {
                setState(() {});
              });
            } else {
              Navigator.of(context)
                  .pushNamed('/quiz', arguments: subhid)
                  .then((value) {
                setState(() {});
              });
            }
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        actions: hid.isEmpty
            ? [
                PopupMenuButton(onSelected: (value) {
                  if (value == 'clear_progress') {
                    clearProgress();
                  }
                }, itemBuilder: (itemBuilder) {
                  return [
                    PopupMenuItem(
                        child: Text("Fortschritt löschen"),
                        value: "clear_progress")
                  ];
                })
              ]
            : null,
        title: Text(
            (GlobalData.questions!['headings'][hid] ?? 'Amateurfunkprüfung')),
      ),
      body: ListView(
        children: cards,
      ),
      bottomNavigationBar: Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 5)]),
          // color: Colors.white,
          child: TextButton(
            child: Text(
                "Alle ${(GlobalData.questions!['questions_for_hid'][hid] ?? []).length} Fragen üben"),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/quiz', arguments: hid)
                  .then((value) {
                setState(() {});
              });
            },
          )),
    );
  }
}

class Quiz extends StatefulWidget {
  Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> with TickerProviderStateMixin {
  String? hid;
  String? qid;
  int confidenceIndex = 0;
  List<Color> answerColor = [];
  List<int> answerIndex = [];
  bool guessedWrong = false;
  bool foundCorrect = false;
  int animationPhase = 0;
  bool solvedAll = false;
  Timer? _timer;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationController2 = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationController3 = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController2.dispose();
    _animationController3.dispose();
    super.dispose();
  }

  void pickTask() {
    guessedWrong = false;
    foundCorrect = false;
    confidenceIndex = 0;
    // get all questions for this heading
    List<String> candidates = [];
    for (String x in GlobalData.questions!['questions_for_hid'][hid]) {
      candidates.add(x);
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    List<ListWithDecay> candidatesSorted = [
      ListWithDecay(0),
      ListWithDecay(1),
      ListWithDecay(2),
      ListWithDecay(3),
      ListWithDecay(4)
    ];
    for (String qid in candidates) {
      int ts = GlobalData.box.get("t/$qid") ?? 0;
      int diff = now - ts;
      int slot = 4;
      if (diff < DECAY[0]) slot = 3;
      if (diff < DECAY[1]) slot = 2;
      if (diff < DECAY[2]) slot = 1;
      if (diff < DECAY[3]) slot = 0;
      candidatesSorted[slot].entries.add(qid);
    }
    candidatesSorted.removeWhere((element) => element.entries.isEmpty);
    if (candidatesSorted.last.decay == 0) {
      solvedAll = true;
      // Navigator.of(context).pop();
    }
    candidates = candidatesSorted.last.entries;
    candidates.shuffle();
    setState(() {
      qid = candidates[0];
      answerColor = [
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent
      ];
      answerIndex = [0, 1, 2, 3];
      answerIndex.shuffle();
    });
  }

  void launchAnimation() {
    _animationController.reset();
    _animationController2.reset();
    _animationController3.reset();
    animationPhase = 1;
    _animationController
        .animateTo(1.0, curve: Curves.easeInOutQuint)
        .then((value) {
      animationPhase = 2;
      _animationController2
          .animateTo(1.0, curve: Curves.easeInOutQuint)
          .then((value) {
        animationPhase = 3;
        setState(() {
          pickTask();
        });
        _animationController3
            .animateTo(1.0, curve: Curves.easeInOutQuint)
            .then((value) {
          setState(() {
            animationPhase = 0;
            _animationController.reset();
            _animationController2.reset();
            _animationController3.reset();
          });
        });
      });
    });
  }

  void tapAnswer(int i) {
    if (i == 0) {
      // answer is correct
      foundCorrect = true;
      answerColor[i] = GREEN;
      if (!guessedWrong) {
        if (confidenceIndex == 0) {
          GlobalData.instance
              .markQuestionSolved(qid!, DateTime.now().millisecondsSinceEpoch);
        }
      }
      if (confidenceIndex == 0) {
        launchAnimation();
      }
    } else {
      // answer is wrong
      answerColor[i] = RED;
      guessedWrong = true;
      confidenceIndex = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hid == null) {
      // get current heading
      if (ModalRoute.of(context) != null) {
        hid = (ModalRoute.of(context)!.settings.arguments ?? '').toString();
      }
    }
    if (qid == null) {
      pickTask();
    }
    List<Widget> cards = [];
    String qidDisplay = qid ?? '';
    if (qidDisplay.endsWith('E') || qidDisplay.endsWith('A')) {
      qidDisplay = qidDisplay.substring(0, qidDisplay.length - 1);
    }

    cards.add(Card(
      child: ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Html(
            data:
                "<b>$qidDisplay</b>&nbsp;&nbsp;&nbsp;&nbsp;${GlobalData.questions!['questions'][qid]['challenge']}",
            style: {'body': Style(margin: Margins.zero)},
          ),
        ),
      ),
    ));
    cards.add(const Divider());

    for (int _i = 0; _i < 4; _i++) {
      int i = answerIndex[_i];
      cards.add(
        AnimatedBuilder(
            animation: _animationController3,
            builder: (context, child) {
              return AnimatedBuilder(
                  animation: _animationController2,
                  builder: (context, child) {
                    return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return LayoutBuilder(builder: (context, constraints) {
                            Offset offset = Offset.zero;
                            if (animationPhase == 1) {
                              if (i != 0) {
                                offset =
                                    Offset(-1 * _animationController.value, 0);
                              }
                            } else if (animationPhase == 2) {
                              if (i != 0) {
                                offset = Offset(-1, 0);
                              } else {
                                offset =
                                    Offset(-1 * _animationController2.value, 0);
                              }
                            } else if (animationPhase == 3) {
                              offset =
                                  Offset(1.0 - _animationController3.value, 0);
                            }
                            return Transform.translate(
                              offset: offset * constraints.maxWidth,
                              child: Card(
                                child: InkWell(
                                  onTapCancel: () => _timer?.cancel(),
                                  onTapDown: (_) => {
                                    _timer =
                                        Timer(Duration(milliseconds: 1500), () {
                                      setState(() {
                                        confidenceIndex = 1;
                                        tapAnswer(i);
                                      });
                                    })
                                  },
                                  onTap: () {
                                    _timer?.cancel();
                                    setState(() {
                                      tapAnswer(i);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: answerColor[i],
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: ListTile(
                                        horizontalTitleGap: 0,
                                        titleAlignment:
                                            ListTileTitleAlignment.top,
                                        leading: Transform.translate(
                                          offset: const Offset(0, 8),
                                          child: CircleAvatar(
                                            backgroundColor: answerColor[i] ==
                                                    Colors.transparent
                                                ? Color.lerp(
                                                    PRIMARY, Colors.white, 0.8)
                                                : answerColor[i],
                                            radius: 15,
                                            child: Text(
                                              String.fromCharCode(65 + _i),
                                              style: GoogleFonts.alegreyaSans(
                                                  fontSize: 14,
                                                  color: answerColor[i] ==
                                                          Colors.transparent
                                                      ? Colors.black87
                                                      : Colors.white,
                                                  fontWeight: answerColor[i] ==
                                                          Colors.transparent
                                                      ? FontWeight.normal
                                                      : FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        title: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Html(
                                            data: GlobalData
                                                .questions!['questions'][qid]
                                                    ['answers'][i]
                                                .toString()
                                                .replaceAll('*', ' ⋅ '),
                                            style: {
                                              'body':
                                                  Style(margin: Margins.zero)
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                        });
                  });
            }),
      );
    }

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: Text(
            (GlobalData.questions!['headings'][hid] ?? 'Amateurfunkprüfung')),
      ),
      floatingActionButton: solvedAll
          ? FloatingActionButton.extended(
              backgroundColor: PRIMARY,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text("Alle Fragen beantwortet!"))
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 5)]),
        child: BottomNavigationBar(
          currentIndex: confidenceIndex,
          selectedItemColor: Colors.black,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          onTap: (value) {
            setState(() {
              if (confidenceIndex == 1 && value == 1 && foundCorrect) {
                launchAnimation();
              } else {
                if (!guessedWrong) {
                  confidenceIndex = value;
                }
              }
            });
          },
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              activeIcon: Text(
                "😀",
                style: TextStyle(fontSize: 24),
              ),
              icon: Opacity(
                opacity: 0.5,
                child: Text(
                  "😀",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: 'Ich bin mir sicher',
            ),
            BottomNavigationBarItem(
              activeIcon: Text(
                (confidenceIndex == 1 && foundCorrect) ? "👍" : "🤔",
                style: TextStyle(fontSize: 24),
              ),
              icon: const Opacity(
                opacity: 0.5,
                child: Text(
                  "🤔",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: (confidenceIndex == 1 && foundCorrect)
                  ? 'Ok, weiter'
                  : 'Ich bin mir unsicher',
            ),
          ],
        ),
      ),
      body: ListView(
        children: cards,
      ),
    );
  }
}
