import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const GREEN = Color(0xff73a946);
// const GRAEN = Color(0xff4aa03f);
// const GREEN = Color.fromARGB(255, 33, 142, 19);
const RED = Color(0xff992413);
const PRIMARY = Color(0xff1d5479);
const GREY = Color(0xffe0e0e0);
const double MAX_WIDTH = 400;

const double INTRO_BOTTOM = 220;
const String ROOT_HID = '2024';
const ICON_SIZE = 28.0;

List<Color> PROGRESS_COLORS = [
  Color.lerp(PRIMARY, GREY, 0 / 4)!,
  Color.lerp(PRIMARY, GREY, 1 / 4)!,
  Color.lerp(PRIMARY, GREY, 2 / 4)!,
  Color.lerp(PRIMARY, GREY, 3 / 4)!,
  Color.lerp(PRIMARY, GREY, 4 / 4)!,
];

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

const Map<String, int> EXAM_MINUTES = {
  'N': 45,
  'E': 45,
  'A': 60,
  'B': 45,
  'V': 45,
};

int timestamp() {
  return DateTime.now().millisecondsSinceEpoch;
  // return DateTime.now().millisecondsSinceEpoch + 1000 * 60 * 60 * 24 * 50;
}

class GlobalData with ChangeNotifier {
  static final GlobalData _globalData = GlobalData._internal();
  GlobalData._internal();
  static GlobalData get instance => _globalData;
  static var box;
  static var starBox;

  static bool ready = false;

  static Map<String, dynamic>? questions;

  final _initMemoizer = AsyncMemoizer<bool>();
  late final PdfViewerController aidPdfViewerController;

  Future<bool> get launchGlobalData async {
    if (ready) return true;
    bool _ready = await _initMemoizer.runOnce(() async {
      return await _init();
    });
    return _ready;
  }

  Future<bool> _init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('settings');
    starBox = await Hive.openBox('starred');

    questions = jsonDecode(await rootBundle.loadString("data/questions.json"));

    developer.log("CREATING PDF DOCUMENT VIEWER");
    aidPdfViewerController = PdfViewerController();

    ready = true;
    developer.log('[init] GlobalData ready.');

    notifyListeners();

    return ready;
  }

  int getLastReviewedForQuestion(String qid) {
    return GlobalData.box.get("t/$qid", defaultValue: 0);
    // return timestamp() -
    // Random.secure().nextInt(1000 * 60 * 60 * 24 * 30); // For testing
  }

  void setLastReviewedForQuestion(String qid, int timestamp) {
    GlobalData.box.put("t/$qid", timestamp);
  }

  int getRepetitionsForQuestion(String qid) {
    return GlobalData.box.get("r/$qid", defaultValue: 0);
    // return Random.secure().nextInt(10); // For testing
  }

  void setRepetitionsForQuestion(String qid, int repetitions) {
    GlobalData.box.put("r/$qid", repetitions);
  }

  int getIntervalForQuestion(String qid) {
    return GlobalData.box.get("i/$qid", defaultValue: 0);
    // return Random.secure().nextInt(30) + 1; // For testing
  }

  void setIntervalForQuestion(String qid, int interval) {
    GlobalData.box.put("i/$qid", interval);
  }

  double getEasinessForQuestion(String qid) {
    return GlobalData.box.get("e/$qid", defaultValue: 2.5);
  }

  void setEasinessForQuestion(String qid, double easiness) {
    GlobalData.box.put("e/$qid", easiness);
  }

  double getRetentionSpanForQuestion(String qid) {
    int interval = getIntervalForQuestion(qid);
    double easiness = getEasinessForQuestion(qid);
    return max(1.0, interval * easiness);
  }

  double getRecallProbabilityForQuestion(String qid) {
    int now = timestamp();
    int lastReviewed = getLastReviewedForQuestion(qid);
    double daysSince = (now - lastReviewed) / (1000 * 60 * 60 * 24);
    double retentionSpan = getRetentionSpanForQuestion(qid);
    return min(0.99, max(0.05, exp(-daysSince / retentionSpan)));
  }

  void questionAnsweredCorrectly(String qid) {
    int now = timestamp();
    int repetitions = getRepetitionsForQuestion(qid) + 1;
    setRepetitionsForQuestion(qid, repetitions);
    double easiness = min(max(1.3, getEasinessForQuestion(qid) + 0.1), 3.0);
    setEasinessForQuestion(qid, easiness);
    int interval = repetitions == 1
        ? 1
        : (repetitions == 2
            ? 6
            : (getIntervalForQuestion(qid) * easiness).round());
    setIntervalForQuestion(qid, interval);
    setLastReviewedForQuestion(qid, now);
  }

  void questionAnsweredWrong(String qid) {
    setRepetitionsForQuestion(qid, 0);
    double easiness = max(1.3, getEasinessForQuestion(qid) - 0.2);
    setEasinessForQuestion(qid, easiness);
    setIntervalForQuestion(qid, 1);
  }

  void starQuestion(String qid) {
    GlobalData.starBox.put(qid, true);
  }

  void unstarQuestion(String qid) {
    GlobalData.starBox.delete(qid);
  }

  double getExamSuccessProbability(String exam) {
    int now = timestamp();
    int tries = 0;
    int successes = 0;
    Random r = Random(now);
    for (int i = 0; i < 1000; i++) {
      int correct = 0;
      for (List<dynamic> block in GlobalData.questions!['exam_questions']
          [exam]) {
        String qid = block[r.nextInt(block.length)];
        double p = GlobalData.instance.getRecallProbabilityForQuestion(qid);
        if (r.nextDouble() < p) correct += 1;
      }
      tries += 1;
      if (correct >= 19) successes += 1;
    }
    return successes / tries;
  }
}

