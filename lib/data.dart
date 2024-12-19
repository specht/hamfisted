import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

const int maxDecay = 28;

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
        double p = (diff < 1000 * 60 * 60 * 24 * 21) ? 0.95 : 0.25;
        if (r.nextDouble() < p) correct += 1;
      }
      tries += 1;
      if (correct >= 19) successes += 1;
    }
    return successes / tries;
  }
}
