import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

class Bookmark {
  final int page;
  final String title;

  Bookmark(this.page, this.title);
}

class Aid extends StatefulWidget {
  const Aid({super.key});

  @override
  State<Aid> createState() => _AidState();
}

class _AidState extends State<Aid>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TransformationController _transformationController =
      TransformationController();

  final List<Bookmark> bookmarks = [
    Bookmark(4, "Frequenzbereiche"),
    Bookmark(7, "Rufzeichenplan"),
    Bookmark(11, "IARU Bandplan 2m"),
    Bookmark(12, "IARU Bandplan 70cm"),
    Bookmark(13, "Formelsammlung"),
    Bookmark(21, "Formelzeichen, Konstanten und Tabellen"),
    Bookmark(24, "Kabeldämpfungsdiagramm Koaxialkabel"),
  ];

  double containerWidth = 100.0;
  double containerHeight = 100.0;
  double currentScale = 1.0;
  double currentTransformY = 0.0;
  final Map<String, MemoryImage> _previewCache = {};

  @override
  void initState() {
    super.initState();

    _transformationController.addListener(() {
      final matrix = _transformationController.value;
      setState(() {
        currentScale = matrix.getMaxScaleOnAxis();
        currentTransformY = matrix.getTranslation().y;
      });
    });

    setState(() {
      double scale = GlobalData.configBox.get('aid_scale', defaultValue: 1.0);
      currentScale = scale;
      double translateX = GlobalData.configBox.get('aid_x', defaultValue: 0.0);
      double translateY = GlobalData.configBox.get('aid_y', defaultValue: 0.0);
      _transformationController.value = Matrix4.identity()
        ..scale(scale)
        ..translate(translateX / scale, translateY / scale);
    });
  }

  void _goToPage(int page) {
    const double targetScale = 1.0;
    final double pageHeight = _pageHeight;
    final double totalHeight = 24 * pageHeight + 8;
    final double pageTop = (page - 1) * pageHeight;
    developer.log(
      "Go to page $page, height: $pageHeight, total: $totalHeight, top: $pageTop",
      name: "Aid._goToPage",
    );

    double translateY;
    if (pageHeight < containerHeight) {
      translateY = (containerHeight - pageHeight) / 2 - pageTop;
    } else {
      translateY = -pageTop;
    }
    translateY -= 16.0;

    if (translateY < containerHeight - totalHeight) {
      translateY = containerHeight - totalHeight;
    } else if (translateY > 0.0) {
      translateY = 0.0;
    }

    // translateY = 0.0;

    final Matrix4 targetTransform = Matrix4.identity()
      ..scale(targetScale)
      ..translate(0.0, translateY);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetTransform,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    controller.forward();
  }

  @override
  bool get wantKeepAlive => true;

  double get _pageHeight {
    const aspectRatio = 210 / 297;
    const verticalPadding = 8.0;
    final pageWidth = MediaQuery.of(context).size.width - 16.0;
    final height = pageWidth / aspectRatio;
    return height + verticalPadding;
  }

  Widget _buildPage(int index, double width, double dpr) {
    double previewOpacity = 1.0 - (currentScale - 1.5).clamp(0.0, 1.0);
    double svgOpacity = (currentScale - 1.2).clamp(0.0, 1.0);

    return Stack(children: [
      Opacity(
        opacity: previewOpacity,
        child: Image.asset(
          "assets/hilfsmittel-${index + 1}-150.jpg",
        ),
      ),
      Opacity(
        opacity: svgOpacity,
        child: Image.asset(
          "assets/hilfsmittel-${index + 1}-300.jpg",
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: Text(
            "Hilfsmittel ${(currentTransformY / currentScale).toStringAsFixed(2)}"),
        backgroundColor: PRIMARY,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value.startsWith("bookmark_")) {
                int page = int.parse(value.split("_")[1]);
                _goToPage(page);
              } else if (value == "save_pdf") {
                launchUrl(Uri.parse(
                  "https://www.bundesnetzagentur.de/SharedDocs/Downloads/DE/Sachgebiete/Telekommunikation/Unternehmen_Institutionen/Frequenzen/Amateurfunk/AntraegeFormulare/Hilfsmittel_12062024.pdf",
                ));
              }
            },
            itemBuilder: (context) {
              return [
                ...bookmarks.map((b) => PopupMenuItem<String>(
                      value: "bookmark_${b.page}",
                      child: ListTile(
                        title: Text(b.title),
                        leading: const Icon(Icons.bookmark_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          containerWidth = constraints.maxWidth;
          containerHeight = constraints.maxHeight;
          double upperLimit =
              (containerHeight * (-0.1) - currentTransformY) / currentScale;
          double lowerLimit = (containerHeight -
                  currentTransformY -
                  10 -
                  containerHeight * (-0.1)) /
              currentScale;
          final double devicePixelRatio =
              MediaQuery.of(context).devicePixelRatio;
          return InteractiveViewer(
            transformationController: _transformationController,
            maxScale: 5,
            minScale: 1,
            panEnabled: true,
            constrained: false,
            onInteractionEnd: (details) {
              final matrix = _transformationController.value;
              final double scale = matrix.getMaxScaleOnAxis();
              final double translateX = matrix.getTranslation().x;
              final double translateY = matrix.getTranslation().y;
              GlobalData.configBox.put('aid_scale', scale);
              GlobalData.configBox.put('aid_x', translateX);
              GlobalData.configBox.put('aid_y', translateY);
            },
            child: SizedBox(
              width: containerWidth,
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    24,
                    (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            top: index == 0 ? 8 : 0,
                            bottom: 8,
                            left: 8,
                            right: 8),
                        child: AspectRatio(
                          aspectRatio: 210 / 297,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: (_pageHeight * index + 8 > lowerLimit ||
                                    _pageHeight * (index + 1) < upperLimit)
                                ? Container()
                                : _buildPage(
                                    index, containerWidth, devicePixelRatio),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
