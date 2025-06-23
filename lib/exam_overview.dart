import 'data.dart';
import 'package:flutter/material.dart';

class ExamOverview extends StatefulWidget {
  const ExamOverview({super.key});

  @override
  State<ExamOverview> createState() => _ExamOverviewState();
}

class _ExamOverviewState extends State<ExamOverview> {
  Map<String, double> examSuccessProbability = {};

  void recalculateProbabilities() {
    for (String exam in ['N', 'E', 'A', 'B', 'V']) {
      examSuccessProbability[exam] =
          GlobalData.instance.getExamSuccessProbability(exam);
    }
  }

  @override
  Widget build(BuildContext context) {
    recalculateProbabilities();
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        // actions: [
        // PopupMenuButton(onSelected: (value) async {
        //   if (value == 'clear_all_stars') {
        //     await showMyDialog(context);
        //     if (GlobalData.starBox.keys.length == 0) {
        //       Navigator.of(context).pop();
        //     }
        //   }
        // }, itemBuilder: (itemBuilder) {
        //   return <PopupMenuEntry>[
        //     const PopupMenuItem<String>(
        //       value: "clear_all_stars",
        //       child: ListTile(
        //         title: Text("Alle gemerkten Fragen löschen"),
        //         visualDensity: VisualDensity.compact,
        //         leading: Icon(Icons.delete_outline),
        //       ),
        //     ),
        //   ];
        // })
        // ],
        title: const Text("Prüfungssimulation"),
      ),
      body: ListView(
        children: [
          for (String exam in ['N', 'E', 'A', 'B', 'V'])
            Card(
              child: ListTile(
                title: Text(
                  "${examTitle[exam]}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            "25 Fragen aus ${GlobalData.questions!['questions_for_hid'][questionCountKey[exam]].length}"),
                        Text("${EXAM_MINUTES[exam]} Minuten"),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: ProgressBarForHid(hid: questionCountKey[exam]!),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Geschätzte Erfolgswahrscheinlichkeit: "),
                        Text(
                          "${(examSuccessProbability[exam]! * 100).round()}%",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context)
                      .pushNamed('/exam', arguments: exam)
                      .then((_) => setState(() {
                            recalculateProbabilities();
                          }));
                },
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 0),
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
    );
  }
}