int getDueTimestampForQuestion(String qid) {
  int lastReviewed = GlobalData.instance.getLastReviewedForQuestion(qid);
  double retentionSpan = GlobalData.instance.getRetentionSpanForQuestion(qid);
  return lastReviewed + (retentionSpan * 1000 * 60 * 60 * 24).round();
}

Widget getQuestionWidget(String qid) {
  String qidDisplay = qid;
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
      challengeParts.add(Container(
        constraints: BoxConstraints(maxWidth: cwidth),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            "data/2024/${GlobalData.questions!['questions'][qid]['challenge_svg']}",
            width: width,
            height: height,
          ),
        ),
      ));
    }

    if (GlobalData.questions!['questions'][qid]['challenge_png'] != null) {
      challengeParts.add(Container(
        constraints: BoxConstraints(maxWidth: cwidth),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image(
            image: AssetImage(
              "data/2024/${GlobalData.questions!['questions'][qid]['challenge_png']}",
            ),
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

Widget getAnswerWidget(String qid, int i) {
  return LayoutBuilder(builder: (context, constraints) {
    double cwidth = min(constraints.maxWidth, MAX_WIDTH);
    return (GlobalData.questions!['questions'][qid]['answers_tex'] == null &&
            GlobalData.questions!['questions'][qid]['answers_svg'] == null)
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 13.0),
            child: Html(
              data: GlobalData.questions!['questions'][qid]['answers'][i]
                  .toString()
                  .replaceAll('*', ' ⋅ '),
              style: {
                'body': Style(
                  margin: Margins.zero,
                ),
              },
            ),
          )
        : (GlobalData.questions!['questions'][qid]['answers_svg'] == null
            ? LayoutBuilder(builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxWidth /
                          GlobalData.questions!['questions'][qid]
                              ['answers_tex_width'][i] *
                          GlobalData.questions!['questions'][qid]
                              ['answers_tex_height'][i],
                      child: FutureBuilder(
                          future: ScalableImage.fromSIAsset(rootBundle,
                              "data/2024/tex/${GlobalData.questions!['questions'][qid]['answers_tex'][i]}.si"),
                          builder: (context, snapshot) {
                            return ScalableImageWidget(
                              si: snapshot.requireData,
                            );
                          })),
                );
              })
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SvgPicture.asset(
                  "data/2024/${GlobalData.questions!['questions'][qid]['answers_svg'][i]}",
                  width: cwidth * 0.86,
                ),
              ));
  });
}

class ListWithDecay {
  ListWithDecay(this.decay);
  int decay = 0;
  List<String> entries = [];
}

class ProgressBarForHid extends StatefulWidget {
  final String hid;
  final bool demo;
  const ProgressBarForHid({super.key, required this.hid, this.demo = false});

  @override
  State<ProgressBarForHid> createState() => _ProgressBarForHidState();
}

class _ProgressBarForHidState extends State<ProgressBarForHid> {
  List<int> countForDuration = [0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    countForDuration = [0, 0, 0, 0, 0];
    if (widget.demo) {
      Random r = Random(0);
      countForDuration = [10, 13, 9, 2, 28];
      countForDuration.shuffle(r);
    } else {
      for (String qid
          in (GlobalData.questions!['questions_for_hid'][widget.hid] ?? [])) {
        int slot = 4;
        double p = GlobalData.instance.getRecallProbabilityForQuestion(qid);
        if (p > 0.2) slot = 3;
        if (p > 0.4) slot = 2;
        if (p > 0.6) slot = 1;
        if (p > 0.8) slot = 0;
        countForDuration[slot] += 1;
      }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (int k = 0; k <= 4; k++)
        if (countForDuration[k] > 0)
          Flexible(
            flex: countForDuration[k],
            child: LinearProgressIndicator(
              backgroundColor: const Color(0x10000000),
              color: PROGRESS_COLORS[k],
              value: 1.0,
            ),
          ),
    ]);
  }
}
