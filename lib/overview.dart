import 'dart:async';
import 'dart:math';

import 'package:Hamfisted/aid.dart';
import 'package:Hamfisted/exam_overview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'data.dart';
import 'quiz.dart';

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
  late final AnimationController _animationControllerExamOverview =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final AnimationController _animationControllerAid = AnimationController(
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
    _animationControllerExamOverview.dispose();
    _animationControllerAid.dispose();
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
    _animationControllerExamOverview.value = 0.0;
    _animationControllerAid.value = 0.0;
    _animationControllerSpotSize.value = 0.0;
    _animationControllerSpotShift1.value = 0.0;
    _animationControllerSpotShift2.value = 0.0;
  }

  Future<void> clearProgress() async {
    String hid = ROOT_HID;
    if (ModalRoute.of(context) != null) {
      hid = (ModalRoute.of(context)!.settings.arguments ?? ROOT_HID).toString();
    }
    List<String> entries = [];
    for (String qid
        in (GlobalData.questions!['questions_for_hid'][hid] ?? [])) {
      entries.add("t/$qid");
      entries.add("r/$qid");
      entries.add("i/$qid");
      entries.add("e/$qid");
    }

    await GlobalData.box.deleteAll(entries);

    setState(() {});
  }

  Future<void> feignProgress() async {
    String hid = ROOT_HID;
    if (ModalRoute.of(context) != null) {
      hid = (ModalRoute.of(context)!.settings.arguments ?? ROOT_HID).toString();
    }
    Random random = Random(DateTime.now().millisecondsSinceEpoch);
    int daysRange = 7;
    int daysOffset = 7;
    for (String qid
        in (GlobalData.questions!['questions_for_hid'][hid] ?? [])) {
      GlobalData.instance.setLastReviewedForQuestion(
          qid,
          (DateTime.now().millisecondsSinceEpoch -
                  random.nextInt(1000 * 60 * 60 * 24 * daysRange) -
                  1000 * 60 * 60 * 24 * daysOffset)
              .round());
      GlobalData.instance.setRepetitionsForQuestion(qid, random.nextInt(3));
      GlobalData.instance.setIntervalForQuestion(qid, random.nextInt(30));
      GlobalData.instance
          .setEasinessForQuestion(qid, 1.3 + random.nextDouble() * 1.7);
    }

    setState(() {});
  }

  List<Widget> getChapterCards({String hid = '', bool demo = false}) {
    List<Widget> cards = [];
    for (var subhid in (GlobalData.questions!['children'][hid] ?? [])) {
      if (subhid == '2007') continue;
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
                child: ProgressBarForHid(hid: subhid, demo: demo),
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
    String qid = '2024_EI103';
    cards.add(getQuestionWidget(qid));
    cards.add(const Divider());
    // for (int i = 0; i < 4; i++) {
    //   cards.add(getAnswerWidget(qid, i));
    // }

    for (int i = 0; i < 4; i++) {
      cards.add(
        LayoutBuilder(builder: (context, constraints) {
          double cwidth = min(constraints.maxWidth, MAX_WIDTH);
          return Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        padding: const EdgeInsets.all(7.0),
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
                        child: getAnswerWidget(qid, i),
                      ),
                    ]),
              ),
            ),
          );
        }),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(color: PRIMARY),
          Container(
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
                              offset: _animationControllerOverview.value < 0.5
                                  ? Offset(
                                      0,
                                      -(1.0 -
                                              _animationControllerOverview
                                                      .value *
                                                  2.0) *
                                          constraints.maxHeight)
                                  : Offset(
                                      -(_animationControllerOverview.value -
                                              0.5) *
                                          2.0 *
                                          constraints.maxWidth,
                                      0),
                              child: Scaffold(
                                backgroundColor:
                                    Color.lerp(PRIMARY, Colors.white, 0.9),
                                appBar: AppBar(
                                  backgroundColor: PRIMARY,
                                  foregroundColor: Colors.white,
                                  automaticallyImplyLeading: false,
                                  title: const Text(
                                      "Technische Kenntnisse der Klasse N"),
                                ),
                                body: Container(
                                  color: Color.lerp(PRIMARY, Colors.white, 0.9),
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
                                offset: _animationControllerQuiz.value < 0.0
                                    ? Offset(
                                        -(_animationControllerQuiz.value -
                                                0.5) *
                                            2.0 *
                                            constraints.maxWidth,
                                        0)
                                    : Offset(
                                        -(_animationControllerQuiz.value -
                                                0.5) *
                                            2.0 *
                                            constraints.maxWidth,
                                        0),
                                child: Scaffold(
                                  backgroundColor:
                                      Color.lerp(PRIMARY, Colors.white, 0.9),
                                  appBar: AppBar(
                                    backgroundColor: PRIMARY,
                                    foregroundColor: Colors.white,
                                    automaticallyImplyLeading: false,
                                    title: Text(
                                        "Technische Kenntnisse der Klasse N"),
                                  ),
                                  body: Material(
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
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Transform.translate(
                                  offset: Offset(
                                      0,
                                      (1.0 -
                                              (0.5 -
                                                      (0.5 -
                                                              _animationControllerQuiz
                                                                  .value)
                                                          .abs()) *
                                                  2.0) *
                                          120),
                                  child: QuizBottomMenu(
                                    qid: qid,
                                    feelingUnsureWidget: Switch(
                                      value: false,
                                      activeColor: Colors.red[900],
                                      onChanged: (value) {},
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(
                                    0,
                                    (1.0 -
                                            (0.5 -
                                                    (0.5 -
                                                            _animationControllerQuiz
                                                                .value)
                                                        .abs()) *
                                                2.0) *
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
                                                            child:
                                                                Transform.scale(
                                                              scale: 4.0 -
                                                                  3.0 *
                                                                      _animationControllerSpotSize
                                                                          .value,
                                                              child: ClipPath(
                                                                clipper:
                                                                    MyClipper(),
                                                                child:
                                                                    Container(
                                                                        decoration:
                                                                            BoxDecoration(
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
                                                                        width:
                                                                            200,
                                                                        height:
                                                                            200),
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
                      child: LayoutBuilder(builder: (context, constraints) {
                        return AnimatedBuilder(
                            animation: _animationControllerExamOverview,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    _animationControllerExamOverview.value < 0.0
                                        ? Offset(
                                            -(_animationControllerExamOverview
                                                        .value -
                                                    0.5) *
                                                2.0 *
                                                constraints.maxWidth,
                                            0)
                                        : Offset(
                                            -(_animationControllerExamOverview
                                                        .value -
                                                    0.5) *
                                                2.0 *
                                                constraints.maxWidth,
                                            0),
                                child: Scaffold(
                                  backgroundColor:
                                      Color.lerp(PRIMARY, Colors.white, 0.9),
                                  appBar: AppBar(
                                    backgroundColor: PRIMARY,
                                    foregroundColor: Colors.white,
                                    title: Text("Prüfungssimulation"),
                                  ),
                                  body: ListView(
                                    children: [
                                      for (String exam in [
                                        'N',
                                        'E',
                                        'A',
                                        'B',
                                        'V'
                                      ])
                                        Card(
                                          child: ListTile(
                                            title: Text(
                                              "${examTitle[exam]}",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        "25 Fragen aus ${GlobalData.questions!['questions_for_hid'][questionCountKey[exam]].length}"),
                                                    Text(
                                                        "${EXAM_MINUTES[exam]} Minuten"),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8, bottom: 4),
                                                  child: ProgressBarForHid(
                                                    hid:
                                                        questionCountKey[exam]!,
                                                    demo: true,
                                                    examOverviewDemo: true,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                        "Geschätzte Erfolgswahrscheinlichkeit: "),
                                                    Text(
                                                      exam == "N"
                                                          ? "90%"
                                                          : "0%",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Text(
                                          "Die Prozentangaben zeigen deine momentane Wahrscheinlichkeit an, den entsprechenden Prüfungsteil zu bestehen. Die Berechnung erfolgt aufgrund deiner bisherigen Antworten im Prüfungstraining und in Prüfungssimulationen.",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: "Alegreya Sans",
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            left: 16, right: 16, bottom: 0),
                                        child: Text(
                                          "Dabei spielt es nicht direkt eine Rolle, wie viele Prüfungssimulationen du bereits bestanden hast. Es zählen nur deine bisherigen Antworten auf die Fragen des jeweiligen Fragenkataloges. Für die Prüfungssimulation werden 25 Fragen quer aus dem jeweiligen Fragenkatalog zufällig ausgewählt und anschließend für jede dieser Fragen geschätzt, wie wahrscheinlich es ist, dass du sie korrekt beantworten kannst. Daraus wird dann die Erfolgswahrscheinlichkeit für den jeweiligen Prüfungsteil berechnet.",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: "Alegreya Sans",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      }),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LayoutBuilder(builder: (context, constraints) {
                        return AnimatedBuilder(
                            animation: _animationControllerAid,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _animationControllerAid.value < 0.0
                                    ? Offset(
                                        -(_animationControllerAid.value - 0.5) *
                                            2.0 *
                                            constraints.maxWidth,
                                        0)
                                    : Offset(
                                        -(_animationControllerAid.value - 0.5) *
                                            2.0 *
                                            constraints.maxWidth,
                                        0),
                                child: Scaffold(
                                  backgroundColor:
                                      Color.lerp(PRIMARY, Colors.white, 0.9),
                                  appBar: AppBar(
                                    backgroundColor: PRIMARY,
                                    foregroundColor: Colors.white,
                                    title: Text("Hilfsmittel"),
                                  ),
                                  body: LayoutBuilder(
                                    builder: (context, constraints) {
                                      double containerWidth =
                                          constraints.maxWidth;
                                      double containerHeight =
                                          constraints.maxHeight;
                                      const aspectRatio = 210 / 297;
                                      const verticalPadding = 8.0 * 2;
                                      final pageWidth =
                                          MediaQuery.of(context).size.width -
                                              16.0;
                                      final height = pageWidth / aspectRatio;
                                      double _pageHeight =
                                          height + verticalPadding;
                                      final double devicePixelRatio =
                                          MediaQuery.of(context)
                                              .devicePixelRatio;
                                      int size = (containerWidth *
                                                  devicePixelRatio)
                                              .toInt() *
                                          (containerHeight * devicePixelRatio)
                                              .toInt() *
                                          4;
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                          maxWidth: constraints.maxWidth,
                                          minHeight: constraints.maxHeight,
                                          maxHeight: double.infinity,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              for (int i = 0; i < 24; i++)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8,
                                                      horizontal: 8),
                                                  child: AspectRatio(
                                                    aspectRatio: 210 / 297,
                                                    child: Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.white,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 4.0,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Image.asset(
                                                        "assets/hilfsmittel-13-150.jpg",
                                                        width: constraints
                                                                .maxWidth -
                                                            16,
                                                        height: _pageHeight,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      // child: Stack(
                                                      //   children: [
                                                      //     // Image(
                                                      //     //   image: GlobalData.instance.previewImages[i]!,
                                                      //     // ),
                                                      //     ScalableImageWidget(
                                                      //       si: GlobalData.instance.aidScalableImages[i],
                                                      //       isComplex: true,
                                                      //     ),
                                                      //   ],
                                                      // ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            });
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
              size: const Size.square(6.0),
              activeSize: const Size(12.0, 8.0),
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
              if (page < 1) {
                _animationControllerOverview.animateTo(0.0,
                    curve: Curves.easeInOutCubic);
              } else if (page == 1) {
                _animationControllerOverview.animateTo(0.5,
                    curve: Curves.easeInOutCubic);
              } else {
                _animationControllerOverview.animateTo(1.0,
                    curve: Curves.easeInOutCubic);
              }
              _animationControllerQuiz.animateTo(
                  (page < 2) ? 0.0 : ((page >= 2 && page <= 5) ? 0.5 : 1.0),
                  curve: Curves.easeInOutCubic);
              _animationControllerExamOverview.animateTo(
                  (page < 6) ? 0.0 : ((page == 6) ? 0.5 : 1.0),
                  curve: Curves.easeInOutCubic);
              _animationControllerAid.animateTo(
                  (page < 7) ? 0.0 : ((page == 7) ? 0.5 : 1.0),
                  curve: Curves.easeInOutCubic);
              _animationControllerSpotSize.animateTo(
                  (page >= 3 && page <= 5) ? 1.0 : 0.0,
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
                        "Hamfisted hilft dir, dich auf die Amateurfunkprüfung vorzubereiten. Eine smarte Lernmethode (Spaced Repetition) hilft dir dabei, deinen Fortschritt zu maximieren.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
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
                        "Die Fortschrittsbalken zeigen dir an, wie gut du die Fragen in diesem Kapitel bereits beherrschst. Sie verändern sich mit deinem Fortschritt.",
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
                        "Wenn du dir sicher bist, kannst du die richtige Antwort einfach antippen. Falls deine Antwort falsch sein sollte, kannst du die anderen Antworten aufdecken, um sie zu überprüfen.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Die App merkt sich deine Antworten und wählt auf dieser Basis die nächsten Fragen aus.",
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
                        "Wenn du dir eine Frage für später merken möchtest, tippe auf den Stern.",
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
                        "Tippe auf »Frage überspringen«, wenn du eine Frage gerade nicht beantworten möchtest.",
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
                        "Wenn du genügend Fragen geübt hast, kannst du eine Prüfungssimulation starten, in der du 25 Fragen quer aus dem Fragenkatalog beantworten musst, während die Zeit läuft.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Die geschätzte Erfolgswahrscheinlichkeit ist umso höher, je mehr Fragen du geübt hast.",
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
                        "Du kannst jederzeit in den Hilfsmitteln nachschlagen, die von der Bundesnetzagentur bereitgestellt werden – so wie in der echten Prüfung auch.",
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

    int solvedQuestionCount = 0;
    for (String qid
        in (GlobalData.questions!['questions_for_hid'][hid] ?? [])) {
      if (GlobalData.box.get("t/$qid") != null) {
        solvedQuestionCount += 1;
      }
    }

    var cards = getChapterCards(hid: hid);

    Future<void> showMyDialog(BuildContext context) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Fortschritt löschen'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  (hid == ROOT_HID)
                      ? Text(
                          'Möchtest du deinen gesamten Fortschritt (${solvedQuestionCount} Antwort${solvedQuestionCount == 1 ? '' : 'en'}) löschen?')
                      : Text(
                          "Möchtest du deinen Fortschritt auf dieser Ebene (${solvedQuestionCount} Antwort${solvedQuestionCount == 1 ? '' : 'en'}) löschen?"),
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
                  await clearProgress();
                  setState(() {});
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
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(onSelected: (value) async {
            if (value == 'show_aid') {
              Navigator.of(context).pushNamed('/aid');
            } else if (value == 'clear_progress') {
              showMyDialog(context);
            } else if (value == 'feign_progress') {
              feignProgress();
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
                value: "show_aid",
                child: ListTile(
                  title: Text("Hilfsmittel"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.menu_book),
                ),
              ),
              PopupMenuItem<String>(
                enabled: solvedQuestionCount > 0,
                value: "clear_progress",
                child: const ListTile(
                  title: Text("Fortschritt löschen"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.delete),
                ),
              ),
              if (kDebugMode)
                const PopupMenuItem<String>(
                  value: "feign_progress",
                  child: ListTile(
                    title: Text("Fortschritt simulieren"),
                    visualDensity: VisualDensity.compact,
                    leading: Icon(Icons.trolley),
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: "show_intro",
                child: ListTile(
                  title: Text("Einführung wiederholen"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.restart_alt),
                ),
              ),
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
        ],
        title: Text(
            (GlobalData.questions!['headings'][hid] ?? 'Amateurfunkprüfung')),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
        child: ListView(
          children: cards,
        ),
      ),
      bottomNavigationBar: const OverviewBottomMenu(),
    );
  }
}

class OverviewBottomMenu extends StatefulWidget {
  const OverviewBottomMenu({super.key});

  @override
  State<OverviewBottomMenu> createState() => _OverviewBottomMenuState();
}

class _OverviewBottomMenuState extends State<OverviewBottomMenu> {
  @override
  Widget build(BuildContext context) {
    String hid = ROOT_HID;
    if (ModalRoute.of(context) != null) {
      hid = (ModalRoute.of(context)!.settings.arguments ?? ROOT_HID).toString();
    }

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 5)],
        color: Colors.white,
      ),
      child: Material(
        child: LayoutBuilder(builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth / 3,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/quiz', arguments: hid)
                        .then((value) {
                      setState(() {});
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.list,
                            size: ICON_SIZE,
                          ),
                        ),
                        Text(
                          "Alle ${(GlobalData.questions!['questions_for_hid'][hid] ?? []).length} Fragen\nüben",
                          style: TextStyle(height: 1.2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth / 3,
                child: InkWell(
                  onTap: GlobalData.starBox.length == 0
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushNamed('/starred')
                              .then((value) {
                            setState(() {});
                          });
                        },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Opacity(
                      opacity: GlobalData.starBox.length == 0 ? 0.5 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Icon(
                              GlobalData.starBox.length == 0
                                  ? Icons.star_border
                                  : Icons.star,
                              size: ICON_SIZE,
                            ),
                          ),
                          Text(
                            GlobalData.starBox.length == 0
                                ? "Keine gemerkten\nFragen"
                                : "Gemerkte\nFragen (${GlobalData.starBox.length})",
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth / 3,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/exam_overview');
                  },
                  child: const Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.alarm,
                            size: ICON_SIZE,
                          ),
                        ),
                        Text(
                          "Prüfungs-\nsimulation",
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
