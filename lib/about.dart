import 'package:Hamfisted/aid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String version = "n/a";
  void getVersionInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    getVersionInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: const Text("Über diese App"),
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
      ),
      body: Html(
        data: "<h2>Hamfisted</h2>"
            "<p>App zur Vorbereitung auf die Amateurfunkprüfung</p>"
            "Die Fragen stammen von der Bundesnetzagentur (3. Auflage, März 2024). Grafiken stammen von <a href='https://freepik.com'>freepik.com</a>. Implementiert von Michael Specht, inhaltliche Beratung von Lars DO5VL.</p>"
            "<p><b>Version:</b> ${version}</p>"
            "<p><b>Quelltext:</b> <a href='https://github.com/specht/hamfisted'>https://github.com/specht/hamfisted</a></p>"
            "<p><b>Kontakt:</b> <a href='mailto:specht@gymnasiumsteglitz.de'>specht@gymnasiumsteglitz.de</a></p>",
        onLinkTap: (url, attributes, element) {
          launchUrl(Uri.parse(url!));
        },
      ),
    );
  }
}
