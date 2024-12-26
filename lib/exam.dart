import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jovial_svg/jovial_svg.dart';

import 'data.dart';

class Exam extends StatefulWidget {
  const Exam({super.key});

  @override
  State<Exam> createState() => _ExamState();
}

class _ExamState extends State<Exam> with TickerProviderStateMixin {
  String? exam;
  List<String> questions = [];
  Map<String, List<int>> answersIndexForQuestion = {};
  Map<String, int> selectedAnswerForQuestion = {};
  Map<String, GlobalKey> globalKeyForQuestion = {};
  bool timeout = false;
  bool showResults = false;
  bool calculatedResults = false;
  int secondsLeft = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int skippedCount = 0;
  bool examPassed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showPopConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Prüfung abbrechen'),
          content: const Text('Möchtest du die Prüfung wirklich abbrechen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Nein'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result == true) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context) == null) {
      return Container();
    }
    if (exam == null) {
      exam = (ModalRoute.of(context)!.settings.arguments ?? '').toString();
      secondsLeft = EXAM_MINUTES[exam]! * 60;
      developer.log("Choosing exam questions for $exam!");
      for (List<dynamic> qp in GlobalData.questions!['exam_questions'][exam]) {
        qp.shuffle();
        String qid = qp[0];
        questions.add(qid);
        answersIndexForQuestion[qid] = [0, 1, 2, 3];
        answersIndexForQuestion[qid]!.shuffle();
        globalKeyForQuestion[qid] = GlobalKey();

        // if (kDebugMode) {
        //   Random r = Random();
        //   if (r.nextDouble() < 0.8) {
        //     selectedAnswerForQuestion[qid] = 0; // r.nextInt(4);
        //   }
        //   showResults = true;
        // }
      }
      questions.shuffle();
    }

    List<Widget> cards = [];

    if (showResults) {
      if (!calculatedResults) {
        calculatedResults = true;
        for (String qid in questions) {
          if (selectedAnswerForQuestion[qid] == null) {
            skippedCount++;
            GlobalData.instance.unmarkQuestionSolved(qid);
          } else if (selectedAnswerForQuestion[qid]! == 0) {
            correctCount++;
            GlobalData.instance
                .markQuestionSolved(qid, DateTime.now().millisecondsSinceEpoch);
          } else {
            wrongCount++;
            GlobalData.instance.unmarkQuestionSolved(qid);
          }
        }
        examPassed = correctCount >= 19;
      }
      const List<String> stateLabel = ['Korrekt', 'Falsch', 'Nicht'];
      const List<Icon> stateIcon = [
        Icon(Icons.check, color: GREEN, size: 20),
        Icon(Icons.close, color: RED, size: 20),
        Icon(Icons.help_outline, color: Colors.black54, size: 20),
      ];

      return Scaffold(
        backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
        appBar: AppBar(
          backgroundColor: PRIMARY,
          foregroundColor: Colors.white,
          title: const Text("Ergebnis der Prüfungssimulation"),
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // Remove the divider color
          ),
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 4),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Auswertung",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...[
                  for (int state = 0; state < 3; state++)
                    if ((state == 0
                            ? correctCount
                            : state == 1
                                ? wrongCount
                                : skippedCount) >
                        0)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        childrenPadding: const EdgeInsets.all(0),
                        showTrailingIcon: false,
                        title: Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: stateIcon[state],
                              ),
                              Expanded(
                                child: Text.rich(
                                    TextSpan(
                                      text:
                                          "${stateLabel[state]} beantwortet: ",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text:
                                              "${state == 0 ? correctCount : state == 1 ? wrongCount : skippedCount} Frage${(state == 0 ? correctCount : state == 1 ? wrongCount : skippedCount) == 1 ? '' : 'n'}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: Icon(
                                  Icons.expand_more, // Trailing icon
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          for (String qid in questions)
                            if ((state == 0 &&
                                    selectedAnswerForQuestion[qid] == 0) ||
                                (state == 1 &&
                                    selectedAnswerForQuestion[qid] != null &&
                                    selectedAnswerForQuestion[qid] != 0) ||
                                (state == 2 &&
                                    selectedAnswerForQuestion[qid] ==
                                        null)) ...[
                              const Divider(),
                              Stack(
                                children: [
                                  Column(
                                    children: [
                                      LayoutBuilder(
                                        key: globalKeyForQuestion[qid],
                                        builder: (context, constraints) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (globalKeyForQuestion[qid]!
                                                    .currentContext !=
                                                null) {
                                              setState(() {});
                                            }
                                          });
                                          return Container(
                                            child: getQuestionWidget(qid),
                                          );
                                        },
                                      ),
                                      for (int i = 1; i < 4; i++)
                                        if (selectedAnswerForQuestion[qid] !=
                                                null &&
                                            selectedAnswerForQuestion[qid] == i)
                                          LayoutBuilder(
                                              builder: (context, constraints) {
                                            double cwidth = min(
                                                constraints.maxWidth,
                                                MAX_WIDTH);
                                            return Card(
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              surfaceTintColor:
                                                  Colors.transparent,
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(7.0),
                                                        child: Center(
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            radius:
                                                                cwidth * 0.045,
                                                            child: Icon(
                                                                Icons.close,
                                                                color: RED,
                                                                size: cwidth *
                                                                    0.05),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: cwidth *
                                                                (1.0 - 0.045) -
                                                            70,
                                                        child: getAnswerWidget(
                                                            qid, i),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                      for (int i = 0; i < 1; i++)
                                        LayoutBuilder(
                                            builder: (context, constraints) {
                                          double cwidth = min(
                                              constraints.maxWidth, MAX_WIDTH);
                                          return Card(
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            surfaceTintColor:
                                                Colors.transparent,
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
                                                          const EdgeInsets.all(
                                                              7.0),
                                                      child: Center(
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          radius:
                                                              cwidth * 0.045,
                                                          child: Icon(
                                                              Icons.check,
                                                              color: GREEN,
                                                              size: cwidth *
                                                                  0.05),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: cwidth *
                                                              (1.0 - 0.045) -
                                                          70,
                                                      child: getAnswerWidget(
                                                          qid, i),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                  if (globalKeyForQuestion[qid]!
                                          .currentContext !=
                                      null)
                                    Positioned(
                                      top: globalKeyForQuestion[qid]!
                                              .currentContext!
                                              .findRenderObject()!
                                              .paintBounds
                                              .height -
                                          20,
                                      right: 0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black45,
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: Color.lerp(
                                              PRIMARY, Colors.white, 0.9),
                                          child: IconButton(
                                            color:
                                                (GlobalData.starBox.get(qid) ??
                                                        false)
                                                    ? Colors.yellow[700]
                                                    : null,
                                            icon: Icon(
                                                (GlobalData.starBox.get(qid) ??
                                                        false)
                                                    ? Icons.star
                                                    : Icons.star_border),
                                            onPressed: () {
                                              setState(() {
                                                bool questionIsStarred =
                                                    GlobalData.starBox
                                                            .get(qid) ??
                                                        false;
                                                if (questionIsStarred) {
                                                  GlobalData.instance
                                                      .unstarQuestion(qid);
                                                } else {
                                                  GlobalData.instance
                                                      .starQuestion(qid);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              )
                            ],
                        ],
                      ),
                ],
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Ergebnis",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                            radius: 16,
                            backgroundColor: examPassed
                                ? Color.lerp(GREEN, Colors.white, 0.7)
                                : Color.lerp(RED, Colors.white, 0.7),
                            child: Icon(examPassed ? Icons.check : Icons.close,
                                color: examPassed ? GREEN : RED, size: 20)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text.rich(
                            TextSpan(
                              text: "Die Prüfung wäre somit ",
                              children: [
                                TextSpan(
                                  text: examPassed
                                      ? 'bestanden'
                                      : 'nicht bestanden',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: ".",
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Benötigte Zeit",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 16,
                          child: Icon(Icons.alarm,
                              size: 20, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text.rich(
                            TextSpan(
                              text: "Du hast ",
                              children: [
                                TextSpan(
                                  text:
                                      "${((EXAM_MINUTES[exam]! * 60 - secondsLeft) / 60.0).ceil()} Minute${(((EXAM_MINUTES[exam]! * 60 - secondsLeft) / 60.0).ceil()) == 1 ? '' : 'n'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: " benötigt.",
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (String qid in questions) {
      cards.add(getQuestionWidget(qid));
      // cards.add(const Divider());
      for (int ti = 0; ti < 4; ti++) {
        int i = answersIndexForQuestion[qid]![ti];
        cards.add(
          LayoutBuilder(builder: (context, constraints) {
            double cwidth = min(constraints.maxWidth, MAX_WIDTH);
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              surfaceTintColor: Colors.transparent,
              child: InkWell(
                onTap: timeout
                    ? null
                    : () {
                        setState(() {
                          selectedAnswerForQuestion[qid] = i;
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedAnswerForQuestion[qid] == i
                          ? PRIMARY
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
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
                                    selectedAnswerForQuestion[qid] == i
                                        ? Color.lerp(PRIMARY, Colors.white, 0.7)
                                        : Color.lerp(
                                            PRIMARY, Colors.white, 0.8),
                                radius: cwidth * 0.045,
                                child: Text(
                                  String.fromCharCode(65 + ti),
                                  style: GoogleFonts.alegreyaSans(
                                      fontSize: cwidth * 0.04,
                                      color: Colors.black87,
                                      fontWeight:
                                          selectedAnswerForQuestion[qid] == i
                                              ? FontWeight.bold
                                              : FontWeight.normal),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: cwidth * (1.0 - 0.045) - 70,
                            child: getAnswerWidget(qid, i),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }
      cards.add(const Divider());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) =>
          {if (!didPop) showPopConfirmationDialog()},
      child: Scaffold(
        backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
        appBar: AppBar(
          backgroundColor: PRIMARY,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Prüfungssimulation"),
              TweenAnimationBuilder<Duration>(
                  duration: Duration(seconds: EXAM_MINUTES[exam]! * 60 + 1),
                  tween: Tween(
                      begin: Duration(seconds: EXAM_MINUTES[exam]! * 60 + 1),
                      end: Duration.zero),
                  onEnd: () {
                    setState(() {
                      timeout = true;
                    });
                  },
                  builder:
                      (BuildContext context, Duration value, Widget? child) {
                    final minutes = value.inMinutes;
                    final seconds = value.inSeconds % 60;
                    secondsLeft = value.inSeconds;
                    return Row(
                      children: [
                        SizedBox(
                            width: 25,
                            child: Align(
                                alignment: Alignment.centerRight,
                                child:
                                    Text(minutes.toString().padLeft(2, '0')))),
                        const Text(':'),
                        SizedBox(
                            width: 25,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child:
                                    Text(seconds.toString().padLeft(2, '0')))),
                      ],
                    );
                  }),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 4),
          child: Scrollbar(
            child: ListView(
              children: cards,
            ),
          ),
        ),
        bottomNavigationBar: ExamBottomMenu(exam: this),
      ),
    );
  }
}

class ExamBottomMenu extends StatefulWidget {
  _ExamState exam;
  ExamBottomMenu({required this.exam, super.key});

  @override
  State<ExamBottomMenu> createState() => _ExamBottomMenuState();
}

class _ExamBottomMenuState extends State<ExamBottomMenu> {
  @override
  Widget build(BuildContext context) {
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
                  onTap: () => widget.exam.showPopConfirmationDialog(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.cancel_outlined,
                            size: ICON_SIZE,
                          ),
                        ),
                        const Text(
                          "Prüfung\nabbrechen",
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
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: ICON_SIZE,
                            child: FittedBox(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.black12,
                                value: widget
                                        .exam.selectedAnswerForQuestion.length /
                                    25,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "${widget.exam.selectedAnswerForQuestion.length} von 25 Fragen beantwortet",
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
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Prüfungbogen abgeben'),
                          content: const Text(
                              'Möchtest du den Prüfungsbogen jetzt abgeben?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text('Nein'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text('Ja'),
                            ),
                          ],
                        );
                      },
                    ).then((result) {
                      if (result == true) {
                        setState(() {
                          widget.exam.showResults = true;
                        });
                      }
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.check,
                            size: ICON_SIZE,
                          ),
                        ),
                        Text(
                          "Prüfungsbogen abgeben",
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
