import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  ListWithDecay(this.decay);
  int decay = 0;
  List<String> entries = [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      debugShowCheckedModeBanner: false,
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
        '/about': (context) => About(),
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
  Future<void> clearProgress() async {
    await GlobalData.box.clear();
    setState(() {});
  }

  List<Widget> getChapterCards({String hid = '', bool demo = false}) {
    List<Widget> cards = [];
    int now = DateTime.now().millisecondsSinceEpoch;
    for (var subhid in (GlobalData.questions!['children'][hid] ?? [])) {
      // <1w, <2w, <3w, <4w, rest
      List<int> countForDuration = [0, 0, 0, 0, 0];
      if (demo) {
        countForDuration = [10, 13, 9, 2, 28];
        countForDuration.shuffle();
      } else {
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
            if (demo) return;
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
    return cards;
  }

  Widget introScreen() {
    List<Widget> cards = [];
    List<int> answerIndex = [1, 3, 0, 2];
    List<Color> answerColor = [
      Colors.transparent,
      Colors.transparent,
      Colors.transparent,
      Colors.transparent
    ];
    List<String> answers = [
      '42*10<sup>-3</sup> A.',
      '42*10<sup>3</sup> A.',
      '42*10<sup>-2</sup> A.',
      '42*10<sup>-1</sup> A.',
    ];
    cards.add(Card(
      child: ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Html(
            data: "<b>TA101</b>&nbsp;&nbsp;&nbsp;&nbsp;0,042 A entspricht",
            style: {'body': Style(margin: Margins.zero)},
          ),
        ),
      ),
    ));
    cards.add(const Divider());

    for (int ti = 0; ti < 4; ti++) {
      int i = answerIndex[ti];
      cards.add(Card(
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
              titleAlignment: ListTileTitleAlignment.top,
              leading: Transform.translate(
                offset: const Offset(0, 8),
                child: CircleAvatar(
                  backgroundColor: answerColor[i] == Colors.transparent
                      ? Color.lerp(PRIMARY, Colors.white, 0.8)
                      : answerColor[i],
                  radius: 15,
                  child: answerColor[i] == GREEN
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : answerColor[i] == RED
                          ? const Icon(
                              Icons.clear,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              String.fromCharCode(65 + ti),
                              style: GoogleFonts.alegreyaSans(
                                  fontSize: 14,
                                  color: answerColor[i] == Colors.transparent
                                      ? Colors.black87
                                      : Colors.white,
                                  fontWeight:
                                      answerColor[i] == Colors.transparent
                                          ? FontWeight.normal
                                          : FontWeight.bold),
                            ),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Html(
                  data: answers[i].toString().replaceAll('*', ' ⋅ '),
                  style: {'body': Style(margin: Margins.zero)},
                ),
              ),
            ),
          ),
        ),
      ));
    }
    return IntroductionScreen(
      rawPages: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(255, 109, 195, 231),
                            Color.fromARGB(255, 248, 220, 255)
                          ]),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.0, 1.0),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Image(
                          image: const AssetImage('assets/stack_of_books.png'),
                          // width: constraints.maxWidth * 0.7,
                          height: constraints.maxHeight * 0.7);
                    }),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x00000000),
                          Color(0x30000000),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Lerne für deine Amateurfunkprüfung",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Schau dir kurz an, wie es funktioniert."),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 3,
              child: SafeArea(
                child: Stack(
                  children: [
                    Container(
                      color: Color.lerp(PRIMARY, Colors.white, 0.9),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: getChapterCards(hid: 'TE', demo: true),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x00000000),
                            Color(0x30000000),
                          ],
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Kapitel auswählen und üben",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Such dir ein Kapitel aus und beantworte die Fragen.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Fortschrittsbalken zeigen dir, wie viele der Fragen du schon korrekt beantwortet hast.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Die Fortschrittsbalken verblassen nach und nach.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 3,
              child: SafeArea(
                child: Container(
                  color: Color.lerp(PRIMARY, Colors.white, 0.9),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: cards,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0x00000000),
                              Color(0x30000000),
                            ],
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Trainiere die Fragen",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Wenn du dir sicher bist, kannst du die richtige Antwort einfach antippen.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Falls du dir unsicher bist, tippe lang auf eine Antwort. Du kannst dann in Ruhe die richtige Antwort lesen. Du bekommst die Frage später noch einmal gezeigt.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      next: const Text("Nächster Tipp"),
      done: const Text("Los geht's!",
          style: TextStyle(fontWeight: FontWeight.bold)),
      onDone: () {
        setState(() {
          GlobalData.box.put('shown_intro', true);
        });
      },
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: PRIMARY,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!GlobalData.ready)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (GlobalData.box.get('shown_intro') != true) {
      return introScreen();
    }
    String hid = '';
    try {
      if (ModalRoute.of(context) != null) {
        hid = (ModalRoute.of(context)!.settings.arguments ?? '').toString();
      }
    } catch (e) {}

    var cards = getChapterCards(hid: hid);

    Future<void> _showMyDialog(BuildContext context) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Fortschritt löschen'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Möchtest du deinen gesamten Fortschritt löschen?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Abbrechen'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Löschen'),
                onPressed: () async {
                  var shownIntro = GlobalData.box.get('shown_intro');
                  await clearProgress();
                  if (shownIntro != null) {
                    setState(() {
                      GlobalData.box.put('shown_intro', shownIntro);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        actions: hid.isEmpty
            ? [
                PopupMenuButton(onSelected: (value) async {
                  if (value == 'clear_progress') {
                    _showMyDialog(context);
                  } else if (value == 'show_intro') {
                    await GlobalData.box.delete('shown_intro');
                    setState(() {});
                  } else if (value == 'about') {
                    Navigator.of(context).pushNamed('/about');
                  }
                }, itemBuilder: (itemBuilder) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem<String>(
                      value: "show_intro",
                      child: ListTile(
                          title: Text("Einführung wiederholen"),
                          leading: Icon(Icons.restart_alt)),
                    ),
                    const PopupMenuItem<String>(
                      value: "clear_progress",
                      child: ListTile(
                          title: Text("Fortschritt löschen"),
                          leading: Icon(Icons.delete)),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: "about",
                      child: ListTile(
                          title: Text("Über diese App"),
                          leading: Icon(Icons.info)),
                    ),
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
  double overallProgress = 0.0;
  double? overallProgressFirst;

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
    overallProgress = (candidatesSorted[0].entries.length +
                candidatesSorted[1].entries.length +
                candidatesSorted[2].entries.length +
                candidatesSorted[3].entries.length)
            .toDouble() /
        candidates.length;
    overallProgressFirst ??= overallProgress;

    candidatesSorted.removeWhere((element) => element.entries.isEmpty);
    solvedAll = (candidatesSorted.last.decay == 0);
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
    if (confidenceIndex == 1 &&
        foundCorrect &&
        answerColor[i] != Colors.transparent) {
      launchAnimation();
      return;
    }
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
      GlobalData.instance.unmarkQuestionSolved(qid!);
      solvedAll = false;
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

    cards.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(
            begin: overallProgressFirst,
            end: overallProgress,
          ),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0x20000000),
            color: PRIMARY,
          ),
        ),
      ),
    );

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

    for (int ti = 0; ti < 4; ti++) {
      int i = answerIndex[ti];
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
                                offset = const Offset(-1, 0);
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
                                    _timer = Timer(
                                        const Duration(milliseconds: 1500), () {
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
                                            child: answerColor[i] == GREEN
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  )
                                                : answerColor[i] == RED
                                                    ? const Icon(
                                                        Icons.clear,
                                                        color: Colors.white,
                                                        size: 16,
                                                      )
                                                    : Text(
                                                        String.fromCharCode(
                                                            65 + ti),
                                                        style: GoogleFonts.alegreyaSans(
                                                            fontSize: 14,
                                                            color: answerColor[
                                                                        i] ==
                                                                    Colors
                                                                        .transparent
                                                                ? Colors.black87
                                                                : Colors.white,
                                                            fontWeight: answerColor[
                                                                        i] ==
                                                                    Colors
                                                                        .transparent
                                                                ? FontWeight
                                                                    .normal
                                                                : FontWeight
                                                                    .bold),
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

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String version = "n/a";
  void getVersionInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    getVersionInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: const Text("Über diese App"),
      ),
      body: Html(
        data: "<h2>Hamfisted</h2>"
            "<p>App zur Vorbereitung auf die Amateurfunkprüfung</p>"
            "<p>Die Fragen stammen aus der AFUTrainer-App von <a href='http://oliver-saal.de/software/afutrainer/download.php'>Oliver Saal</a>. Grafiken stammen von <a href='https://freepik.com'>freepik.com</a>. Implementiert von Michael Specht.</p>"
            "<p><b>Version:</b> ${version}</p>"
            "<p><b>Quelltext:</b> <a href='https://github.com/specht/hamfisted'>https://github.com/specht/hamfisted</a></p>"
            "<p><b>Kontakt:</b> <a href='mailto:specht@gymnasiumsteglitz.de'>specht@gymnasiumsteglitz.de</a></p>",
        onLinkTap: (url, attributes, element) {
          developer.log(Uri.parse(url!).toString());
          launchUrl(Uri.parse(url));
        },
      ),
    );
  }
}
