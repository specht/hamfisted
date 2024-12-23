import 'data.dart';
import 'package:flutter/material.dart';

class ExamOverview extends StatefulWidget {
  const ExamOverview({super.key});

  @override
  State<ExamOverview> createState() => _ExamOverviewState();
}

class _ExamOverviewState extends State<ExamOverview> {
  @override
  Widget build(BuildContext context) {
    Map<String, double> examSuccessProbability = {};
    for (String exam in ['N', 'E', 'A', 'B', 'V']) {
      examSuccessProbability[exam] =
          GlobalData.instance.getExamSuccessProbability(exam);
    }
    const Map<String, String> examTitle = {
      'N': 'Technische Kenntnisse der Klasse N',
      'E': 'Technische Kenntnisse der Klasse E',
      'A': 'Technische Kenntnisse der Klasse A',
      'B': 'Betriebliche Kenntnisse',
      'V': 'Kenntnisse von Vorschriften',
    };
    const Map<String, String> questionCountKey = {
      'N': '2024/TN',
      'E': '2024/TE_only',
      'A': '2024/TA_only',
      'B': '2024/1',
      'V': '2024/2',
    };
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
        //         leading: Icon(Icons.delete),
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
                        Text("25 Fragen aus ${GlobalData.questions!['questions_for_hid'][questionCountKey[exam]].length}"),
                        Text("${EXAM_MINUTES[exam]} Minuten"),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: examSuccessProbability[exam]!,
                        backgroundColor: const Color(0x20000000),
                        color: PRIMARY,
                      ),
                    ),
                    Text("Geschätzte Erfolgswahrscheinlichkeit: ${(examSuccessProbability[exam]! * 100).round()}%"),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/exam', arguments: exam);
                },
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Die Prozentangaben zeigen deine momentane Wahrscheinlichkeit an, den entsprechenden Prüfungsteil zu bestehen. Die Berechnung erfolgt aufgrund deiner bisherigen Antworten im Prüfungstraining.",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, fontFamily: "Alegreya Sans"),
            ),
          ),
        ],
      ),
    );
  }
}
