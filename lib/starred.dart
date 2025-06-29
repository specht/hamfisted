import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data.dart';

class Starred extends StatefulWidget {
  const Starred({super.key});

  @override
  State<Starred> createState() => _StarredState();
}

class _StarredState extends State<Starred> {
  Future<void> showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gemerkte Fragen löschen'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Möchtest du deine gemerkten Fragen löschen?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Löschen'),
              onPressed: () async {
                await GlobalData.starBox.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    cards.add(const Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Text(
        "Anmerkung: Bei den hier angezeigten Fragen ist immer Antwort A die korrekte Antwort.",
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
          fontFamily: "Alegreya Sans",
        ),
      ),
    ));
    cards.add(const Divider());
    List<dynamic> sortedKeys = GlobalData.starBox.keys.toList();
    sortedKeys.sort((a, b) {
      const order = ['N', 'E', 'A', 'B', 'V'];
      int indexA = order.indexOf(a[5]);
      int indexB = order.indexOf(b[5]);
      if (indexA == indexB) {
        return a.compareTo(b);
      }
      return indexA.compareTo(indexB);
    });
    List<String> lastHidList = [];
    for (String qid in sortedKeys) {
      List<String> hidList = [];
      String p = GlobalData.questions!['hid_for_question'][qid];
      while (p != '') {
        hidList.add(p);
        p = GlobalData.questions!['parents'][p] ?? '';
      }
      hidList = hidList.reversed.toList();
      String hid = hidList.join(' / ');

      const Map<String, String> tr = {
        'TN': 'Technik N',
        'TE': 'Technik E',
        'TA': 'Technik A',
        '1': 'Betrieb:',
        '2': 'Vorschriften:',
      };
      for (int i = 2; i < hidList.length; i++) {
        if (hidList[i] != (i < lastHidList.length ? lastHidList[i] : '')) {
          String s = GlobalData.questions!['headings'][hidList[i]];
          if (i == 2) {
            s = "${tr[hidList[i].split('/')[1]]}: ${s}";
          }
          cards.add(Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              s,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: i == 2 ? FontWeight.bold : FontWeight.normal),
            ),
          ));
        }
      }
      lastHidList = hidList;

      String qidDisplay = qid;
      if (qidDisplay.endsWith('E') || qidDisplay.endsWith('A')) {
        qidDisplay = qidDisplay.substring(0, qidDisplay.length - 1);
      }
      qidDisplay = qidDisplay.replaceFirst('2024_', '');
      List<Widget> columnChildren = [];
      for (int i = 0; i < 4; i++) {
        columnChildren.add(
          LayoutBuilder(builder: (context, constraints) {
            double cwidth = min(constraints.maxWidth, MAX_WIDTH);
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              surfaceTintColor: Colors.transparent,
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
                          padding: const EdgeInsets.all(7.0),
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == 0
                                      ? Color.lerp(GREEN, Colors.white, 0.5)!
                                      : Colors.transparent, // Border color
                                  width: 1.5, // Border width
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: i == 0
                                    ? Color.lerp(GREEN, Colors.white, 0.7)
                                    : Color.lerp(PRIMARY, Colors.white, 0.8),
                                radius: cwidth * 0.045,
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: GoogleFonts.alegreyaSans(
                                      fontSize: cwidth * 0.04,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cwidth * (1.0 - 0.045) - 70,
                          child: getAnswerWidget(qid, i),
                        ),
                      ]),
                ),
              ),
            );
          }),
        );
      }
      Widget widget = ExpansionTile(
        shape: const Border(),
        title: getQuestionWidget(qid),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        collapsedShape: Border(),
        dense: true,
        showTrailingIcon: false,
        children: columnChildren,
      );
      cards.add(
        Dismissible(
          key: Key(qid),
          direction: DismissDirection.startToEnd,
          dismissThresholds: const {DismissDirection.startToEnd: 0.7},
          background: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.delete_outline, color: Colors.black45),
            ),
          ),
          onDismissed: (direction) {
            GlobalData.instance.unstarQuestion(qid);
            setState(() {
              if (GlobalData.starBox.keys.length == 0) {
                Navigator.of(context).pop();
              }
            });
          },
          child: widget,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(onSelected: (value) async {
            if (value == "show_aid") {
              Navigator.of(context).pushNamed('/aid');
            } else if (value == 'clear_all_stars') {
              await showMyDialog(context);
              if (GlobalData.starBox.keys.length == 0) {
                Navigator.of(context).pop();
              }
            }
          }, itemBuilder: (itemBuilder) {
            return <PopupMenuEntry>[
              const PopupMenuItem<String>(
                value: "show_aid",
                child: ListTile(
                  title: Text("Hilfsmittel"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.menu_book),
                ),
              ),
              const PopupMenuItem<String>(
                value: "clear_all_stars",
                child: ListTile(
                  title: Text("Alle gemerkten Fragen löschen"),
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.delete_outline),
                ),
              ),
            ];
          })
        ],
        title: const Text("Gemerkte Fragen"),
      ),
      body: ListView(
        children: cards,
      ),
    );
  }
}
