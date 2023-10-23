import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

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
}
