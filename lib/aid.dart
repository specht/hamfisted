import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class Aid extends StatefulWidget {
  static final Aid instance = Aid._internal();
  const Aid._internal();

  factory Aid() => instance;

  @override
  State<Aid> createState() => _AidState();
}

class Bookmark {
  final int page;
  final String title;

  Bookmark(this.page, this.title);
}

class _AidState extends State<Aid> with AutomaticKeepAliveClientMixin {
  final List<Bookmark> bookmarks = [
    Bookmark(4, "Frequenzbereiche"),
    Bookmark(7, "Rufzeichenplan"),
    Bookmark(11, "IARU Bandplan 2m"),
    Bookmark(12, "IARU Bandplan 70cm"),
    Bookmark(13, "Formelsammlung"),
    Bookmark(21, "Formelzeichen, Konstanten und Tabellen"),
    Bookmark(24, "Kabeldämpfungsdiagramm Koaxialkabel"),
  ];
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<PopupMenuEntry<String>> popupMenuItems = bookmarks.map((bookmark) {
      return PopupMenuItem<String>(
        value: "bookmark_${bookmark.page}",
        child: ListTile(
          title: Text(bookmark.title),
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.bookmark_outline),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: const Text("Hilfsmittel"),
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            onSelected: (String value) async {
              if (value.startsWith("bookmark_")) {
                int page = int.parse(value.split("_")[1]);
                GlobalData.instance.aidPdfViewerController.jumpToPage(page);
              } else if (value == "save_pdf") {
                launchUrl(Uri.parse(
                    "https://www.bundesnetzagentur.de/SharedDocs/Downloads/DE/Sachgebiete/Telekommunikation/Unternehmen_Institutionen/Frequenzen/Amateurfunk/AntraegeFormulare/Hilfsmittel_12062024.pdf"));
              }
            },
            itemBuilder: (context) {
              return [
                ...popupMenuItems,
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: "save_pdf",
                  child: ListTile(
                    title: Text("Im Browser öffnen"),
                    leading: Icon(Icons.open_in_browser_outlined),
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: GlobalData.instance.aidPdfViewer,
    );
  }
}

class AidScaffold extends StatefulWidget {
  final Color? backgroundColor;
  final AppBar? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  const AidScaffold(
      {super.key,
      this.backgroundColor,
      this.appBar,
      this.body,
      this.bottomNavigationBar});

  @override
  State<AidScaffold> createState() => _AidScaffoldState();
}

class _AidScaffoldState extends State<AidScaffold> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !GlobalData.showAid,
      onPopInvokedWithResult: (didPop, result) {
        if (GlobalData.showAid) {
          setState(() {
            GlobalData.showAid = false;
          });
        } else {
          Navigator.of(context).maybePop(result);
        }
      },
      child: IndexedStack(
        index: GlobalData.showAid
            ? 1
            : 0, // This can be used to switch between different pages if needed
        children: [
          Scaffold(
            appBar: widget.appBar,
            backgroundColor: widget.backgroundColor,
            body: widget.body,
            bottomNavigationBar: widget.bottomNavigationBar,
          ),
          Aid(),
        ],
      ),
    );
  }
}
