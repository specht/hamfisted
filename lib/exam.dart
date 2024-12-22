import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class Exam extends StatefulWidget {
  const Exam({super.key});

  @override
  State<Exam> createState() => _ExamState();
}

class _ExamState extends State<Exam> with TickerProviderStateMixin {
  String? exam;
  List<String> questions = [];
  Map<String, List<int>> answers_for_question = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context) == null) {
      return Container();
    }
    if (exam == null) {
      exam = (ModalRoute.of(context)!.settings.arguments ?? '').toString();
      developer.log("Choosing exam questions for $exam!");
      for (List<dynamic> qp in GlobalData.questions!['exam_questions'][exam]) {
        qp.shuffle();
        String qid = qp[0];
        questions.add(qid);
        answers_for_question[qid] = [0, 1, 2, 3];
        answers_for_question[qid]!.shuffle();
      }
      questions.shuffle();
    }

    List<Widget> cards = [];

    for (String qid in questions) {
      cards.add(getQuestionWidget(qid));
    }

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        title: Text("Prüfungssimulation",),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
        child: ListView(
          children: cards,
        ),
      ),
      bottomNavigationBar: ExamBottomMenu(),
    );
  }
}

class ExamBottomMenu extends StatefulWidget {
  const ExamBottomMenu(
      {super.key});

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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: constraints.maxWidth / 3,
                child: const InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: ICON_SIZE,

                            child: FittedBox(
                              child: CircularProgressIndicator(
                                value: 0.7,

                                
                                
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          "18/25 Fragen beantwortet",
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
                child: const InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.cancel,
                            size: ICON_SIZE,
                          ),
                        ),
                        const Text(
                          "Prüfung abbrechen",
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
                child: const InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.check,
                            size: ICON_SIZE,
                          ),
                        ),
                        const Text(
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
