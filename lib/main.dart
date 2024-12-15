import 'dart:developer' as developer;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

const GREEN = Color(0xff73a946);
const RED = Color(0xff992413);
const PRIMARY = Color(0xff1d5479);
const double MAX_WIDTH = 400;

const double INTRO_BOTTOM = 220;
const String ROOT_HID = '2024';

const List<String> introTitles = [
  "Lerne für deine Amateurfunkprüfung",
  "Kapitel auswählen und üben",
  "Trainiere die Fragen",
  "Trainiere die Fragen",
  "Trainiere die Fragen",
  "Trainiere die Fragen",
];

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
          seedColor: PRIMARY,
        ),
        textTheme: GoogleFonts.alegreyaSansTextTheme(textTheme),
        // fontFamily: 'BitstreamCharter',
      ),
      home: const Overview(),
      routes: {
        '/overview': (context) => const Overview(),
        '/quiz': (context) => const Quiz(),
        '/starred': (context) => const Starred(),
        '/about': (context) => const About(),
      },
    );
  }
}

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> with TickerProviderStateMixin {
  String oldTitle = "";
  String newTitle = "";
  bool animatingForward = true;
  int oldPage = 0;
  late final AnimationController _animationControllerHeading =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerCat = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerOverview =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerQuiz = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerSpotSize =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerSpotShift1 =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerSpotShift2 =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  @override
  void initState() {
    resetIntro();
    super.initState();
  }

  @override
  void dispose() {
    _animationControllerHeading.dispose();
    _animationControllerCat.dispose();
    _animationControllerOverview.dispose();
    _animationControllerQuiz.dispose();
    _animationControllerSpotSize.dispose();
    _animationControllerSpotShift1.dispose();
    _animationControllerSpotShift2.dispose();
    super.dispose();
  }

  void resetIntro() {
    oldTitle = introTitles[0];
    newTitle = introTitles[0];
    animatingForward = true;
    oldPage = 0;
    _animationControllerHeading.value = 0.0;
    _animationControllerCat.value = 1.0;
    _animationControllerOverview.value = 0.0;
    _animationControllerQuiz.value = 0.0;
    _animationControllerSpotSize.value = 0.0;
    _animationControllerSpotShift1.value = 0.0;
    _animationControllerSpotShift2.value = 0.0;
  }

  Future<void> clearProgress() async {
    await GlobalData.box.clear();
    setState(() {});
  }

  List<Widget> getChapterCards({String hid = '', bool demo = false}) {
    List<Widget> cards = [];
    int now = DateTime.now().millisecondsSinceEpoch;
    Random r = Random(0);
    for (var subhid in (GlobalData.questions!['children'][hid] ?? [])) {
      if (subhid == '2007') continue;
      List<int> countForDuration = [0, 0, 0, 0, 0];
      if (demo) {
        countForDuration = [10, 13, 9, 2, 28];
        countForDuration.shuffle(r);
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
      String label = GlobalData.questions!['headings'][subhid] ?? subhid;
      cards.add(
        InkWell(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            surfaceTintColor: Colors.transparent,
            elevation: 2,
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
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                offset: const Offset(-2, 5),
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
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(color: PRIMARY),
          SafeArea(
            child: Container(
              color: Color.lerp(PRIMARY, Colors.white, 0.9),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: INTRO_BOTTOM + 64),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                          animation: _animationControllerCat,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _animationControllerCat.value,
                              child: Container(
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
                            );
                          }),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LayoutBuilder(builder: (context, constraints) {
                          return AnimatedBuilder(
                              animation: _animationControllerCat,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1.0 - _animationControllerCat.value) *
                                          constraints.maxHeight),
                                  child: Image(
                                      image: const AssetImage(
                                          'assets/stack_of_books.png'),
                                      height: constraints.maxHeight * 0.7),
                                );
                              });
                        }),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: AnimatedBuilder(
                            animation: _animationControllerOverview,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0,
                                    -(1.0 -
                                            _animationControllerOverview
                                                .value) *
                                        constraints.maxHeight),
                                child: SafeArea(
                                  child: Container(
                                    color:
                                        Color.lerp(PRIMARY, Colors.white, 0.9),
                                    child: SingleChildScrollView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: Column(
                                        children: getChapterCards(
                                            hid: '2024/TA', demo: true),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                      AnimatedBuilder(
                          animation: _animationControllerQuiz,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1.0 - _animationControllerQuiz.value) *
                                          constraints.maxHeight),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: SafeArea(
                                      child: Container(
                                        color: Color.lerp(
                                            PRIMARY, Colors.white, 0.9),
                                        child: SingleChildScrollView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          child: Column(
                                            children: cards,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1.0 - _animationControllerQuiz.value) *
                                          120),
                                  child: BottomMenu(
                                    qid: 'TA101E',
                                    feelingUnsureWidget: Switch(
                                      value: false,
                                      activeColor: Colors.red[900],
                                      onChanged: (value) {},
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1.0 - _animationControllerQuiz.value) *
                                          120),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return Transform.translate(
                                        offset: Offset(
                                            -1 * constraints.maxWidth / 3, 60),
                                        child: AnimatedBuilder(
                                            animation:
                                                _animationControllerSpotShift2,
                                            builder: (context, child) {
                                              return AnimatedBuilder(
                                                  animation:
                                                      _animationControllerSpotShift1,
                                                  builder: (context, child) {
                                                    return AnimatedBuilder(
                                                        animation:
                                                            _animationControllerSpotSize,
                                                        builder:
                                                            (context, child) {
                                                          return Opacity(
                                                            opacity:
                                                                _animationControllerSpotSize
                                                                    .value,
                                                            child: Transform
                                                                .translate(
                                                              offset: Offset(
                                                                  constraints
                                                                          .maxWidth /
                                                                      3 *
                                                                      (_animationControllerSpotShift1
                                                                              .value +
                                                                          _animationControllerSpotShift2
                                                                              .value),
                                                                  0),
                                                              child: Transform
                                                                  .scale(
                                                                scale: 4.0 -
                                                                    3.0 *
                                                                        _animationControllerSpotSize
                                                                            .value,
                                                                child: ClipPath(
                                                                  clipper:
                                                                      MyClipper(),
                                                                  child: Container(
                                                                      decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(1000),
                                                                        gradient:
                                                                            const RadialGradient(
                                                                          colors: [
                                                                            Color(0x80000000),
                                                                            Color(0x00000000),
                                                                          ],
                                                                          stops: [
                                                                            0.0,
                                                                            1.0
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      width: 200,
                                                                      height: 200),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                  });
                                            }),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            );
                          }),
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
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 8,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          stops: [0, 1],
                          colors: [Color(0x00000000), Color(0x20000000)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: INTRO_BOTTOM),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 28, left: 8.0, right: 8.0, bottom: 8.0),
                      child: AnimatedBuilder(
                          animation: _animationControllerHeading,
                          builder: (context, child) {
                            double direction = 1.0;
                            if (!animatingForward) direction = -1.0;
                            return Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Transform.translate(
                                    offset: Offset(
                                        -_animationControllerHeading.value *
                                            constraints.maxWidth *
                                            direction,
                                        0),
                                    child: Text(
                                      oldTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Transform.translate(
                                    offset: Offset(
                                        (1.0 -
                                                _animationControllerHeading
                                                    .value) *
                                            constraints.maxWidth *
                                            direction,
                                        0),
                                    child: Text(
                                      newTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IntroductionScreen(
            next: const Text("Nächster Tipp"),
            done: const Text("Los geht's!"),
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
              activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0)),
            ),
            curve: Curves.easeInOutCubic,
            onChange: (page) {
              animatingForward = (page > oldPage);
              if (introTitles[page] != introTitles[oldPage]) {
                oldTitle = introTitles[oldPage];
                newTitle = introTitles[page];
                _animationControllerHeading.value = 0;
                _animationControllerHeading
                    .animateTo(1.0, curve: Curves.easeInOutCubic)
                    .then((value) {});
              }
              _animationControllerCat.animateTo((page == 0) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);
              _animationControllerOverview.animateTo((page == 1) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);
              _animationControllerQuiz.animateTo((page >= 2) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);
              _animationControllerSpotSize.animateTo((page >= 3) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);
              _animationControllerSpotShift1.animateTo((page >= 4) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);
              _animationControllerSpotShift2.animateTo((page >= 5) ? 1.0 : 0.0,
                  curve: Curves.easeInOutCubic);

              oldPage = page;
            },
            isProgressTap: false,
            globalBackgroundColor: Colors.transparent,
            rawPages: const [
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Schau dir kurz an, wie es funktioniert.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Such dir ein Kapitel aus und beantworte die Fragen.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Fortschrittsbalken zeigen dir an, wie viele der Fragen du schon korrekt beantwortet hast.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Die Fortschrittsbalken verblassen nach einigen Tagen.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Wenn du dir sicher bist, kannst du die richtige Antwort einfach antippen.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Falls du dir unsicher bist, tippe auf den Schalter unten links (oder tippe lang auf eine Antwort).",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Du kannst dann in Ruhe alle Antworten aufdecken, bis du die richtige Antwort gefunden hast. Du bekommst die Frage später noch einmal gezeigt.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Wenn du dir eine Frage für später merken möchtest, tippe auf das Sternsymbol.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Du kannst dir alle gemerkten Fragen später ansehen und üben.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              IntroScreenColumn(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Tippe auf »Frage überspringen«, wenn du eine Frage gerade nicht beantworten kannst oder möchtest.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!GlobalData.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (GlobalData.box.get('shown_intro') != true) {
      return introScreen();
    }
    String hid = ROOT_HID;
    if (ModalRoute.of(context) != null) {
      hid = (ModalRoute.of(context)!.settings.arguments ?? ROOT_HID).toString();
    }

    var cards = getChapterCards(hid: hid);

    Future<void> showMyDialog(BuildContext context) async {
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
      floatingActionButton: (GlobalData.starBox.length > 0 && hid == ROOT_HID)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/starred').then((value) {
                  setState(() {});
                });
              },
              icon: const Icon(Icons.star),
              label: Text(
                "Gemerkte Fragen (${GlobalData.starBox.length})",
                style: const TextStyle(fontSize: 16),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: hid == ROOT_HID
            ? [
                PopupMenuButton(onSelected: (value) async {
                  if (value == 'clear_progress') {
                    showMyDialog(context);
                  } else if (value == 'show_intro') {
                    await GlobalData.box.delete('shown_intro');
                    setState(() {
                      resetIntro();
                    });
                  } else if (value == 'about') {
                    Navigator.of(context).pushNamed('/about');
                  }
                }, itemBuilder: (itemBuilder) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem<String>(
                      value: "show_intro",
                      child: ListTile(
                        title: Text("Einführung wiederholen"),
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.restart_alt),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: "clear_progress",
                      child: ListTile(
                        title: Text("Fortschritt löschen"),
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.delete),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: "about",
                      child: ListTile(
                        title: Text("Über diese App"),
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.info),
                      ),
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
      bottomNavigationBar: hid == ''
          ? null
          : Container(
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Color(0x80000000), blurRadius: 5)
              ]),
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
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

Widget getQuestionWidget(String qid) {
  String qidDisplay = qid ?? '';
  if (qidDisplay.endsWith('E') || qidDisplay.endsWith('A')) {
    qidDisplay = qidDisplay.substring(0, qidDisplay.length - 1);
  }
  qidDisplay = qidDisplay.replaceFirst('2024_', '');

  return LayoutBuilder(builder: (context, constraints) {
    double cwidth = min(constraints.maxWidth, MAX_WIDTH);
    List<Widget> challengeParts = [];

    if (GlobalData.questions!['questions'][qid]['challenge'] != null) {
      challengeParts.add(Container(
        constraints: BoxConstraints(maxWidth: cwidth),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Html(
            data:
                "<b>$qidDisplay</b>&nbsp;&nbsp;&nbsp;&nbsp;${GlobalData.questions!['questions'][qid]['challenge']}",
            style: {
              'body': Style(margin: Margins.zero, fontSize: FontSize(16))
            },
          ),
        ),
      ));
    }

    if (GlobalData.questions!['questions'][qid]['challenge_tex'] != null) {
      developer.log(GlobalData.questions!['questions'][qid]['challenge_tex']);
      challengeParts.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: SizedBox(
          width: cwidth,
          height: max(
              60,
              cwidth /
                  GlobalData.questions!['questions'][qid]
                      ['challenge_tex_width'] *
                  GlobalData.questions!['questions'][qid]
                      ['challenge_tex_height']),
          child: FutureBuilder(
              future: ScalableImage.fromSIAsset(rootBundle,
                  "data/2024/tex/${GlobalData.questions!['questions'][qid]['challenge_tex']}.si"),
              builder: (context, snapshot) {
                developer.log(
                    GlobalData.questions!['questions'][qid]['challenge_tex']);
                return ScalableImageWidget(
                  si: snapshot.requireData,
                );
              }),
        ),
      ));
    }

    if (GlobalData.questions!['questions'][qid]['challenge_svg'] != null) {
      var aspect = GlobalData.questions!['questions'][qid]
              ['challenge_svg_width'] /
          GlobalData.questions!['questions'][qid]['challenge_svg_height'];
      var width = (cwidth) *
          min(GlobalData.questions!['questions'][qid]['challenge_svg_width'],
              250) /
          250;
      var height = width / aspect;
      challengeParts.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          "data/2024/${GlobalData.questions!['questions'][qid]['challenge_svg']}",
          width: width,
          height: height,
        ),
      ));
    }

    if (GlobalData.questions!['questions'][qid]['challenge_png'] != null) {
      challengeParts.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image(
          image: AssetImage(
            "data/2024/${GlobalData.questions!['questions'][qid]['challenge_png']}",
          ),
        ),
      ));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      child: Column(children: challengeParts),
    );
  });
}

class _QuizState extends State<Quiz> with TickerProviderStateMixin {
  String? hid;
  String? qid;
  bool unsure = false;
  List<Color> answerColor = [];
  List<int> answerIndex = [];
  bool guessedWrong = false;
  bool foundCorrect = false;
  bool animationPhase1 = false;
  bool animationPhase2 = false;
  bool animationPhase3 = false;
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

  // late final PlatformWebViewControllerCreationParams params;
  // late final WebViewController wvController;

  @override
  void initState() {
    super.initState();
//     if (WebViewPlatform.instance is WebKitWebViewPlatform) {
//       params = WebKitWebViewControllerCreationParams(
//         allowsInlineMediaPlayback: true,
//         mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
//       );
//     } else {
//       params = const PlatformWebViewControllerCreationParams();
//     }

//     wvController = WebViewController.fromPlatformCreationParams(params);
//     wvController
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             debugPrint('WebView is loading (progress : $progress%)');
//           },
//           onPageStarted: (String url) {
//             debugPrint('Page started loading: $url');
//           },
//           onPageFinished: (String url) {
//             debugPrint('Page finished loading: $url');
//           },
//           onWebResourceError: (WebResourceError error) {
//             debugPrint('''
// Page resource error:
//   code: ${error.errorCode}
//   description: ${error.description}
//   errorType: ${error.errorType}
//   isForMainFrame: ${error.isForMainFrame}
//           ''');
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             if (request.url.startsWith('https://www.youtube.com/')) {
//               debugPrint('blocking navigation to ${request.url}');
//               return NavigationDecision.prevent;
//             }
//             debugPrint('allowing navigation to ${request.url}');
//             return NavigationDecision.navigate;
//           },
//           onUrlChange: (UrlChange change) {
//             debugPrint('url change to ${change.url}');
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'Toaster',
//         onMessageReceived: (JavaScriptMessage message) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(message.message)),
//           );
//         },
//       );

//     // #docregion platform_features
//     if (wvController.platform is AndroidWebViewController) {
//       AndroidWebViewController.enableDebugging(true);
//       (wvController.platform as AndroidWebViewController)
//           .setMediaPlaybackRequiresUserGesture(false);
//     }
//     wvController.loadHtmlString('hello');
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
    unsure = false;
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

  void launchAnimation({bool quick = false}) {
    _animationController.reset();
    _animationController2.reset();
    _animationController3.reset();
    if (quick) {
      animationPhase1 = true;
      animationPhase2 = true;
      _animationController.animateTo(1.0, curve: Curves.easeInOutCubic);
      _animationController2
          .animateTo(1.0, curve: Curves.easeInOutCubic)
          .then((value) {
        animationPhase3 = true;
        setState(() {
          pickTask();
        });
        _animationController3
            .animateTo(1.0, curve: Curves.easeInOutCubic)
            .then((value) {
          setState(() {
            animationPhase1 = false;
            animationPhase2 = false;
            animationPhase3 = false;
            _animationController.reset();
            _animationController2.reset();
            _animationController3.reset();
          });
        });
      });
    } else {
      animationPhase1 = true;
      _animationController
          .animateTo(1.0, curve: Curves.easeInOutCubic)
          .then((value) {
        animationPhase1 = false;
        animationPhase2 = true;
        _animationController2
            .animateTo(1.0, curve: Curves.easeInOutCubic)
            .then((value) {
          animationPhase3 = true;
          setState(() {
            pickTask();
          });
          _animationController3
              .animateTo(1.0, curve: Curves.easeInOutCubic)
              .then((value) {
            setState(() {
              animationPhase1 = false;
              animationPhase2 = false;
              animationPhase3 = false;
              _animationController.reset();
              _animationController2.reset();
              _animationController3.reset();
            });
          });
        });
      });
    }
  }

  void tapAnswer(int i) {
    if (unsure && foundCorrect && answerColor[i] != Colors.transparent) {
      launchAnimation();
      return;
    }
    if (i == 0) {
      // answer is correct
      foundCorrect = true;
      answerColor[i] = GREEN;
      if (!guessedWrong) {
        if (!unsure) {
          GlobalData.instance
              .markQuestionSolved(qid!, DateTime.now().millisecondsSinceEpoch);
        }
      }
      if (!unsure) {
        launchAnimation();
      }
    } else {
      // answer is wrong
      answerColor[i] = RED;
      guessedWrong = true;
      unsure = true;
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
    // qid = '2024_AF420';

    List<Widget> cards = [];

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
            color: Color.lerp(PRIMARY, Colors.black, 0.5),
          ),
        ),
      ),
    );

    cards.add(getQuestionWidget(qid!));

    cards.add(const Divider());

    for (int ti = 0; ti < 4; ti++) {
      int i = answerIndex[ti];
      cards.add(
        Padding(
          padding:
              ti == 3 ? const EdgeInsets.only(bottom: 105) : EdgeInsets.zero,
          child: AnimatedBuilder(
              animation: _animationController3,
              builder: (context, child) {
                return AnimatedBuilder(
                    animation: _animationController2,
                    builder: (context, child) {
                      return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return LayoutBuilder(
                                builder: (context, constraints) {
                              double cwidth =
                                  min(constraints.maxWidth, MAX_WIDTH);
                              Offset offset = Offset.zero;
                              if (animationPhase1) {
                                if (i != 0) {
                                  offset = Offset(
                                      -1 * _animationController.value, 0);
                                }
                              }
                              if (animationPhase2) {
                                if (i != 0 && !animationPhase1) {
                                  offset = const Offset(-1, 0);
                                } else {
                                  offset =
                                      Offset(-_animationController2.value, 0);
                                }
                              }
                              if (animationPhase3) {
                                offset = Offset(
                                    1.0 - _animationController3.value, 0);
                              }
                              return Transform.translate(
                                offset: offset * constraints.maxWidth,
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  surfaceTintColor: Colors.transparent,
                                  child: InkWell(
                                    onTapCancel: () => _timer?.cancel(),
                                    onTapDown: (_) => {
                                      _timer = Timer(
                                          const Duration(milliseconds: 1500),
                                          () {
                                        setState(() {
                                          unsure = true;
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
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: max(
                                                  0,
                                                  (constraints.maxWidth -
                                                              cwidth) /
                                                          2 -
                                                      15)),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        answerColor[i] ==
                                                                Colors
                                                                    .transparent
                                                            ? Color.lerp(
                                                                PRIMARY,
                                                                Colors.white,
                                                                0.8)
                                                            : answerColor[i],
                                                    radius: cwidth * 0.045,
                                                    child:
                                                        answerColor[i] == GREEN
                                                            ? Icon(
                                                                Icons.check,
                                                                color: Colors
                                                                    .white,
                                                                size: cwidth *
                                                                    0.05,
                                                              )
                                                            : answerColor[i] ==
                                                                    RED
                                                                ? Icon(
                                                                    Icons.clear,
                                                                    color: Colors
                                                                        .white,
                                                                    size:
                                                                        cwidth *
                                                                            0.05,
                                                                  )
                                                                : Text(
                                                                    String.fromCharCode(
                                                                        65 +
                                                                            ti),
                                                                    style: GoogleFonts.alegreyaSans(
                                                                        fontSize:
                                                                            cwidth *
                                                                                0.04,
                                                                        color: answerColor[i] == Colors.transparent
                                                                            ? Colors
                                                                                .black87
                                                                            : Colors
                                                                                .white,
                                                                        fontWeight: answerColor[i] ==
                                                                                Colors.transparent
                                                                            ? FontWeight.normal
                                                                            : FontWeight.bold),
                                                                  ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width:
                                                    cwidth * (1.0 - 0.045) - 70,
                                                child:
                                                    (GlobalData.questions!['questions'][qid]
                                                                    [
                                                                    'answers_tex'] ==
                                                                null &&
                                                            GlobalData.questions!['questions']
                                                                        [qid][
                                                                    'answers_svg'] ==
                                                                null)
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        13.0),
                                                            child: Html(
                                                              data: GlobalData
                                                                  .questions![
                                                                      'questions']
                                                                      [qid][
                                                                      'answers']
                                                                      [i]
                                                                  .toString()
                                                                  .replaceAll(
                                                                      '*',
                                                                      ' ⋅ '),
                                                              style: {
                                                                'body': Style(
                                                                  margin:
                                                                      Margins
                                                                          .zero,
                                                                ),
                                                              },
                                                            ),
                                                          )
                                                        : (GlobalData.questions!['questions']
                                                                        [qid][
                                                                    'answers_svg'] ==
                                                                null
                                                            ? LayoutBuilder(
                                                                builder: (context,
                                                                    constraints) {
                                                                return Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              6,
                                                                          bottom:
                                                                              6),
                                                                  child: SizedBox(
                                                                      width: constraints.maxWidth,
                                                                      height: constraints.maxWidth / GlobalData.questions!['questions'][qid]['answers_tex_width'][i] * GlobalData.questions!['questions'][qid]['answers_tex_height'][i],
                                                                      child: FutureBuilder(
                                                                          future: ScalableImage.fromSIAsset(rootBundle, "data/2024/tex/${GlobalData.questions!['questions'][qid]['answers_tex'][i]}.si"),
                                                                          builder: (context, snapshot) {
                                                                            return ScalableImageWidget(
                                                                              si: snapshot.requireData,
                                                                            );
                                                                          })),
                                                                );
                                                              })
                                                            : SvgPicture.asset(
                                                                "data/2024/${GlobalData.questions!['questions'][qid]['answers_svg'][i]}",
                                                                width: cwidth *
                                                                    0.86,
                                                              )),
                                              ),
                                            ],
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
        ),
      );
    }

    Switch unsureSwitch = Switch(
      value: unsure,
      activeColor: Colors.red[900],
      onChanged: (value) {
        if (!unsure) {
          setState(() => unsure = value);
        }
      },
    );

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        title: Text(
            (GlobalData.questions!['headings'][hid] ?? 'Amateurfunkprüfung')),
      ),
      body: Stack(
        children: [
          Container(
            child: ListView(
              children: cards,
            ),
          ),
          BottomMenu(
            qid: qid!,
            feelingUnsureWidget: unsureSwitch,
            onFeelingUnsure: () {
              unsureSwitch.onChanged!(true);
              unsure = true;
            },
            onHelp: GlobalData.questions!['questions'][qid]['hint'] == null
                ? null
                : () {
                    String? url =
                        GlobalData.questions!['questions'][qid]['hint'];
                    developer.log("$url");
                    if (url != null) {
                      setState(() => unsure = true);
                      launchUrl(Uri.parse(url));
                    }
                  },
            onStar: () {
              setState(() {
                bool questionIsStarred = GlobalData.starBox.get(qid) ?? false;
                if (questionIsStarred)
                  GlobalData.instance.unstarQuestion(qid!);
                else
                  GlobalData.instance.starQuestion(qid!);
              });
            },
            onSkip: () {
              launchAnimation(quick: true);
            },
          ),
          if (solvedAll)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120, right: 10),
                child: ElevatedButton.icon(
                  style: ButtonStyle(
                    surfaceTintColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    elevation: WidgetStateProperty.all(4),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10000)),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text(
                    "Alle Fragen beantwortet!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
      ),
      body: Html(
        data: "<h2>Hamfisted</h2>"
            "<p>App zur Vorbereitung auf die Amateurfunkprüfung</p>"
            "Die Fragen stammen von der Bundesnetzagentur (3. Auflage, März 2024). Grafiken stammen von <a href='https://freepik.com'>freepik.com</a>. Implementiert von Michael Specht.</p>"
            "<p><b>Version:</b> ${version}</p>"
            "<p><b>Quelltext:</b> <a href='https://github.com/specht/hamfisted'>https://github.com/specht/hamfisted</a></p>"
            "<p><b>Kontakt:</b> <a href='mailto:specht@gymnasiumsteglitz.de'>specht@gymnasiumsteglitz.de</a></p>",
        onLinkTap: (url, attributes, element) {
          launchUrl(Uri.parse(url!));
        },
      ),
    );
  }
}

class BottomMenu extends StatefulWidget {
  final Function? onFeelingUnsure;
  final Widget feelingUnsureWidget;
  final Function? onHelp;
  final Function? onStar;
  final Function? onSkip;
  final String qid;

  const BottomMenu(
      {super.key,
      required this.qid,
      required this.feelingUnsureWidget,
      this.onFeelingUnsure,
      this.onSkip,
      this.onHelp,
      this.onStar});

  @override
  State<BottomMenu> createState() => _BottomMenuState();
}

class _BottomMenuState extends State<BottomMenu> {
  @override
  Widget build(BuildContext context) {
    bool questionIsStarred = GlobalData.starBox.get(widget.qid) ?? false;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 5)],
              color: Colors.white,
            ),
            child: Material(
              child: LayoutBuilder(builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth / 3,
                      child: InkWell(
                        onTap: widget.onFeelingUnsure == null
                            ? null
                            : () {
                                widget.onFeelingUnsure!();
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8, left: 8, right: 8, bottom: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 45,
                                child: widget.feelingUnsureWidget,
                              ),
                              const Text(
                                "Ich bin mir\nunsicher",
                                textAlign: TextAlign.center,
                                style: TextStyle(height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth / 3,
                      child: InkWell(
                        onTap: widget.onStar == null
                            ? null
                            : () {
                                widget.onStar!();
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8, left: 8, right: 8, bottom: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 45,
                                child: Icon(
                                  questionIsStarred
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: questionIsStarred
                                      ? Colors.yellow[700]
                                      : null,
                                  size: questionIsStarred ? 32 : 28,
                                ),
                              ),
                              const Text(
                                "Frage für später\nmerken",
                                textAlign: TextAlign.center,
                                style: const TextStyle(height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth / 3,
                      child: InkWell(
                        onTap: widget.onSkip == null
                            ? null
                            : () {
                                widget.onSkip!();
                              },
                        child: const Padding(
                          padding: EdgeInsets.only(
                              top: 8, left: 8, right: 8, bottom: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 45,
                                child: Icon(
                                  Icons.skip_next_outlined,
                                  size: 28,
                                ),
                              ),
                              Text(
                                "Frage\nüberspringen",
                                textAlign: TextAlign.center,
                                style: TextStyle(height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: 55))
      ..close();

    return Path.combine(
        PathOperation.difference,
        Path()
          ..addRRect(
              RRect.fromLTRBR(0, 0, size.width, size.height, Radius.zero)),
        path);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class IntroScreenColumn extends StatelessWidget {
  const IntroScreenColumn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          Container(
            color: Colors.transparent,
            child: SizedBox(
              height: constraints.maxHeight - INTRO_BOTTOM,
            ),
          ),
          Container(
            color: Colors.white,
            child: SizedBox(
              height: INTRO_BOTTOM,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: SizedBox(width: double.maxFinite, child: child),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class Starred extends StatefulWidget {
  const Starred({super.key});

  @override
  State<Starred> createState() => _StarredState();
}

class _StarredState extends State<Starred> {
  Future<void> showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gemerkte Fragen löschen'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Möchtest du deine gemerkten Fragen löschen?'),
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
                await GlobalData.starBox.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    List<dynamic> sortedKeys = GlobalData.starBox.keys.toList();
    sortedKeys.sort((a, b) {
      const order = ['B', 'V', 'N', 'E', 'A'];
      int indexA = order.indexOf(a[5]);
      int indexB = order.indexOf(b[5]);
      if (indexA == indexB) {
        return a.compareTo(b);
      }
      return indexA.compareTo(indexB);
    });
    String lastHeader = '';
    for (String qid in sortedKeys) {
      String hid = GlobalData.questions!['hid_for_question'][qid];
      if (hid != lastHeader) {
        cards.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            GlobalData.questions!['headings'][hid],
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ));
      }
      lastHeader = hid;
      String qidDisplay = qid;
      if (qidDisplay.endsWith('E') || qidDisplay.endsWith('A')) {
        qidDisplay = qidDisplay.substring(0, qidDisplay.length - 1);
      }
      qidDisplay = qidDisplay.replaceFirst('2024_', '');
      List<Widget> columnChildren = [];
      for (int i = 0; i < 4; i++) {
        columnChildren.add(
          LayoutBuilder(builder: (context, constraints) {
            double cwidth = min(constraints.maxWidth, MAX_WIDTH);
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              surfaceTintColor: Colors.transparent,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          max(0, (constraints.maxWidth - cwidth) / 2 - 15)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: CircleAvatar(
                              backgroundColor:
                                  Color.lerp(PRIMARY, Colors.white, 0.8),
                              radius: cwidth * 0.045,
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: GoogleFonts.alegreyaSans(
                                    fontSize: cwidth * 0.04,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: cwidth * (1.0 - 0.045) - 70,
                          child: (GlobalData.questions!['questions'][qid]
                                          ['answers_tex'] ==
                                      null &&
                                  GlobalData.questions!['questions'][qid]
                                          ['answers_svg'] ==
                                      null)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13.0),
                                  child: Html(
                                    data: GlobalData.questions!['questions']
                                            [qid]['answers'][i]
                                        .toString()
                                        .replaceAll('*', ' ⋅ '),
                                    style: {
                                      'body': Style(
                                        margin: Margins.zero,
                                      ),
                                    },
                                  ),
                                )
                              : (GlobalData.questions!['questions'][qid]
                                          ['answers_svg'] ==
                                      null
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 6, bottom: 6),
                                        child: SizedBox(
                                            width: constraints.maxWidth,
                                            height: constraints.maxWidth /
                                                GlobalData.questions![
                                                        'questions'][qid]
                                                    ['answers_tex_width'][i] *
                                                GlobalData.questions![
                                                        'questions'][qid]
                                                    ['answers_tex_height'][i],
                                            child: FutureBuilder(
                                                future: ScalableImage.fromSIAsset(
                                                    rootBundle,
                                                    "data/2024/tex/${GlobalData.questions!['questions'][qid]['answers_tex'][i]}.si"),
                                                builder: (context, snapshot) {
                                                  return ScalableImageWidget(
                                                    si: snapshot.requireData,
                                                  );
                                                })),
                                      );
                                    })
                                  : SvgPicture.asset(
                                      "data/2024/${GlobalData.questions!['questions'][qid]['answers_svg'][i]}",
                                      width: cwidth * 0.86,
                                    )),
                        ),
                      ]),
                ),
              ),
            );
          }),
        );
      }
      Widget widget = ExpansionTile(
        visualDensity: VisualDensity.compact,
        shape: const Border(),
        title: getQuestionWidget(qid),
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        showTrailingIcon: false,
        children: columnChildren,
      );
      cards.add(
        Dismissible(
          key: Key(qid),
          direction: DismissDirection.startToEnd,
          background: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.delete, color: Colors.black45),
            ),
          ),
          onDismissed: (direction) {
            GlobalData.instance.unstarQuestion(qid);
            setState(() {
              if (GlobalData.starBox.keys.length == 0) {
                Navigator.of(context).pop();
              }
            });
          },
          child: widget,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(onSelected: (value) async {
            if (value == 'clear_all_stars') {
              await showMyDialog(context);
              if (GlobalData.starBox.keys.length == 0) {
                Navigator.of(context).pop();
              }
            }
          }, itemBuilder: (itemBuilder) {
            return <PopupMenuEntry>[
              const PopupMenuItem<String>(
                value: "clear_all_stars",
                child: ListTile(
                  title: Text("Alle gemerkten Fragen löschen"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.delete),
                ),
              ),
            ];
          })
        ],
        title: const Text("Gemerkte Fragen"),
      ),
      body: ListView(
        children: cards,
      ),
    );
  }
}
