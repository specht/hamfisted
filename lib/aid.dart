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
  final Map<String, MemoryImage> _previewCache = {};

  @override
  void initState() {
    super.initState();

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

  // Future<MemoryImage> renderPreviewImage({
  //   required ScalableImage dag,
  //   required double width,
  // }) async {
  //   width = (210.0 / 25.4) * 72.0;
  //   int scale = 1;
  //   final int pixelWidth = width.round();
  //   final int pixelHeight = (pixelWidth * 297 / 210).round(); // A4 aspect ratio

  //   final recorder = ui.PictureRecorder();
  //   final canvas = Canvas(recorder);
  //   canvas.scale(scale.toDouble());

  //   dag.paint(canvas);

  //   final picture = recorder.endRecording();
  //   final img = await picture.toImage(pixelWidth * scale, pixelHeight * scale);
  //   final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

  //   return MemoryImage(byteData!.buffer.asUint8List());
  // }

  void _goToPage(int page) {
    const double targetScale = 1.0;
    final double pageHeight = _pageHeight;
    final double totalHeight =
        GlobalData.instance.aidScalableImages.length * pageHeight;
    final double pageTop = (page - 1) * pageHeight;

    double translateY;
    if (pageHeight < containerHeight) {
      translateY = (containerHeight - pageHeight) / 2 - pageTop;
    } else {
      translateY = -pageTop;
    }

    if (translateY < containerHeight - totalHeight) {
      translateY = containerHeight - totalHeight;
    } else if (translateY > 0.0) {
      translateY = 0.0;
    }

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
    const verticalPadding = 8.0 * 2;
    final pageWidth = MediaQuery.of(context).size.width - 16.0;
    final height = pageWidth / aspectRatio;
    return height + verticalPadding;
  }

  // Widget _buildPage(int index, double width, double dpr) {
  //   final key = '$index@${dpr.toStringAsFixed(2)}';

  //   return FutureBuilder<MemoryImage>(
  //     future: _previewCache.containsKey(key)
  //         ? Future.value(_previewCache[key])
  //         : renderPreviewImage(
  //                 dag: GlobalData.instance.aidScalableImages[index],
  //                 width: width * dpr)
  //             .then((img) {
  //             _previewCache[key] = img;
  //             return img;
  //           }),
  //     builder: (context, snapshot) {
  //       // if (snapshot.connectionState == ConnectionState.waiting) {
  //       // return const Center(child: CircularProgressIndicator());
  //       // }

  //       double previewOpacity = 1.0 - (currentScale - 1.5).clamp(0.0, 1.0);
  //       double svgOpacity = (currentScale - 1.2).clamp(0.0, 1.0);

  //       return Stack(children: [
  //         Opacity(
  //           opacity: previewOpacity,
  //           child: Image(
  //             image: snapshot.data!,
  //             width: width,
  //             height: _pageHeight,
  //             fit: BoxFit.cover,
  //           ),
  //         ),
  //         Opacity(
  //           opacity: svgOpacity,
  //           child: ScalableImageWidget(
  //               si: GlobalData.instance.aidScalableImages[index],
  //               isComplex: true),
  //         ),
  //       ]);
  //     },
  //   );
  // }

  Widget _buildPage(int index, double width, double dpr) {
    double previewOpacity = 1.0 - (currentScale - 1.5).clamp(0.0, 1.0);
    double svgOpacity = (currentScale - 1.2).clamp(0.0, 1.0);

    return Stack(children: [
      Opacity(
        opacity: previewOpacity,
        child: Image.asset(
          "assets/hilfsmittel-${index + 1}-72.jpg",
          width: width,
          height: _pageHeight,
          fit: BoxFit.cover,
        ),
      ),
      Opacity(
        opacity: svgOpacity,
        child: ScalableImageWidget(
            si: GlobalData.instance.aidScalableImages[index], isComplex: true),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (GlobalData.instance.aidScalableImages.length < 24) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Color.lerp(PRIMARY, Colors.white, 0.9),
      appBar: AppBar(
        title: const Text("Hilfsmittel"),
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
          final double devicePixelRatio =
              MediaQuery.of(context).devicePixelRatio;
          int size = (containerWidth * devicePixelRatio).toInt() *
              (containerHeight * devicePixelRatio).toInt() *
              4;
          developer.log(
            "Container size: ${constraints.maxWidth} x ${constraints.maxHeight}, DPR: $devicePixelRatio, bytes: $size",
            name: "Aid",
          );
          return InteractiveViewer(
            transformationController: _transformationController,
            maxScale: 5,
            minScale: 1,
            panEnabled: true,
            constrained: false,
            onInteractionUpdate: (details) {
              final matrix = _transformationController.value;
              setState(() {
                currentScale = matrix.getMaxScaleOnAxis();
              });
            },
            onInteractionEnd: (details) {
              final matrix = _transformationController.value;
              final double scale = matrix.getMaxScaleOnAxis();
              final double translateX = matrix.getTranslation().x;
              final double translateY = matrix.getTranslation().y;
              GlobalData.configBox.put('aid_scale', scale);
              GlobalData.configBox.put('aid_x', translateX);
              GlobalData.configBox.put('aid_y', translateY);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
                maxHeight: double.infinity,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    for (int i = 0; i < 24; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: AspectRatio(
                          aspectRatio: 210 / 297,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildPage(
                                i, containerWidth - 16, devicePixelRatio),
                            // child: Stack(
                            //   children: [
                            //     // Image(
                            //     //   image: GlobalData.instance.previewImages[i]!,
                            //     // ),
                            //     ScalableImageWidget(
                            //       si: GlobalData.instance.aidScalableImages[i],
                            //       isComplex: true,
                            //     ),
                            //   ],
                            // ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
