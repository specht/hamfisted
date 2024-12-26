import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
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
      // if (kDebugMode) qid = "2024_NB703";
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
        AnimatedBuilder(
            animation: _animationController3,
            builder: (context, child) {
              return AnimatedBuilder(
                  animation: _animationController2,
                  builder: (context, child) {
                    return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return LayoutBuilder(builder: (context, constraints) {
                            double cwidth =
                                min(constraints.maxWidth, MAX_WIDTH);
                            Offset offset = Offset.zero;
                            if (animationPhase1) {
                              if (i != 0) {
                                offset =
                                    Offset(-1 * _animationController.value, 0);
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
                              offset =
                                  Offset(1.0 - _animationController3.value, 0);
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
                                        const Duration(milliseconds: 1500), () {
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
                                        color:
                                            answerColor[i] == Colors.transparent
                                                ? Colors.transparent
                                                : Color.lerp(answerColor[i],
                                                    Colors.white, 0.5)!,
                                        width: 1.5,
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
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Color.lerp(
                                                          answerColor[i],
                                                          Colors.white,
                                                          0.5)!, // Border color
                                                      width:
                                                          1.5, // Border width
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        // Colors.transparent,
                                                        answerColor[i] ==
                                                                Colors
                                                                    .transparent
                                                            ? Color.lerp(
                                                                PRIMARY,
                                                                Colors.white,
                                                                0.9)
                                                            : Color.lerp(
                                                                answerColor[i],
                                                                Colors.white,
                                                                0.7),
                                                    radius: cwidth * 0.045,
                                                    child:
                                                        answerColor[i] == GREEN
                                                            ? Icon(
                                                                Icons.check,
                                                                color: GREEN,
                                                                size: cwidth *
                                                                    0.05,
                                                              )
                                                            : answerColor[i] ==
                                                                    RED
                                                                ? Icon(
                                                                    Icons.clear,
                                                                    color: RED,
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
                                            ),
                                            Container(
                                              width:
                                                  cwidth * (1.0 - 0.045) - 70,
                                              child: getAnswerWidget(qid!, i),
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
      body: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
        child: Stack(
          children: [
            Container(
              child: ListView(
                children: cards,
              ),
            ),
            if (solvedAll)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 10),
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      surfaceTintColor:
                          WidgetStateProperty.all(Colors.transparent),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      elevation: WidgetStateProperty.all(4),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      "Alle Fragen beantwortet!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: QuizBottomMenu(
        qid: qid!,
        feelingUnsureWidget: unsureSwitch,
        onFeelingUnsure: () {
          unsureSwitch.onChanged!(true);
          unsure = true;
        },
        onHelp: GlobalData.questions!['questions'][qid]['hint'] == null
            ? null
            : () {
                String? url = GlobalData.questions!['questions'][qid]['hint'];
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
    );
  }
}

class QuizBottomMenu extends StatefulWidget {
  final Function? onFeelingUnsure;
  final Widget feelingUnsureWidget;
  final Function? onHelp;
  final Function? onStar;
  final Function? onSkip;
  final String qid;

  const QuizBottomMenu(
      {super.key,
      required this.qid,
      required this.feelingUnsureWidget,
      this.onFeelingUnsure,
      this.onSkip,
      this.onHelp,
      this.onStar});

  @override
  State<QuizBottomMenu> createState() => _QuizBottomMenuState();
}

class _QuizBottomMenuState extends State<QuizBottomMenu> {
  @override
  Widget build(BuildContext context) {
    bool questionIsStarred = GlobalData.starBox.get(widget.qid) ?? false;
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
                child: InkWell(
                  onTap: widget.onFeelingUnsure == null
                      ? null
                      : () {
                          widget.onFeelingUnsure!();
                        },
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
                              child: widget.feelingUnsureWidget,
                            ),
                          ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            questionIsStarred ? Icons.star : Icons.star_border,
                            color:
                                questionIsStarred ? Colors.yellow[700] : null,
                            size: ICON_SIZE,
                          ),
                        ),
                        const Text(
                          "Frage für später\nmerken",
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
                  onTap: widget.onSkip == null
                      ? null
                      : () {
                          widget.onSkip!();
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
                            Icons.skip_next_outlined,
                            size: ICON_SIZE,
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
    );
  }
}
