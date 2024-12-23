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
  Map<String, List<int>> answers_index_for_question = {};
  Map<String, List<Color>> answer_color_for_question = {};
  Map<String, int> selected_answer_for_question = {};

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
      developer.log("Choosing exam questions for $exam!");
      for (List<dynamic> qp in GlobalData.questions!['exam_questions'][exam]) {
        qp.shuffle();
        String qid = qp[0];
        questions.add(qid);
        answers_index_for_question[qid] = [0, 1, 2, 3];
        answers_index_for_question[qid]!.shuffle();
        answer_color_for_question[qid] = [
          Colors.transparent,
          Colors.transparent,
          Colors.transparent,
          Colors.transparent
        ];
      }
      questions.shuffle();
    }

    List<Widget> cards = [];

    for (String qid in questions) {
      cards.add(getQuestionWidget(qid));
      // cards.add(const Divider());
      for (int ti = 0; ti < 4; ti++) {
        int i = answers_index_for_question[qid]![ti];
        cards.add(
          LayoutBuilder(builder: (context, constraints) {
            double cwidth = min(constraints.maxWidth, MAX_WIDTH);
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              surfaceTintColor: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    selected_answer_for_question[qid] = i;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected_answer_for_question[qid] == i
                          ? PRIMARY
                          : answer_color_for_question[qid]![i],
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
                                    answer_color_for_question[qid]![i] ==
                                            Colors.transparent
                                        ? Color.lerp(PRIMARY, Colors.white, 0.8)
                                        : answer_color_for_question[qid]![i],
                                radius: cwidth * 0.045,
                                child: answer_color_for_question[qid]![i] ==
                                        GREEN
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: cwidth * 0.05,
                                      )
                                    : answer_color_for_question[qid]![i] == RED
                                        ? Icon(
                                            Icons.clear,
                                            color: Colors.white,
                                            size: cwidth * 0.05,
                                          )
                                        : Text(
                                            String.fromCharCode(65 + ti),
                                            style: GoogleFonts.alegreyaSans(
                                                fontSize: cwidth * 0.04,
                                                color:
                                                    answer_color_for_question[
                                                                qid]![i] ==
                                                            Colors.transparent
                                                        ? Colors.black87
                                                        : Colors.white,
                                                fontWeight:
                                                    answer_color_for_question[
                                                                qid]![i] ==
                                                            Colors.transparent
                                                        ? FontWeight.normal
                                                        : FontWeight.bold),
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
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Prüfungssimulation",
              ),
              Text("45:00"),
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
                                value: widget.exam.selected_answer_for_question
                                        .length /
                                    25,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "${widget.exam.selected_answer_for_question.length} von 25 Fragen beantwortet",
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
