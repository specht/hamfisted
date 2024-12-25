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
      return Scaffold(
        backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
        appBar: AppBar(
          backgroundColor: PRIMARY,
          foregroundColor: Colors.white,
          title: const Text("Ergebnis der Prüfungssimulation"),
        ),
        body: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 4),
          child: ListView(
            children: [
              const Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Auswertung",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (correctCount > 0)
                Card(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Icon(Icons.check, color: GREEN, size: 20),
                    ),
                    Expanded(
                      child: Text("$correctCount Fragen korrekt beantwortet",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                )),
              if (wrongCount > 0)
                Card(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Icon(Icons.close, color: RED, size: 20),
                    ),
                    Expanded(
                      child: Text("$wrongCount Fragen falsch beantwortet",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                )),
              if (skippedCount > 0)
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Icon(Icons.help_outline,
                            color: Colors.black54, size: 20),
                      ),
                      Expanded(
                        child: Text("$skippedCount Fragen nicht beantwortet",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Ergebnis",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          radius: 16,
                          backgroundColor: examPassed
                              ? Color.lerp(GREEN, Colors.white, 0.7)
                              : Color.lerp(RED, Colors.white, 0.7),
                          child: Icon(examPassed ? Icons.check : Icons.close,
                              color: examPassed ? GREEN : RED, size: 20)),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Die Prüfung wäre somit ",
                          children: [
                            TextSpan(
                              text:
                                  examPassed ? 'bestanden' : 'nicht bestanden',
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
                  ],
                ),
              ),
              if (wrongCount > 0 || skippedCount > 0) const Divider(),
              if (wrongCount > 0 || skippedCount > 0)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Nicht oder falsch beantwortete Fragen",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              for (String qid in questions)
                if (selectedAnswerForQuestion[qid] != 0) ...[
                  getQuestionWidget(qid),
                  for (int i = 1; i < 4; i++)
                    if (selectedAnswerForQuestion[qid] != null &&
                        selectedAnswerForQuestion[qid] == i)
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
                                  horizontal: max(
                                      0,
                                      (constraints.maxWidth - cwidth) / 2 -
                                          15)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        radius: cwidth * 0.045,
                                        child: Icon(Icons.close,
                                            color: RED, size: cwidth * 0.05),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cwidth * (1.0 - 0.045) - 70,
                                    child: getAnswerWidget(qid, i),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  for (int i = 0; i < 1; i++)
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
                                horizontal: max(0,
                                    (constraints.maxWidth - cwidth) / 2 - 15)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      radius: cwidth * 0.045,
                                      child: Icon(Icons.check,
                                          color: GREEN, size: cwidth * 0.05),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cwidth * (1.0 - 0.045) - 70,
                                  child: getAnswerWidget(qid, i),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
            ],
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
                            padding: const EdgeInsets.all(8.0),
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
                    return Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
                  }),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 4),
          child: ListView(
            children: cards,
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
