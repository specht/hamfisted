import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'about.dart';
import 'data.dart';
import 'exam.dart';
import 'exam_overview.dart';
import 'overview.dart';
import 'quiz.dart';
import 'starred.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalData.instance.launchGlobalData;
  runApp(ChangeNotifierProvider<GlobalData>.value(
      value: GlobalData.instance, child: const Hamfisted()));
}

class Hamfisted extends StatelessWidget {
  const Hamfisted({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      title: 'Amateurfunkprüfung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: PRIMARY,
        ),
        textTheme: GoogleFonts.alegreyaSansTextTheme(textTheme),
      ),
      home: const Overview(),
      routes: {
        '/overview': (context) => const Overview(),
        '/quiz': (context) => const Quiz(),
        '/starred': (context) => const Starred(),
        '/exam_overview': (context) => const ExamOverview(),
        '/exam': (context) => const Exam(),
        '/about': (context) => const About(),
      },
    );
  }
}
