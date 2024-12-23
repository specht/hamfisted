import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:Hamfisted/data.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jovial_svg/jovial_svg.dart';

const GREEN = Color(0xff73a946);
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
  'N': 1,
  'E': 45,
  'A': 60,
  'B': 45,
  'V': 45,
};

int timestamp() {
  return DateTime.now().millisecondsSinceEpoch;
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

    ready = true;
    developer.log('[init] GlobalData ready.');

    notifyListeners();

    return ready;
  }

  void markQuestionSolved(String qid, int timestamp) {
    GlobalData.box.put("t/$qid", timestamp);
  }

  void unmarkQuestionSolved(String qid) {
    GlobalData.box.delete("t/$qid");
  }

  void starQuestion(String qid) {
    GlobalData.starBox.put(qid, true);
  }

  void unstarQuestion(String qid) {
    GlobalData.starBox.delete(qid);
  }

  double getExamSuccessProbability(String exam) {
    int now = DateTime.now().millisecondsSinceEpoch;
    int tries = 0;
    int successes = 0;
    Random r = Random(now);
    for (int i = 0; i < 1000; i++) {
      int correct = 0;
      for (List<dynamic> block in GlobalData.questions!['exam_questions']
          [exam]) {
        String qid = block[r.nextInt(block.length)];
        int ts = GlobalData.box.get("t/$qid") ?? 0;
        int diff = now - ts;
        // model exponential decay over time:
        // - 95% after 0 days
        // - 61% after 7 days
        // - 52% after 14 days
        // - 48% after 21 days
        // - 45% after 28 days
        double days = diff / (1000.0 * 60 * 60 * 24);
        double p = (pow(days * 0.5 + 1.0, -0.4) * 0.75 + 0.2).toDouble();
        if (r.nextDouble() < p) correct += 1;
      }
      tries += 1;
      if (correct >= 19) successes += 1;
    }
    return successes / tries;
  }
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

class ListWithDecay {
  ListWithDecay(this.decay);
  int decay = 0;
  List<String> entries = [];
}
