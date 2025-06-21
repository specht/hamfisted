import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class Aid extends StatefulWidget {
  const Aid({super.key});

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
      body: SfPdfViewer.asset(
        "assets/Hilfsmittel.pdf",
        controller: GlobalData.instance.aidPdfViewerController,
        enableTextSelection: false,
        canShowTextSelectionMenu: false,
      ),
    );
  }
}
