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
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Auf Grundlage deiner bisherigen Antworten ergeben sich folgende Wahrscheinlichkeiten für dich, die Prüfungen bzw. Prüfungsteile zu bestehen:",
              style: TextStyle(fontSize: 16),
            ),
          ),
          for (String exam in ['N', 'E', 'A', 'B', 'V'])
            Card(
              child: ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${examTitle[exam]}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ],
                ),
                subtitle: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: examSuccessProbability[exam]!,
                        backgroundColor: const Color(0x20000000),
                        color: PRIMARY,
                      ),
                    ),
                    Text("${(examSuccessProbability[exam]! * 100).round()}%"),
                  ],
                ),
                trailing:
                    IconButton(onPressed: () {}, icon: Icon(Icons.play_arrow)),
              ),
            ),
        ],
      ),
    );
  }
}
