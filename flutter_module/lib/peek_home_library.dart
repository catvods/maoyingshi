import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:rfw/rfw.dart';

import 'theme_design.dart';

/// The `peek.home` local widget library: the thirteen custom widgets
/// the ported PeekPro home themes import next to `core.widgets`. The
/// themes are declarative RFW text (assets/peek_home); everything
/// stateful or platform-bound lives here, implemented against the
/// B11/B12 home data the bridge in themed_home.dart feeds in.
///
/// The four shape widgets (ClipPath, RotatedBox, Transform,
/// CustomPaint) fill the gaps RFW's core library leaves: core
/// registers only 39 widgets and has no arbitrary clip, rotation,
/// transform or custom painting, so themes that need a true polygon
/// or a Bezier curve use these instead of approximating with
/// borderRadius.
///
/// The themes pass no event handlers into these widgets; the two
/// behaviours that need to reach back into the bridge (carousel page
/// changes for the immersive palette, grid end-of-scroll for paging)
/// go through [PeekHomeHooks], which the bridge installs while the
/// themed home is mounted.
class PeekHomeHooks {
  /// PeekCarousel with `syncImmersivePalette: true` reports its page.
  static void Function(int index)? onCarouselPage;

  /// PeekStickyGrid reports scrolling near the end of the grid.
  static VoidCallback? onGridEndReached;

  /// The active theme's title font family (a bundled family name
  /// — 'NotoSerifSC' / 'LXGWWenKaiLite' — 'monospace', or null
  /// for the default sans). The bridge sets it from the theme's
  /// meta while the themed home is mounted; the caption widgets
  /// below render item titles with it.
  static String? titleFontFamily;

  /// The active theme's design-layer parameters (theme_design.
  /// dart), set by the bridge alongside [titleFontFamily]. The
  /// carousel reads the design style's poster treatment from it.
  static ThemeDesignParams? designParams;

  /// The native-design recommend section (LeeCat's native design
  /// home): for themes whose design layer renders recommend as a
  /// titled section below the filter area (meta nativeDesign),
  /// the bridge sets the items here and PeekStickyGrid renders
  /// them as a sliver between the pinned header and the grid.
  /// Null (or empty) = no section — the RFW template's hero
  /// carousel is the recommend presentation, as before.
  static List<PeekRecommendItem>? recommendSection;

  /// Tap on a native recommend-section item: the bridge routes
  /// it to the same host call as the template's "openRecommend"
  /// event (B12 openBannerItem).
  static void Function(int index)? onRecommendTap;

  /// The native Feature hero replaces the template's hero
  /// carousel when the bridge sets it: every native-design
  /// style's hero is its own Feature panel, recovered verbatim
  /// from the design layer's embedded RFW fragments (see
  /// _NativeFeature). PeekStickyGrid renders the Feature as
  /// the top sliver when this is true.
  static bool nativeFeature = false;

  /// The native Showcase grid (LeeCat's native design home):
  /// for themes whose design layer renders grid items as
  /// per-style Showcase cells, the bridge sets the items here
  /// and _PeekStickyGrid builds the cells from them instead of
  /// the template's RFW-built Film children. Null (or empty) =
  /// no swap — the template's grid renders as before. The tap
  /// routes to the same host call as a template cell tap.
  static List<PeekGridItem>? gridItems;
  static void Function(int index)? onGridItemTap;
  static bool nativeShowcase = false;

  /// The current display style the bridge feeds the template
  /// ('grid', 'largeGrid', 'banner', 'list', 'list2', 'card',
  /// 'textList'). The Showcase swap applies to the grid modes
  /// only — in list/textList the template's RowItem/TextItem
  /// rows render.
  static String displayStyle = 'grid';

  /// The two data fields the native Feature's static panels
  /// reference (totalLabel / source.name in the fragments),
  /// set by the bridge alongside the recommend section.
  static String? totalLabel;
  static String? sourceName;

  /// Feature-panel buttons (openSearch / openHistory /
  /// openFavorite / showDisplayStylePicker): the bridge routes
  /// the action name to its _onEvent.
  static void Function(String name)? onFeatureAction;
}

/// One item of the native-design recommend section: the B12
/// banner item reduced to what the section renders.
class PeekRecommendItem {
  const PeekRecommendItem({
    required this.index,
    required this.name,
    required this.pic,
    required this.remarks,
  });

  final int index;
  final String name;
  final String pic;
  final String remarks;
}

/// One item of the native Showcase grid: the B11 grid item
/// reduced to what the Showcase cells render (rankLabel is the
/// 1-based position the fragments print).
class PeekGridItem {
  const PeekGridItem({
    required this.index,
    required this.name,
    required this.pic,
    required this.remarks,
    required this.rankLabel,
  });

  final int index;
  final String name;
  final String pic;
  final String remarks;
  final String rankLabel;
}

BoxFit _fit(Object? value, BoxFit fallback) {
  switch (value) {
    case 'contain':
      return BoxFit.contain;
    case 'fill':
      return BoxFit.fill;
    case 'fitWidth':
      return BoxFit.fitWidth;
    case 'fitHeight':
      return BoxFit.fitHeight;
    case 'none':
      return BoxFit.none;
    case 'scaleDown':
      return BoxFit.scaleDown;
    case 'cover':
      return BoxFit.cover;
  }
  return fallback;
}

LocalWidgetLibrary createPeekHomeWidgets() =>
    LocalWidgetLibrary(<String, LocalWidgetBuilder>{
      'T4Image': (BuildContext context, DataSource source) {
        final String url = source.v<String>(<Object>['url']) ?? '';
        final Color placeholder =
            ArgumentDecoders.color(source, <Object>['placeholderColor']) ??
                const Color(0xFF37474F);
        if (url.isEmpty) return ColoredBox(color: placeholder);
        return Image.network(
          url,
          fit: _fit(source.v<String>(<Object>['fit']), BoxFit.cover),
          alignment:
              ArgumentDecoders.alignment(source, <Object>['alignment']) ??
                  Alignment.center,
          gaplessPlayback:
              source.v<bool>(<Object>['useOldImageOnUrlChange']) ?? false,
          errorBuilder: (BuildContext context, Object error,
                  StackTrace? stackTrace) =>
              ColoredBox(color: placeholder),
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? progress) {
            if (progress == null) return child;
            return ColoredBox(color: placeholder);
          },
        );
      },
      'PeekGlass': (BuildContext context, DataSource source) {
        final double blur = source.v<double>(<Object>['blur']) ?? 12;
        final double radius = source.v<double>(<Object>['radius']) ?? 16;
        final Color tint =
            ArgumentDecoders.color(source, <Object>['tintColor']) ??
                const Color(0x33FFFFFF);
        final Color border =
            ArgumentDecoders.color(source, <Object>['borderColor']) ??
                const Color(0x22FFFFFF);
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border),
              ),
              child: source.optionalChild(<Object>['child']),
            ),
          ),
        );
      },
      'PeekCarousel': (BuildContext context, DataSource source) {
        return _PeekCarousel(
          autoPlay: source.v<bool>(<Object>['autoPlay']) ?? false,
          intervalMs: source.v<int>(<Object>['interval']) ?? 4000,
          viewportFraction:
              source.v<double>(<Object>['viewportFraction']) ?? 1.0,
          activeColor:
              ArgumentDecoders.color(source, <Object>['activeColor']) ??
                  const Color(0xFFFFFFFF),
          inactiveColor:
              ArgumentDecoders.color(source, <Object>['inactiveColor']) ??
                  const Color(0x66FFFFFF),
          showIndicators:
              source.v<bool>(<Object>['showIndicators']) ?? true,
          indicatorAlignment: ArgumentDecoders.alignment(
                  source, <Object>['indicatorAlignment']) ??
              Alignment.bottomCenter,
          style: source.v<String>(<Object>['style']),
          stackScale: source.v<double>(<Object>['stackScale']),
          stackOpacity: source.v<double>(<Object>['stackOpacity']),
          stackOffset: source.v<double>(<Object>['stackOffset']),
          stackRotation: source.v<double>(<Object>['stackRotation']),
          syncImmersivePalette:
              source.v<bool>(<Object>['syncImmersivePalette']) ?? false,
          children: source.childList(<Object>['children']),
        );
      },
      'PeekImmersiveBackdrop': (BuildContext context, DataSource source) {
        final String url = source.v<String>(<Object>['imageUrl']) ?? '';
        final Color primary =
            ArgumentDecoders.color(source, <Object>['primaryColor']) ??
                const Color(0xFF1A237E);
        final Color secondary =
            ArgumentDecoders.color(source, <Object>['secondaryColor']) ??
                const Color(0xFF4A148C);
        final Color background =
            ArgumentDecoders.color(source, <Object>['backgroundColor']) ??
                const Color(0xFF0B0B10);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: background),
            if (url.isNotEmpty)
              Opacity(
                opacity: 0.55,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    primary.withValues(alpha: 0.45),
                    secondary.withValues(alpha: 0.18),
                    background.withValues(alpha: 0.88),
                    background,
                  ],
                  stops: const <double>[0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ],
        );
      },
      'PeekImmersiveHero': (BuildContext context, DataSource source) {
        final String url = source.v<String>(<Object>['imageUrl']) ?? '';
        final Color primary =
            ArgumentDecoders.color(source, <Object>['primaryColor']) ??
                const Color(0xFF1A237E);
        final Color secondary =
            ArgumentDecoders.color(source, <Object>['secondaryColor']) ??
                primary;
        final Color background =
            ArgumentDecoders.color(source, <Object>['backgroundColor']) ??
                const Color(0xFF0B0B10);
        final String fitName = source.v<String>(<Object>['fit']) ?? 'cover';
        final String portraitFit =
            source.v<String>(<Object>['portraitFit']) ?? fitName;
        final String landscapeFit =
            source.v<String>(<Object>['landscapeFit']) ?? fitName;
        final AlignmentGeometry portraitAlignment =
            ArgumentDecoders.alignment(source, <Object>['portraitAlignment']) ??
                Alignment.topCenter;
        final AlignmentGeometry landscapeAlignment = ArgumentDecoders
                .alignment(source, <Object>['landscapeAlignment']) ??
            Alignment.center;
        final Widget? child = source.optionalChild(<Object>['child']);
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool landscape = constraints.maxWidth > constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: background),
                if (url.isNotEmpty)
                  Image.network(
                    url,
                    fit: _fit(landscape ? landscapeFit : portraitFit,
                        BoxFit.cover),
                    alignment:
                        landscape ? landscapeAlignment : portraitAlignment,
                    gaplessPlayback: true,
                    errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        primary.withValues(alpha: 0.30),
                        secondary.withValues(alpha: 0.16),
                        background.withValues(alpha: 0.92),
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                if (child != null) child,
              ],
            );
          },
        );
      },
      'PeekImmersiveScaffold': (BuildContext context, DataSource source) {
        // The immersive root PeekPro's polaroid-style themes use:
        // a full-screen immersive backdrop (poster image + primary /
        // secondary wash fading into the background colour) with the
        // page body on top. Same background treatment as
        // PeekImmersiveHero (same gradient stops and alphas); the
        // Scaffold call carries no fit/alignment arguments, so there
        // is no orientation branch here. Only one of the 50 pack
        // themes uses it (拍立得）; RFW core has no such widget.
        final String url = source.v<String>(<Object>['imageUrl']) ?? '';
        final Color primary =
            ArgumentDecoders.color(source, <Object>['primaryColor']) ??
                const Color(0xFF1A237E);
        final Color secondary =
            ArgumentDecoders.color(source, <Object>['secondaryColor']) ??
                primary;
        final Color background =
            ArgumentDecoders.color(source, <Object>['backgroundColor']) ??
                const Color(0xFF0B0B10);
        final Widget? child = source.optionalChild(<Object>['child']);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: background),
            if (url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) =>
                    const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    primary.withValues(alpha: 0.30),
                    secondary.withValues(alpha: 0.16),
                    background.withValues(alpha: 0.92),
                  ],
                  stops: const <double>[0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
      'PosterCaption': (BuildContext context, DataSource source) {
        final String name = source.v<String>(<Object>['name']) ?? '';
        final String remarks = source.v<String>(<Object>['remarks']) ?? '';
        // Caption treatment by design style (theme_design.dart):
        // the one library choke point inside every template Poster.
        // ticket gets its dashed perforation, noir its gold rule,
        // album its light "留白题签" strip, paper its fine rule +
        // left-aligned editorial text, polar its accent bar, radar
        // its accent-lit title. Every other style keeps the plain
        // dark scrim + white title.
        final ThemeDesignParams? design = PeekHomeHooks.designParams;
        final String shape = design?.posterShape ?? 'source';
        final Color accent = design?.accent ?? const Color(0xFFFFFFFF);
        final bool lightStrip = shape == 'polaroid';
        final bool leftAlign = shape == 'paper';
        final Color titleColor = lightStrip
            ? const Color(0xFF252A30)
            : shape == 'radar'
                ? accent
                : const Color(0xFFFFFFFF);
        final Color remarksColor = lightStrip
            ? const Color(0xB3252A30)
            : shape == 'radar'
                ? accent.withValues(alpha: 0.75)
                : const Color(0xB3FFFFFF);
        final TextAlign align =
            leftAlign ? TextAlign.start : TextAlign.center;
        final CrossAxisAlignment cross = leftAlign
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center;
        Widget? divider;
        if (shape == 'ticket') {
          divider = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _DashedLine(color: accent),
          );
        } else if (shape == 'gold') {
          divider = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(width: 40, height: 1, color: accent),
          );
        } else if (shape == 'paper') {
          divider = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
                height: 1, color: accent.withValues(alpha: 0.6)),
          );
        } else if (shape == 'polar') {
          divider = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(height: 3, color: accent),
          );
        }
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lightStrip
                  ? const <Color>[Color(0x00FFFFFF), Color(0xE0FFFFFF)]
                  : const <Color>[Color(0x00000000), Color(0xB3000000)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: <Widget>[
              if (divider != null) divider,
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  fontFamily: PeekHomeHooks.titleFontFamily,
                ),
              ),
              if (remarks.isNotEmpty)
                Text(
                  remarks,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: align,
                  style: TextStyle(
                    color: remarksColor,
                    fontSize: 10.5,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        );
      },
      'HomeCaption': (BuildContext context, DataSource source) {
        final String name = source.v<String>(<Object>['name']) ?? '';
        final String remarks = source.v<String>(<Object>['remarks']) ?? '';
        final Color color =
            ArgumentDecoders.color(source, <Object>['color']) ??
                const Color(0xFFFFFFFF);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                fontFamily: PeekHomeHooks.titleFontFamily,
              ),
            ),
            if (remarks.isNotEmpty)
              Text(
                remarks,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        );
      },
      'PeekStickyGrid': (BuildContext context, DataSource source) {
        return _PeekStickyGrid(
          heroHeight: source.v<double>(<Object>['heroHeight']) ?? 0,
          pinnedHeight: source.v<double>(<Object>['pinnedHeight']) ?? 54,
          sectionHeight: source.v<double>(<Object>['sectionHeight']) ?? 55,
          crossAxisCount: source.v<int>(<Object>['crossAxisCount']) ?? 3,
          childAspectRatio:
              source.v<double>(<Object>['childAspectRatio']) ?? 0.61,
          mainAxisSpacing:
              source.v<double>(<Object>['mainAxisSpacing']) ?? 8,
          crossAxisSpacing:
              source.v<double>(<Object>['crossAxisSpacing']) ?? 8,
          horizontalPadding:
              source.v<double>(<Object>['horizontalPadding']) ?? 12,
          bottomPadding: source.v<double>(<Object>['bottomPadding']) ?? 96,
          hero: source.child(<Object>['hero']),
          pinnedHeader: source.child(<Object>['pinnedHeader']),
          sectionHeader: source.child(<Object>['sectionHeader']),
          empty: source.child(<Object>['empty']),
          children: source.childList(<Object>['children']),
        );
      },
      'ClipPath': (BuildContext context, DataSource source) {
        final Widget? child = source.optionalChild(<Object>['child']);
        if (child == null) {
          return const SizedBox.shrink();
        }
        // Bezier `path` wins when given; `points` (straight edges)
        // is the fallback. Coordinates are 0..1-relative in both.
        final List<_PathSegment>? segments =
            _decodePathSegments(source, <Object>['path']);
        if (segments != null && segments.isNotEmpty) {
          return ClipPath(clipper: _BezierClipper(segments), child: child);
        }
        final List<Offset>? points =
            _decodeOffsets(source, <Object>['points']);
        if (points == null || points.length < 3) {
          return child;
        }
        return ClipPath(clipper: _PolygonClipper(points), child: child);
      },
      'RotatedBox': (BuildContext context, DataSource source) {
        final int turns = source.v<int>(<Object>['quarterTurns']) ?? 0;
        return RotatedBox(
          quarterTurns: turns,
          child: source.optionalChild(<Object>['child']) ??
              const SizedBox.shrink(),
        );
      },
      'Transform': (BuildContext context, DataSource source) {
        final double angle = _decodeDouble(source, <Object>['angle']) ?? 0.0;
        final double scale = _decodeDouble(source, <Object>['scale']) ?? 1.0;
        final double translateX =
            _decodeDouble(source, <Object>['translateX']) ?? 0.0;
        final double translateY =
            _decodeDouble(source, <Object>['translateY']) ?? 0.0;
        return Transform(
          transform: Matrix4.identity()
            ..translateByDouble(translateX, translateY, 0.0, 1.0)
            ..rotateZ(angle)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          alignment: Alignment.center,
          child: source.optionalChild(<Object>['child']) ??
              const SizedBox.shrink(),
        );
      },
      'CustomPaint': (BuildContext context, DataSource source) {
        final double width =
            _decodeDouble(source, <Object>['width']) ?? 100.0;
        final double height =
            _decodeDouble(source, <Object>['height']) ?? 100.0;
        final List<_PaintCommand>? shapes =
            _decodePaintCommands(source, <Object>['shapes']);
        return CustomPaint(
          size: Size(width, height),
          painter: _CommandPainter(shapes ?? const <_PaintCommand>[]),
        );
      },
    });

/// Decodes an RFW number (int or double) as a double. RFW text writes
/// `0` as int and `0.0` as double; `source.v<double>` only matches
/// doubles, so int values need the fallback.
double? _decodeDouble(DataSource source, List<Object> key) {
  final double? asDouble = source.v<double>(key);
  if (asDouble != null) return asDouble;
  final int? asInt = source.v<int>(key);
  return asInt?.toDouble();
}

/// Decodes a list of `{x, y}` maps as 0..1-relative [Offset]s.
List<Offset>? _decodeOffsets(DataSource source, List<Object> key) {
  return ArgumentDecoders.list<Offset>(
    source,
    key,
    (DataSource s, List<Object> k) {
      final double x = _decodeDouble(s, <Object>[...k, 'x']) ?? 0.0;
      final double y = _decodeDouble(s, <Object>[...k, 'y']) ?? 0.0;
      return Offset(x, y);
    },
  );
}

/// Clips to the polygon through the given 0..1-relative points
/// (straight edges only). For smooth curves use [_BezierClipper].
class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final Offset p =
          Offset(points[i].dx * size.width, points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_PolygonClipper oldClipper) {
    if (points.length != oldClipper.points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != oldClipper.points[i]) return true;
    }
    return false;
  }
}

/// Clips to a Bezier path through 0..1-relative segments ('move' |
/// 'line' | 'quad' | 'cubic' | 'close'), decoded the same way as
/// [_CommandPainter]'s path command, so curves stay smooth at any
/// size. [points] ([_PolygonClipper]) remains the straight-edge
/// fallback when no `path` is given.
class _BezierClipper extends CustomClipper<Path> {
  const _BezierClipper(this.segments);

  final List<_PathSegment> segments;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    for (final _PathSegment segment in segments) {
      switch (segment.op) {
        case 'move':
          path.moveTo(segment.x * size.width, segment.y * size.height);
          break;
        case 'line':
          path.lineTo(segment.x * size.width, segment.y * size.height);
          break;
        case 'quad':
          path.quadraticBezierTo(
            segment.cx * size.width,
            segment.cy * size.height,
            segment.x * size.width,
            segment.y * size.height,
          );
          break;
        case 'cubic':
          path.cubicTo(
            segment.c1x * size.width,
            segment.c1y * size.height,
            segment.c2x * size.width,
            segment.c2y * size.height,
            segment.x * size.width,
            segment.y * size.height,
          );
          break;
        case 'close':
          path.close();
          break;
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BezierClipper oldClipper) {
    return !_listEquals(segments, oldClipper.segments);
  }
}

/// One segment of a [CustomPaint] `path` command. Coordinates are
/// absolute px inside the widget's `width` x `height` box.
class _PathSegment {
  const _PathSegment({
    required this.op,
    this.x = 0.0,
    this.y = 0.0,
    this.cx = 0.0,
    this.cy = 0.0,
    this.c1x = 0.0,
    this.c1y = 0.0,
    this.c2x = 0.0,
    this.c2y = 0.0,
  });

  /// 'move' | 'line' | 'quad' | 'cubic' | 'close'.
  final String op;
  final double x;
  final double y;

  /// Quadratic Bezier control point ('quad').
  final double cx;
  final double cy;

  /// Cubic Bezier control points ('cubic').
  final double c1x;
  final double c1y;
  final double c2x;
  final double c2y;

  @override
  bool operator ==(Object other) {
    return other is _PathSegment &&
        op == other.op &&
        x == other.x &&
        y == other.y &&
        cx == other.cx &&
        cy == other.cy &&
        c1x == other.c1x &&
        c1y == other.c1y &&
        c2x == other.c2x &&
        c2y == other.c2y;
  }

  @override
  int get hashCode => Object.hash(op, x, y, cx, cy, c1x, c1y, c2x, c2y);
}

/// One draw instruction for [CustomPaint]'s `shapes` list. Coordinates
/// are absolute px inside the widget's `width` x `height` box.
class _PaintCommand {
  const _PaintCommand({
    required this.type,
    this.cx = 0.0,
    this.cy = 0.0,
    this.radius = 0.0,
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.x1 = 0.0,
    this.y1 = 0.0,
    this.x2 = 0.0,
    this.y2 = 0.0,
    this.segments = const <_PathSegment>[],
    this.points = const <Offset>[],
    this.close = false,
    this.color = const Color(0xFF000000),
    this.filled = true,
    this.width = 1.0,
  });

  /// 'circle' | 'rect' | 'rrect' | 'line' | 'path'.
  final String type;

  /// Circle centre + radius ('circle'); rrect corner radius ('rrect').
  final double cx;
  final double cy;
  final double radius;

  /// Box edges ('rect' / 'rrect').
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Line endpoints ('line').
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  /// Path segments ('path'); used when non-empty.
  final List<_PathSegment> segments;

  /// Shorthand polyline points ('path') when [segments] is empty:
  /// move to the first point, line to the rest.
  final List<Offset> points;

  /// Whether the path is closed ('path').
  final bool close;
  final Color color;
  final bool filled;
  final double width;

  @override
  bool operator ==(Object other) {
    if (other is! _PaintCommand) return false;
    return type == other.type &&
        cx == other.cx &&
        cy == other.cy &&
        radius == other.radius &&
        left == other.left &&
        top == other.top &&
        right == other.right &&
        bottom == other.bottom &&
        x1 == other.x1 &&
        y1 == other.y1 &&
        x2 == other.x2 &&
        y2 == other.y2 &&
        close == other.close &&
        color == other.color &&
        filled == other.filled &&
        width == other.width &&
        _listEquals(segments, other.segments) &&
        _listEquals(points, other.points);
  }

  @override
  int get hashCode => Object.hash(
        type,
        cx,
        cy,
        radius,
        left,
        top,
        right,
        bottom,
        x1,
        y1,
        x2,
        y2,
        close,
        color,
        filled,
        width,
        Object.hashAll(segments),
        Object.hashAll(points),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<_PathSegment>? _decodePathSegments(DataSource source, List<Object> key) {
  return ArgumentDecoders.list<_PathSegment>(
    source,
    key,
    (DataSource s, List<Object> k) {
      return _PathSegment(
        op: s.v<String>(<Object>[...k, 'op']) ?? '',
        x: _decodeDouble(s, <Object>[...k, 'x']) ?? 0.0,
        y: _decodeDouble(s, <Object>[...k, 'y']) ?? 0.0,
        cx: _decodeDouble(s, <Object>[...k, 'cx']) ?? 0.0,
        cy: _decodeDouble(s, <Object>[...k, 'cy']) ?? 0.0,
        c1x: _decodeDouble(s, <Object>[...k, 'c1x']) ?? 0.0,
        c1y: _decodeDouble(s, <Object>[...k, 'c1y']) ?? 0.0,
        c2x: _decodeDouble(s, <Object>[...k, 'c2x']) ?? 0.0,
        c2y: _decodeDouble(s, <Object>[...k, 'c2y']) ?? 0.0,
      );
    },
  );
}

List<_PaintCommand>? _decodePaintCommands(DataSource source, List<Object> key) {
  return ArgumentDecoders.list<_PaintCommand>(
    source,
    key,
    (DataSource s, List<Object> k) {
      final Color color =
          ArgumentDecoders.color(s, <Object>[...k, 'color']) ??
              const Color(0xFF000000);
      return _PaintCommand(
        type: s.v<String>(<Object>[...k, 'type']) ?? '',
        cx: _decodeDouble(s, <Object>[...k, 'cx']) ?? 0.0,
        cy: _decodeDouble(s, <Object>[...k, 'cy']) ?? 0.0,
        radius: _decodeDouble(s, <Object>[...k, 'radius']) ?? 0.0,
        left: _decodeDouble(s, <Object>[...k, 'left']) ?? 0.0,
        top: _decodeDouble(s, <Object>[...k, 'top']) ?? 0.0,
        right: _decodeDouble(s, <Object>[...k, 'right']) ?? 0.0,
        bottom: _decodeDouble(s, <Object>[...k, 'bottom']) ?? 0.0,
        x1: _decodeDouble(s, <Object>[...k, 'x1']) ?? 0.0,
        y1: _decodeDouble(s, <Object>[...k, 'y1']) ?? 0.0,
        x2: _decodeDouble(s, <Object>[...k, 'x2']) ?? 0.0,
        y2: _decodeDouble(s, <Object>[...k, 'y2']) ?? 0.0,
        segments: _decodePathSegments(s, <Object>[...k, 'segments']) ??
            const <_PathSegment>[],
        points: _decodeOffsets(s, <Object>[...k, 'points']) ??
            const <Offset>[],
        close: s.v<bool>(<Object>[...k, 'close']) ?? false,
        color: color,
        filled: s.v<bool>(<Object>[...k, 'filled']) ?? true,
        width: _decodeDouble(s, <Object>[...k, 'width']) ?? 1.0,
      );
    },
  );
}

/// Draws [CustomPaint]'s `shapes` command list, in order.
class _CommandPainter extends CustomPainter {
  const _CommandPainter(this.commands);

  final List<_PaintCommand> commands;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _PaintCommand command in commands) {
      final Paint paint = Paint()
        ..color = command.color
        ..style = command.filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = command.width;
      switch (command.type) {
        case 'circle':
          canvas.drawCircle(
              Offset(command.cx, command.cy), command.radius, paint);
          break;
        case 'rect':
          canvas.drawRect(
              Rect.fromLTRB(
                  command.left, command.top, command.right, command.bottom),
              paint);
          break;
        case 'rrect':
          canvas.drawRRect(
              RRect.fromLTRBR(command.left, command.top, command.right,
                  command.bottom, Radius.circular(command.radius)),
              paint);
          break;
        case 'line':
          canvas.drawLine(Offset(command.x1, command.y1),
              Offset(command.x2, command.y2), paint);
          break;
        case 'path':
          canvas.drawPath(_buildPath(command), paint);
          break;
      }
    }
  }

  Path _buildPath(_PaintCommand command) {
    final Path path = Path();
    if (command.segments.isNotEmpty) {
      for (final _PathSegment segment in command.segments) {
        switch (segment.op) {
          case 'move':
            path.moveTo(segment.x, segment.y);
            break;
          case 'line':
            path.lineTo(segment.x, segment.y);
            break;
          case 'quad':
            path.quadraticBezierTo(
                segment.cx, segment.cy, segment.x, segment.y);
            break;
          case 'cubic':
            path.cubicTo(segment.c1x, segment.c1y, segment.c2x, segment.c2y,
                segment.x, segment.y);
            break;
          case 'close':
            path.close();
            break;
        }
      }
    } else {
      for (int i = 0; i < command.points.length; i++) {
        if (i == 0) {
          path.moveTo(command.points[i].dx, command.points[i].dy);
        } else {
          path.lineTo(command.points[i].dx, command.points[i].dy);
        }
      }
    }
    if (command.close) path.close();
    return path;
  }

  @override
  bool shouldRepaint(_CommandPainter oldDelegate) {
    if (commands.length != oldDelegate.commands.length) return true;
    for (int i = 0; i < commands.length; i++) {
      if (commands[i] != oldDelegate.commands[i]) return true;
    }
    return false;
  }
}

class _PeekCarousel extends StatefulWidget {
  const _PeekCarousel({
    required this.autoPlay,
    required this.intervalMs,
    required this.viewportFraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.showIndicators,
    required this.indicatorAlignment,
    required this.style,
    required this.stackScale,
    required this.stackOpacity,
    required this.stackOffset,
    required this.stackRotation,
    required this.syncImmersivePalette,
    required this.children,
  });

  final bool autoPlay;
  final int intervalMs;
  final double viewportFraction;
  final Color activeColor;
  final Color inactiveColor;
  final bool showIndicators;
  final AlignmentGeometry indicatorAlignment;

  /// The themes' carousel mode: "stack" enables the stack*
  /// transforms; any other value (e.g. "standard") disables
  /// them even if stack parameters are present.
  final String? style;
  final double? stackScale;
  final double? stackOpacity;
  final double? stackOffset;
  final double? stackRotation;
  final bool syncImmersivePalette;
  final List<Widget> children;

  @override
  State<_PeekCarousel> createState() => _PeekCarouselState();
}

class _PeekCarouselState extends State<_PeekCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        PageController(viewportFraction: widget.viewportFraction);
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!widget.autoPlay || widget.children.length < 2) return;
    _timer = Timer.periodic(Duration(milliseconds: widget.intervalMs),
        (Timer timer) {
      if (!mounted || !_controller.hasClients) return;
      final int next = (_page + 1) % widget.children.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  void didUpdateWidget(_PeekCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.intervalMs != widget.intervalMs) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The design layer's disc treatment: the slide is presented
  /// as a record — circular cover, accent ring, spindle dot —
  /// centred in the carousel page. The slide's own caption bar
  /// survives inside the circle's lower arc.
  Widget _discFrame(Widget child, Color accent) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(child: child),
            ),
            Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  border:
                      Border.all(color: const Color(0x66000000), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageChild(int index, double pageWidth) {
    Widget child = widget.children[index];
    // Design-style poster treatment (theme_design.dart): the
    // hero slide is framed by the style's own device — record
    // disc for vinyl, ticket silhouette for 午夜票根， white
    // polaroid frame for 海盐相册， radar rings for 深空雷达，
    // double gold rule for 黑金典藏. Keyed on the theme's
    // declared designStyle through the design parameters —
    // never on a theme id. Wide/capsule styles keep the
    // template slide as-is (their identity is the wide frame
    // itself, carried by the section + captions).
    final ThemeDesignParams? design = PeekHomeHooks.designParams;
    if (design != null) {
      final Color accent = design.accent ?? const Color(0xFFFFBD70);
      final double radius = design.cardRadius ?? 16;
      switch (design.posterShape) {
        case 'disc':
          child = _discFrame(child, accent);
          break;
        case 'ticket':
          child = _TicketFrame(child: child, accent: accent, radius: radius);
          break;
        case 'polaroid':
          child = _PolaroidFrame(child: child);
          break;
        case 'radar':
          child = _RadarFrame(child: child, accent: accent);
          break;
        case 'gold':
          child = _GoldFrame(child: child, accent: accent, radius: radius);
          break;
        default:
          break;
      }
    }
    final bool stackMode = widget.style == null || widget.style == 'stack';
    final bool stacked = stackMode &&
        (widget.stackScale != null ||
            widget.stackOpacity != null ||
            widget.stackOffset != null ||
            widget.stackRotation != null);
    if (!stacked) return child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? inner) {
        double delta = 0;
        if (_controller.hasClients &&
            _controller.position.haveDimensions) {
          delta = (_controller.page ?? _page.toDouble()) - index;
        }
        final double d = delta.abs().clamp(0.0, 1.0);
        final double scale =
            1 - (1 - (widget.stackScale ?? 1)) * d;
        final double opacity =
            1 - (1 - (widget.stackOpacity ?? 1)) * d;
        // stackOffset is a fraction of the page width, not
        // pixels: the themes pass 0.22/0.24, and with delta's
        // sign the shift pulls neighbouring pages toward the
        // centre — the layered-cards look the stack themes
        // document. As raw pixels it would be a no-op.
        final double offsetX =
            (widget.stackOffset ?? 0) * delta * pageWidth;
        final double rotation = (widget.stackRotation ?? 0) * delta;
        Widget result = Opacity(opacity: opacity.clamp(0.0, 1.0), child: inner);
        result = Transform.scale(scale: scale, child: result);
        result = Transform.translate(offset: Offset(offsetX, 0), child: result);
        result = Transform.rotate(angle: rotation, child: result);
        return result;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            PageView.builder(
              controller: _controller,
              itemCount: widget.children.length,
              onPageChanged: (int index) {
                setState(() => _page = index);
                if (widget.syncImmersivePalette) {
                  PeekHomeHooks.onCarouselPage?.call(index);
                }
              },
              itemBuilder: (BuildContext context, int index) =>
                  _pageChild(index, constraints.maxWidth),
            ),
            if (widget.showIndicators && widget.children.length > 1)
              Align(
                alignment: widget.indicatorAlignment,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < widget.children.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? widget.activeColor
                                : widget.inactiveColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// LeeCat's native Feature hero: the per-style hero panel
/// recovered verbatim from the design layer's embedded RFW
/// fragments (pool dump pp 49965–50024 + 50075 — one Feature +
/// one Showcase per style). The Feature replaces the template's
/// hero carousel for every native-design style with a recovered
/// fragment (the bridge sets nativeFeature); the carousel
/// variants auto-advance on the fragment's own interval, the
/// panel variants are static. Fragment colours are verbatim
/// except the description-matched styles, whose text would be
/// unreadable on their own page background and is re-based onto
/// the theme's own meta (marked 推定 in the report): polaroid
/// (album, light page), capsule when the style is rose (light
/// page; arch is verbatim — its meta matches the capsule
/// record exactly), journal (paper). The generic style's
/// fragment is truncated in the pool dump itself (it cuts off
/// mid-string at the "观看影片" button's text colour) — the
/// visible part is implemented verbatim and the button's text
/// colour and size are inferred to match its play icon (推定）;
/// its Showcase is missing entirely, so the generic style has
/// no Showcase swap. Never keyed on a theme id.
class _NativeFeature extends StatefulWidget {
  const _NativeFeature({required this.items, required this.design});

  final List<PeekRecommendItem> items;
  final ThemeDesignParams? design;

  /// The Feature height for the active theme: the config
  /// table's per-style height, or the pool's heroHeight switch
  /// (portrait 330 / landscape 390) when the style has no
  /// recorded height.
  static double heightFor(ThemeDesignParams? design, bool landscape) =>
      design?.featureHeight(landscape: landscape) ??
          (landscape ? 390.0 : 330.0);

  @override
  State<_NativeFeature> createState() => _NativeFeatureState();
}

class _NativeFeatureState extends State<_NativeFeature> {
  late PageController _controller;
  Timer? _timer;

  String get _key => widget.design?.featureKey ?? 'generic';

  static const Set<String> _carouselKeys = <String>{
    'aurora',
    'noir',
    'morandi-ash',
    'morandi-mist',
    'morandi-violet',
    'morandi-arch',
    'capsule',
    'panorama',
    'premiere',
    'prism',
    'vinyl',
    'generic',
  };

  double get _viewportFraction => switch (_key) {
        'aurora' => 0.94,
        'noir' => 0.96,
        'morandi-ash' => 0.94,
        'morandi-mist' => 0.88,
        'morandi-violet' => 0.92,
        'morandi-arch' => 0.82,
        'capsule' => 0.82,
        'panorama' => 0.96,
        'premiere' => 0.96,
        'prism' => 0.92,
        'vinyl' => 0.92,
        _ => 1.0,
      };

  int? get _intervalMs => switch (_key) {
        'aurora' => 6500,
        'morandi-ash' => 6800,
        'morandi-mist' => 6400,
        'morandi-violet' => 7200,
        'panorama' => 7000,
        'premiere' => 7500,
        'prism' => 7000,
        _ => null,
      };

  Color get _accent => widget.design?.accent ?? const Color(0xFFFFBD70);
  List<Color> get _bases =>
      widget.design?.backgroundColors ?? const <Color>[];
  Color get _base =>
      _bases.isNotEmpty ? _bases.first : const Color(0xFF302019);
  String? get _fontFamily => PeekHomeHooks.titleFontFamily;
  Color get _placeholder =>
      widget.design?.surfaceColor ?? const Color(0xFF37474F);

  /// Text colour that reads on the theme's own page background:
  /// cream on dark bases, graphite on light ones — the same
  /// pair the Lee sources write into their own captions.
  Color get _ink {
    if (_bases.isEmpty) return const Color(0xFFFFE8CD);
    return _bases.first.computeLuminance() < 0.35
        ? const Color(0xFFFFE8CD)
        : const Color(0xFF252A30);
  }

  /// The capsule fragment belongs to arch (verbatim — its meta
  /// matches the capsule record exactly); rose re-bases the
  /// texts that would be unreadable on its light page.
  bool get _capsuleRebase =>
      _key == 'capsule' && widget.design?.designStyle == 'rose';

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
    _restartTimer();
  }

  @override
  void didUpdateWidget(_NativeFeature oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.design?.featureKey != widget.design?.featureKey) {
      _controller.dispose();
      _controller = PageController(viewportFraction: _viewportFraction);
    }
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final int? interval = _intervalMs;
    if (interval == null || widget.items.length < 2) return;
    _timer = Timer.periodic(Duration(milliseconds: interval), (Timer timer) {
      if (!mounted || !_controller.hasClients) return;
      final int current = _controller.page?.round() ?? 0;
      final int next = (current + 1) % widget.items.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic);
    });
  }

  void _fire(String name) => PeekHomeHooks.onFeatureAction?.call(name);

  Widget _action(String name, Widget child) => GestureDetector(
        onTap: () => _fire(name),
        child: child,
      );

  Widget _tapCard(PeekRecommendItem item, Widget child) => GestureDetector(
        onTap: () => PeekHomeHooks.onRecommendTap?.call(item.index),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (!_carouselKeys.contains(_key)) return _panel();
    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      itemBuilder: (BuildContext context, int index) =>
          _card(widget.items[index]),
    );
  }

  Widget _card(PeekRecommendItem item) => switch (_key) {
        'aurora' => _tapCard(item, _auroraCard(item)),
        'noir' => _tapCard(item, _noirCard(item)),
        'morandi-ash' => _tapCard(item, _ashCard(item)),
        'morandi-mist' => _tapCard(item, _mistCard(item)),
        'morandi-violet' => _tapCard(item, _violetCard(item)),
        'morandi-arch' => _tapCard(item, _archCard(item)),
        'capsule' => _tapCard(item, _capsuleCard(item)),
        'panorama' => _tapCard(item, _panoramaCard(item)),
        'premiere' => _tapCard(item, _premiereCard(item)),
        'prism' => _tapCard(item, _prismCard(item)),
        'vinyl' => _tapCard(item, _vinylCard(item)),
        _ => _tapCard(item, _genericCard(item)),
      };

  Widget _panel() => switch (_key) {
        'arcade' => _arcadePanel(),
        'journal' => _journalPanel(),
        'morandi-rose' => _rosePanel(),
        'morandi-wax' => _waxPanel(),
        'morandi-ochre' => _ochrePanel(),
        'morandi-album' => _albumPanel(),
        'ticket' => _ticketPanel(),
        'polaroid' => _polaroidPanel(),
        'bubble' => _bubblePanel(),
        'celluloid' => _celluloidPanel(),
        'radar' => _radarPanel(),
        'matrix' => _matrixPanel(),
        _ => const SizedBox.shrink(),
      };

  // --- Carousel cards (one per fragment, verbatim) ---

  Widget _auroraCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _sectionImage(item.pic, _placeholder),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      _base.withValues(alpha: 0),
                      _base.withValues(alpha: 0.93),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AURORA / 特别放映',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFFFFFFF),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '${item.remarks}  ·  进入故事  →',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _noirCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.6),
          border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(flex: 5, child: _sectionImage(item.pic, _placeholder)),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'PRIVATE\nSCREENING',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 18),
                      color: _accent,
                    ),
                    Text(
                      item.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFFFF5DE),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '落座，静候开场 →',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _ashCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _sectionImage(item.pic, _placeholder),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0x33867984),
                      Color(0xEE6C7984),
                      Color(0xCC967278),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xDDCD7461),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'SOFT SCREEN / 陶灰放映',
                        style: const TextStyle(
                          color: const Color(0xFF252A30),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFFFF7F3),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${item.remarks}  /  进入',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFC8BC),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _mistCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xCCF0F5F6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xAA86BBBA), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x00BCCEDA),
                            Color(0xCC96B8C4),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xEEDBB6BE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'MIST WINDOW',
                          style: const TextStyle(
                            color: const Color(0xFF252A30),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFF252A30),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Text(
                    '打开 →',
                    style: TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _violetCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xAA7180A6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x99BB939D), width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _sectionImage(item.pic, _placeholder),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    const Color(0x337F7DA3),
                    const Color(0xDD7180A6),
                    const Color(0xCC809DBD),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'BLUE VIOLET / 私人放映',
                    style: TextStyle(
                      color: Color(0xFFFFDDE4),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: const Color(0xFFFFF6F8),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '现在入场 →',
                    style: TextStyle(
                      color: Color(0xFFFFDDE4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _archCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(110, 110),
                  topRight: Radius.elliptical(110, 110),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x00CFA7BD),
                            Color(0xDDAFC5D2),
                            Color(0xCCD3A5AA),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xDDFFF1F3),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          'ROSE ARCADE',
                          style: const TextStyle(
                            color: const Color(0xFF252A30),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: const Color(0xFF252A30),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _capsuleCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(120, 120),
                  topRight: Radius.elliptical(120, 120),
                  bottomRight: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _base.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.nightlight_round,
                              color: Color(0xFFE4D9FF),
                              size: 14,
                            ),
                            Text(
                              '  月下首映',
                              style: TextStyle(
                                color: Color(0xFFE4D9FF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _capsuleRebase
                      ? _ink
                      : const Color(0xFFEFEAFF),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _panoramaCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _base.withValues(alpha: 0.67),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '↗  EXPLORE / 极地放映',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: _base.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFEAF8FF),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '进入 →',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _premiereCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x992C101D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x77FF647B), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 16, 26, 58),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _sectionImage(item.pic, _placeholder),
                ),
              ),
              const _ThemePattern(
                  kind: 'curtain', color: Color(0xBBDE345E)),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xBB2C101D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'PREMIERE / 今夜首映',
                    style: const TextStyle(
                      color: const Color(0xFFFFCCD3),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 14),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: const Color(0xFFFFEDEF),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _prismCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xAA16495A),
              const Color(0xAA59328C),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: const Radius.circular(28),
            topRight: const Radius.circular(8),
            bottomRight: const Radius.circular(28),
            bottomLeft: const Radius.circular(8),
          ),
          border: Border.all(color: const Color(0xAA63EBFF), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(28),
            bottomLeft: Radius.circular(8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _ThemePattern(kind: 'grid', color: Color(0x4463EBFF)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Q / 光子放映室',
                      style: TextStyle(
                        color: Color(0xFFB5F6FF),
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _sectionImage(item.pic, _placeholder),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              color: const Color(0xFFFFFFFF),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0x4463EBFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF63EBFF), width: 1),
                          ),
                          child: const Text(
                            '↗',
                            style: const TextStyle(
                              color: const Color(0xFFB5F6FF),
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // The vinyl card keeps the previous line's implementation
  // verbatim (it was already wired); _card wraps it in the
  // recommend tap, so there is no GestureDetector here.
  Widget _vinylCard(PeekRecommendItem item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.53),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: _accent.withValues(alpha: 0.27), width: 1),
        ),
        child: Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          _sectionImage(item.pic, _placeholder),
                          Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _base,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _accent, width: 5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SIDE A\n33 RPM',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          item.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            color: const Color(0xFFFFF0DE),
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '● 落针，开场',
                        style: TextStyle(color: _accent, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

  Widget _genericCard(PeekRecommendItem item) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _sectionImage(item.pic, _placeholder),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x20132920),
                      Color(0xF0132920),
                    ],
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: const Text(
                    "今日精选 · EDITOR'S PICK",
                    style: TextStyle(
                      color: Color(0xFFF1F1E4),
                      fontSize: 11,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFFFFFFF),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD5DED4),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1E4),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.play_arrow,
                                  color: const Color(0xFF253D32),
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                // The pool dump cuts off here, mid-string,
                                // at this text's colour: it is inferred to
                                // match the play icon (推定）.
                                const Text(
                                  '观看影片',
                                  style: const TextStyle(
                                    color: const Color(0xFF253D32),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // --- Static panels (one per fragment, verbatim) ---

  Widget _arcadePanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x88111724),
          border: Border.all(color: const Color(0xFFCAFF42), width: 1.5),
          boxShadow: <BoxShadow>[
            const BoxShadow(
              color: const Color(0x334AFFCB),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '●  PRESS PLAY',
                    style: TextStyle(
                      color: Color(0xFFCAFF42),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Text(
                  '${PeekHomeHooks.totalLabel ?? ''} TITLES',
                  style: const TextStyle(
                    color: Color(0xFF7A8AFF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '今晚，开一局。',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: const Color(0xFFFFFFFF),
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Row(
              children: <Widget>[
                _action(
                  'openSearch',
                  const Text(
                    '[ 搜索影片 ]',
                    style: TextStyle(
                      color: Color(0xFFCAFF42),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
                _action(
                  'openHistory',
                  const Text(
                    '继续旅程 →',
                    style: TextStyle(
                      color: Color(0xFFCAFF42),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // The journal fragment's texts are near-white / light blue on
  // the page background; for paper (light parchment) they are
  // re-based onto the theme's own accent and ink (推定） — the
  // Showcase keeps its dark pill, so its colours stay verbatim.
  Widget _journalPanel() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'THE SCREEN JOURNAL',
              style: TextStyle(
                color: _accent,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '今晚\n看点什么？',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _ink,
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            Container(height: 2, color: _accent),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${PeekHomeHooks.sourceName ?? ''} / '
                '${PeekHomeHooks.totalLabel ?? ''} 个故事',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _rosePanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xCCEBE0C1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x887A5D77), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ROSE STUDY / 玫瑰书房',
                    style: TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '翻开今晚的\n柔软章节',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFF252A30),
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Text(
                    '${PeekHomeHooks.sourceName ?? ''} · '
                    '${PeekHomeHooks.totalLabel ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _action(
              'openFavorite',
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x88C19E98),
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: const Color(0x996D536A), width: 1),
                ),
                child: const Text(
                  'MY\nSHELF',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: const Color(0xFF252A30),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _waxPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xAACFB7BD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x88D3A5AA), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x88AFC5D2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'LIST',
                style: const TextStyle(
                  color: const Color(0xFF252A30),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'WAX LIST / 粉蜡片单',
                      style: TextStyle(
                        color: Color(0xFF252A30),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '轻轻排好\n今晚顺序',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFF252A30),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    _action(
                      'showDisplayStylePicker',
                      const Text(
                        '切换视图 →',
                        style: TextStyle(
                          color: Color(0xFF252A30),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _ochrePanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xCCF4CBC8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xAAD0BC2C), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'OCHRE TICKET / 芥末票夹',
                    style: TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '从这一格，\n入场。',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFF252A30),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Text(
                    '片库 · ${PeekHomeHooks.totalLabel ?? ''}',
                    style: const TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0BC2C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '8',
                    style: const TextStyle(
                      color: const Color(0xFF252A30),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _action(
                    'openSearch',
                    const Text(
                      '找片',
                      style: TextStyle(
                        color: Color(0xFF252A30),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _albumPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x99B7B0AE),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x88F5BAC9), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'SEA ALBUM / 海雾相册',
                    style: TextStyle(
                      color: Color(0xFFFFD5DE),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '收好今晚的\n一帧心动',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFFFFFFF),
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  _action(
                    'openHistory',
                    const Text(
                      '翻看记录 →',
                      style: TextStyle(
                        color: Color(0xFFFFD5DE),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 68,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0x668AA6B8),
                borderRadius: const BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(8),
                  bottomRight: const Radius.circular(22),
                  bottomLeft: const Radius.circular(8),
                ),
                border:
                    Border.all(color: const Color(0xAAF5BAC9), width: 1),
              ),
            ),
          ],
        ),
      );

  Widget _ticketPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accent.withValues(alpha: 0.53), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'AFTER HOURS / 午夜场',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '下一站，好故事。',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFFFF3EB),
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _action(
                    'openHistory',
                    Text(
                      '凭票入场  →  继续观看',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The fragment's childless divider Container expands
            // to the row height in RFW; in Flutter that needs an
            // explicit infinite height (clamped by the row).
            Container(
              width: 1,
              height: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: _accent.withValues(alpha: 0.4),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'CINEMA',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                  ),
                ),
                const Text(
                  '01',
                  style: TextStyle(
                    color: Color(0xFFFFF3EB),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: <Widget>[
                    for (final double width in <double>[1, 3, 2, 1, 3, 1, 2])
                      Container(
                        width: width,
                        height: 18,
                        margin: const EdgeInsets.all(1),
                        color: _accent,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  // The polaroid fragment's texts are near-white on the page
  // background; for album (light page) the title and button
  // text are re-based onto the theme's ink and accent (推定） —
  // the teal accents stay, they are the fragment's identity.
  Widget _polaroidPanel() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'SALT & FILM  /  生活切片',
                    style: TextStyle(
                      color: Color(0xFF94E7E0),
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '把光影，\n装进相册。',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: _ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _action(
              'openSearch',
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x3394E7E0),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: const Color(0x8894E7E0), width: 1),
                ),
                child: Text(
                  '＋\n找一部',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bubblePanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0x77301D32),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(8),
            bottomLeft: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'BERRY CLUB / 今日灵感',
              style: TextStyle(
                color: Color(0xFFFFB4D8),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '快乐，不设片限。',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: const Color(0xFFFFEAF5),
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: _action(
                    'openSearch',
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x44FFB4D8),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Row(
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome,
                            color: const Color(0xFFFFEAF5),
                            size: 14,
                          ),
                          const Expanded(
                            child: const Text(
                              '  发现新片',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: const Color(0xFFFFEAF5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _action(
                    'openHistory',
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x44BBA8FF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Text(
                        '↗  继续追剧',
                        style: const TextStyle(
                          color: const Color(0xFFF0EAFF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _celluloidPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x9925231F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x77F1CE98), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 22,
                child: _ThemePattern(
                    kind: 'slate', color: Color(0x99F1CE98)),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "DIRECTOR'S CUT / 导演剪辑",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFF1CE98),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '故事，从这一镜开始。',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            color: const Color(0xFFFFF4DF),
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '片库 / ${PeekHomeHooks.totalLabel ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF1CE98),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          _action(
                            'openHistory',
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0x77F1CE98), width: 1),
                              ),
                              child: const Text(
                                '观看记录 →',
                                style: const TextStyle(
                                  color: const Color(0xFFF1CE98),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _radarPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.53),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 112,
              // The fragment's radar colour carries its own
              // alpha (0x99); the theme accent is passed at
              // that alpha.
              child: _ThemePattern(
                  kind: 'radar', color: _accent.withValues(alpha: 0.6)),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'DEEP SPACE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '探索\n故事星域',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFE5FFF3),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    _action(
                      'openSearch',
                      Text(
                        '寻找影片 →',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _matrixPanel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.53),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.53), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // The fragment's circuit colour carries its own
              // alpha (0x33); the theme accent is passed at
              // that alpha.
              _ThemePattern(
                  kind: 'circuit', color: _accent.withValues(alpha: 0.2)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'MATRIX / 影像终端',
                      style: TextStyle(
                        color: Color(0xFFDCC6FF),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '下一帧，无限可能。',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFF6EFFF),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _action(
                            'openSearch',
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.27),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '01 / 搜索',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFF6EFFF),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _action(
                            'openHistory',
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0x336BF5DA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '02 / 记录',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: const Color(0xFFBCFFED),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// LeeCat's native design pattern overlay (the ThemePattern
/// widget the fragments reference — kinds curtain, slate, film,
/// grid, radar, circuit). Its implementation is compiled into
/// LeeCat's libapp.so and does not appear in the pool dump, so
/// every kind below is an inferred drawing of the named device
/// (推定）, painted with the fragment's own colour.
class _ThemePattern extends StatelessWidget {
  const _ThemePattern({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
          painter: _ThemePatternPainter(kind: kind, color: color)),
    );
  }
}

class _ThemePatternPainter extends CustomPainter {
  const _ThemePatternPainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case 'curtain':
        _paintCurtain(canvas, size);
      case 'slate':
        _paintSlate(canvas, size);
      case 'film':
        _paintFilm(canvas, size);
      case 'grid':
        _paintGrid(canvas, size);
      case 'radar':
        _paintRadar(canvas, size);
      case 'circuit':
        _paintCircuit(canvas, size);
    }
  }

  void _paintCurtain(Canvas canvas, Size size) {
    // Vertical drape pleats: alternating translucent bands.
    const double step = 26;
    bool strong = true;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, step * 0.55, size.height),
          const Radius.circular(6),
        ),
        Paint()
          ..color =
              strong ? color : color.withValues(alpha: color.a * 0.35),
      );
      strong = !strong;
    }
  }

  void _paintSlate(Canvas canvas, Size size) {
    // Clapperboard diagonal stripes.
    const double stripe = 14;
    final Path path = Path();
    for (double x = -size.height;
        x < size.width + size.height;
        x += stripe * 2) {
      path.addPath(_diagonalStripe(x, stripe, size), Offset.zero);
    }
    canvas.drawPath(
        path, Paint()..color = color.withValues(alpha: color.a * 0.6));
  }

  Path _diagonalStripe(double x, double width, Size size) => Path()
    ..moveTo(x, 0)
    ..lineTo(x + width, 0)
    ..lineTo(x + width + size.height, size.height)
    ..lineTo(x + size.height, size.height)
    ..close();

  void _paintFilm(Canvas canvas, Size size) {
    // Filmstrip: sprocket holes down both edges.
    const double holeW = 7;
    const double holeH = 5;
    const double gap = 14;
    final Paint paint = Paint()..color = color;
    for (double y = 6; y + holeH < size.height; y += holeH + gap) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(4, y, holeW, holeH), const Radius.circular(2)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width - 4 - holeW, y, holeW, holeH),
            const Radius.circular(2)),
        paint,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    const double step = 26;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintRadar(Canvas canvas, Size size) {
    // Concentric rings + crosshair + a sweep wedge.
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxR =
        (size.width < size.height ? size.width : size.height) / 2;
    final Paint ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final double r in <double>[maxR, maxR * 0.66, maxR * 0.33]) {
      canvas.drawCircle(center, r, ring);
    }
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), ring);
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), ring);
    final Path sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
          Rect.fromCircle(center: center, radius: maxR), -1.2, 0.9, false)
      ..close();
    canvas.drawPath(
        sweep, Paint()..color = color.withValues(alpha: color.a * 0.14));
    canvas.drawCircle(center, 3, Paint()..color = color);
  }

  void _paintCircuit(Canvas canvas, Size size) {
    // Orthogonal traces with node dots; a tiny deterministic
    // generator so the pattern is stable across rebuilds.
    int seed = 7;
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed;
    }

    final Paint trace = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Paint node = Paint()..color = color;
    for (int i = 0; i < 9; i++) {
      double x = (next() % 1000) / 1000 * size.width;
      double y = (next() % 1000) / 1000 * size.height;
      final Path path = Path()..moveTo(x, y);
      for (int s = 0; s < 3; s++) {
        if (next() % 2 == 0) {
          x += 30 + next() % 60;
        } else {
          y += 24 + next() % 48;
        }
        path.lineTo(x, y);
      }
      canvas.drawPath(path, trace);
      canvas.drawCircle(Offset(x, y), 2.5, node);
    }
  }

  @override
  bool shouldRepaint(_ThemePatternPainter old) =>
      old.kind != kind || old.color != color;
}

/// The fragments' HomeCaption as the library's own HomeCaption
/// renders it (name 13 w600 + remarks 10.5 at 0.7 alpha, title
/// font family) — the fragment's fontSize argument is ignored
/// by that builder, as for the RFW templates.
class _ShowcaseCaption extends StatelessWidget {
  const _ShowcaseCaption({
    required this.name,
    required this.remarks,
    required this.color,
  });

  final String name;
  final String remarks;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
            fontFamily: PeekHomeHooks.titleFontFamily,
          ),
        ),
        if (remarks.isNotEmpty)
          Text(
            remarks,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10.5,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    );
  }
}

/// LeeCat's native Showcase (grid item): the per-style grid
/// cell recovered verbatim from the design layer's embedded
/// RFW fragments (one Showcase per style, same pool lines as
/// the Features). The bridge swaps the grid to these cells
/// (_PeekStickyGrid) for native-design styles with a recovered
/// Showcase; the generic style has no recovered Showcase (its
/// fragment is truncated) and keeps the template's Poster.
/// Colours verbatim except the capsule cell when the style is
/// rose (its caption would be unreadable on the light page —
/// re-based to the theme's ink, 推定； arch is verbatim). The
/// exact-match styles use the theme's own accent/base (equal
/// to the fragment literals), so a user theme re-declaring the
/// style follows its own meta.
class _NativeShowcase extends StatelessWidget {
  const _NativeShowcase({required this.item, required this.design});

  final PeekGridItem item;
  final ThemeDesignParams? design;

  String get _key => design?.featureKey ?? 'generic';
  Color get _accent => design?.accent ?? const Color(0xFFFFBD70);
  List<Color> get _bases =>
      design?.backgroundColors ?? const <Color>[];
  Color get _base =>
      _bases.isNotEmpty ? _bases.first : const Color(0xFF302019);
  String? get _fontFamily => PeekHomeHooks.titleFontFamily;
  Color get _placeholder =>
      design?.surfaceColor ?? const Color(0xFF37474F);

  Color get _ink {
    if (_bases.isEmpty) return const Color(0xFFFFE8CD);
    return _bases.first.computeLuminance() < 0.35
        ? const Color(0xFFFFE8CD)
        : const Color(0xFF252A30);
  }

  bool get _capsuleRebase =>
      _key == 'capsule' && design?.designStyle == 'rose';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PeekHomeHooks.onGridItemTap?.call(item.index),
      child: switch (_key) {
        'vinyl' => _vinylCell(),
        'aurora' => _auroraCell(),
        'noir' => _noirCell(),
        'ticket' => _ticketCell(),
        'polaroid' => _polaroidCell(),
        'panorama' => _panoramaCell(),
        'radar' => _radarCell(),
        'matrix' => _matrixCell(),
        'capsule' => _capsuleCell(),
        'journal' => _journalCell(),
        'bubble' => _bubbleCell(),
        'premiere' => _premiereCell(),
        'celluloid' => _celluloidCell(),
        'prism' => _prismCell(),
        'morandi-ash' => _ashCell(),
        'morandi-rose' => _roseCell(),
        'morandi-mist' => _mistCell(),
        'morandi-wax' => _waxCell(),
        'morandi-ochre' => _ochreCell(),
        'morandi-violet' => _violetCell(),
        'morandi-album' => _albumCell(),
        'morandi-arch' => _archCell(),
        'arcade' => _arcadeCell(),
        _ => _fallbackCell(),
      },
    );
  }

  Widget _vinylCell() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.47),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(240),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _sectionImage(item.pic, _placeholder),
                        Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _base,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _accent, width: 3),
                            ),
                            child: Text(
                              item.rankLabel,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFFFFE6C7),
              ),
            ),
          ],
        ),
      );

  Widget _auroraCell() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _sectionImage(item.pic, _placeholder),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _base.withValues(alpha: 0),
                    _base.withValues(alpha: 0.93),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '/ ${item.rankLabel}',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _ShowcaseCaption(
                    name: item.name,
                    remarks: item.remarks,
                    color: const Color(0xFFFFFFFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _noirCell() => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.47),
          border:
              Border.all(color: _accent.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(child: _sectionImage(item.pic, _placeholder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '—  ${item.rankLabel}  —',
                style: TextStyle(
                  color: _accent,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFFFFF5DE),
              ),
            ),
          ],
        ),
      );

  Widget _ticketCell() => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: _base.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: _accent.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 88,
                child: _sectionImage(item.pic, _placeholder),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'NOW ADMITTING',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            color: const Color(0xFFFFF3EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The fragment's childless stub Container expands
              // to the row height in RFW; in Flutter that needs
              // an explicit infinite height (clamped by the row).
              Container(
                width: 42,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.27), width: 1),
                ),
                child: Text(
                  item.rankLabel,
                  style: TextStyle(
                    color: _accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _polaroidCell() => Container(
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 4),
        decoration: BoxDecoration(
          color: const Color(0xBBE8FFF8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            const BoxShadow(
              color: const Color(0x33102025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: _sectionImage(item.pic, _placeholder),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Text(
                'FRAME / ${item.rankLabel}',
                style: const TextStyle(
                  color: Color(0xFF123C3A),
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFF123C3A),
              ),
            ),
          ],
        ),
      );

  Widget _panoramaCell() => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 6,
              child: _sectionImage(item.pic, _placeholder),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: _base.withValues(alpha: 0.67),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'VIEW / ${item.rankLabel}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 9,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFEAF8FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.remarks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _radarCell() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _base.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: _accent.withValues(alpha: 0.27), width: 1),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 94,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: _base.withValues(alpha: 0.73),
                        child: Text(
                          item.rankLabel,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SECTOR / CINEMA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFE5FFF3),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                        height: 1, color: _accent.withValues(alpha: 0.27)),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _matrixCell() => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _base.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: _accent.withValues(alpha: 0.53), width: 1),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'FILE / ${item.rankLabel}',
                        style: const TextStyle(
                          color: Color(0xFFDCC6FF),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BF5DA),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A0FF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _sectionImage(item.pic, _placeholder),
                  ),
                ),
              ),
              Container(
                height: 3,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                decoration: const BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      const Color(0xFFC9A0FF),
                      const Color(0xFF6BF5DA),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _ShowcaseCaption(
                  name: item.name,
                  remarks: item.remarks,
                  color: const Color(0xFFF6EFFF),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _capsuleCell() => Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.elliptical(96, 96),
                topRight: Radius.elliptical(96, 96),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _sectionImage(item.pic, _placeholder),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _base.withValues(alpha: 0.67),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.nightlight_round,
                            color: Color(0xFFE4D9FF),
                            size: 12,
                          ),
                          Text(
                            '  ${item.rankLabel}',
                            style: const TextStyle(
                              color: Color(0xFFE4D9FF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            child: _ShowcaseCaption(
              name: item.name,
              remarks: item.remarks,
              color: _capsuleRebase ? _ink : const Color(0xFFEFEAFF),
            ),
          ),
        ],
      );

  Widget _journalCell() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x66122336),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 36,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  item.rankLabel,
                  style: const TextStyle(
                    color: Color(0xFF83BBFF),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _sectionImage(item.pic, _placeholder),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: const Color(0xFFF1F5FF),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF83BBFF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Text(
                      '打开故事  ↗',
                      style: TextStyle(
                        color: Color(0xFF83BBFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bubbleCell() => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(30),
          bottomLeft: Radius.circular(10),
        ),
        child: Container(
          color: const Color(0x88301D32),
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: _ShowcaseCaption(
                  name: item.name,
                  remarks: item.remarks,
                  color: const Color(0xFFFFD9ED),
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xCC301D32),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFFB4D8), width: 1),
                        ),
                        child: Text(
                          item.rankLabel,
                          style: const TextStyle(
                            color: Color(0xFFFFB4D8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _premiereCell() => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: const Color(0x992C101D),
          child: Column(
            children: <Widget>[
              Container(height: 5, color: const Color(0xFFFF647B)),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    const _ThemePattern(
                        kind: 'curtain', color: Color(0x99C52C4F)),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xAA2C101D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.rankLabel,
                          style: const TextStyle(
                            color: Color(0xFFFFCCD3),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: _ShowcaseCaption(
                  name: item.name,
                  remarks: item.remarks,
                  color: const Color(0xFFFFEDEF),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _celluloidCell() => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: const Color(0xAA25231F),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x0025231F),
                            Color(0xDD25231F),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'REEL / ${item.rankLabel}',
                            style: const TextStyle(
                              color: Color(0xFFFFF4DF),
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                          _ShowcaseCaption(
                            name: item.name,
                            remarks: item.remarks,
                            color: const Color(0xFFFFF4DF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _ThemePattern(kind: 'film', color: Color(0x99F1CE98)),
            ],
          ),
        ),
      );

  Widget _prismCell() => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0x6615233C),
          borderRadius: const BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(8),
            bottomRight: const Radius.circular(24),
            bottomLeft: const Radius.circular(8),
          ),
          border: Border.all(color: const Color(0x8863EBFF), width: 1),
          boxShadow: <BoxShadow>[
            const BoxShadow(
              color: const Color(0x224CE5FF),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        color: const Color(0x9915233C),
                        child: Text(
                          'Q / ${item.rankLabel}',
                          style: const TextStyle(
                            color: Color(0xFFB5F6FF),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFFE7FBFF),
              ),
            ),
          ],
        ),
      );

  Widget _ashCell() => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _sectionImage(item.pic, _placeholder),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xDDCD7461),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.rankLabel,
                        style: const TextStyle(
                          color: Color(0xFF252A30),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xCC6C7984),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'GALLERY',
                      style: TextStyle(
                        color: Color(0xFFE8DCDD),
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFFFFF7F3),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.remarks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFC8BC),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _roseCell() => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xDDEBD9AF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x66A893A3), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _sectionImage(item.pic, _placeholder),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 2),
              child: Row(
                children: <Widget>[
                  Container(
                      width: 28, height: 2, color: const Color(0xFF6D536A)),
                  const Expanded(child: SizedBox.shrink()),
                  Text(
                    item.rankLabel,
                    style: const TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 8),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFF252A30),
              ),
            ),
          ],
        ),
      );

  Widget _mistCell() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xDDEAF1F4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x6686BBBA), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _sectionImage(item.pic, _placeholder),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFF252A30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
              child: Container(
                width: 42,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF86BBBA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _waxCell() => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xDDC3B8BE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66D3A5AA), width: 1),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x77D3A5AA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.rankLabel,
                  style: const TextStyle(
                    color: Color(0xFF252A30),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 82,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _sectionImage(item.pic, _placeholder),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: const Color(0xFF252A30),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item.remarks,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF252A30),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ochreCell() => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xDDAAB0BD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x88D0BC2C), width: 1),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 70,
                height: double.infinity,
                color: const Color(0xFFD0BC2C),
                alignment: Alignment.center,
                child: Text(
                  item.rankLabel,
                  style: const TextStyle(
                    color: Color(0xFF252A30),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 82,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _sectionImage(item.pic, _placeholder),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'ADMIT ONE',
                        style: TextStyle(
                          color: Color(0xFF252A30),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            color: const Color(0xFF252A30),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        item.remarks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF252A30),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _violetCell() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: const Color(0xAA7180A6),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x007180A6),
                            Color(0xDD7180A6),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(9),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xCCBB939D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.rankLabel,
                          style: const TextStyle(
                            color: Color(0xFF252A30),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: _ShowcaseCaption(
                  name: item.name,
                  remarks: item.remarks,
                  color: const Color(0xFFFFF6F8),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _albumCell() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xDDB7B0AE),
          borderRadius: const BorderRadius.only(
            topLeft: const Radius.circular(26),
            topRight: const Radius.circular(10),
            bottomRight: const Radius.circular(26),
            bottomLeft: const Radius.circular(10),
          ),
          border: Border.all(color: const Color(0x77F5BAC9), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _sectionImage(item.pic, _placeholder),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xCC5F8494),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.rankLabel,
                          style: const TextStyle(
                            color: Color(0xFFFFD5DE),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFF252A30),
              ),
            ),
          ],
        ),
      );

  Widget _archCell() => Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.elliptical(92, 92),
                topRight: Radius.elliptical(92, 92),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _sectionImage(item.pic, _placeholder),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xEECFA7BD),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'ARCH / ${item.rankLabel}',
                        style: const TextStyle(
                          color: Color(0xFF252A30),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
            child: _ShowcaseCaption(
              name: item.name,
              remarks: item.remarks,
              color: const Color(0xFF252A30),
            ),
          ),
        ],
      );

  Widget _arcadeCell() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0x88111724),
          border: Border.all(color: const Color(0x997A8AFF), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _sectionImage(item.pic, _placeholder),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: const Color(0xCC111724),
                      child: Text(
                        'LV. ${item.rankLabel}',
                        style: const TextStyle(
                          color: Color(0xFFCAFF42),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: _ShowcaseCaption(
                name: item.name,
                remarks: item.remarks,
                color: const Color(0xFFCAFF42),
              ),
            ),
          ],
        ),
      );

  // Defensive only: the bridge never enables the Showcase swap
  // for the generic style (its fragment is truncated), so this
  // is the template's own Poster look.
  Widget _fallbackCell() => Column(
        children: <Widget>[
          Expanded(
            child: _RectPoster(
              pic: item.pic,
              accent: _accent,
              radius: 16,
              width: double.infinity,
              height: double.infinity,
              placeholder: _placeholder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
            child: _ShowcaseCaption(
              name: item.name,
              remarks: item.remarks,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      );
}

/// The native grid's section header ("为你呈现 {{总数}} 部"):
/// the pool's lone "为你呈现" string sits next to a "{{0}} 部"
/// count string, and every root template puts its Section header
/// above a PeekStickyGrid that iterates data.home.items — so the
/// title belongs to the main grid, not to a banner-fed recommend
/// row (no root has such a row; the only horizontal things are
/// the Feature carousel and the 54px tab row). The count is the
/// grid's own item total. Ink follows the design layer's own
/// rule (page-background luminance, the same pair the Showcase
/// captions use).
class _NativeSectionHeader extends StatelessWidget {
  const _NativeSectionHeader({required this.design, required this.count});

  final ThemeDesignParams? design;
  final int count;

  @override
  Widget build(BuildContext context) {
    final List<Color> bases = design?.backgroundColors ?? const <Color>[];
    final Color ink = bases.isEmpty || bases.first.computeLuminance() < 0.35
        ? const Color(0xFFFFE8CD)
        : const Color(0xFF252A30);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: <Widget>[
          Text(
            '为你呈现',
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$count 部',
            style: TextStyle(
              color: ink.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero-slide frames: the same per-style devices as the
/// section posters, as wrappers around an arbitrary slide
/// widget (the carousel's template slide). The clip is real,
/// so the ticket silhouette reads on any page background.
class _TicketFrame extends StatelessWidget {
  const _TicketFrame({
    required this.child,
    required this.accent,
    required this.radius,
  });

  final Widget child;
  final Color accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipPath(
          clipper: _TicketClipper(radius: radius),
          child: child,
        ),
        CustomPaint(
          painter: _TicketOutlinePainter(radius: radius, accent: accent),
        ),
      ],
    );
  }
}

class _PolaroidFrame extends StatelessWidget {
  const _PolaroidFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 40),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDF8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RadarFrame extends StatelessWidget {
  const _RadarFrame({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Center(
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accent.withValues(alpha: 0.3), width: 1),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accent.withValues(alpha: 0.45), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldFrame extends StatelessWidget {
  const _GoldFrame({
    required this.child,
    required this.accent,
    required this.radius,
  });

  final Widget child;
  final Color accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: accent, width: 1),
          ),
        ),
        Positioned(
          left: 6,
          top: 6,
          right: 6,
          bottom: 6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular((radius - 2).clamp(0, 99)),
              border: Border.all(
                  color: accent.withValues(alpha: 0.55), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

/// The fallback recommend poster for styles without a native
/// shape: the template's own Poster look (rounded rect,
/// cardRadius, 1px accent border).
class _RectPoster extends StatelessWidget {
  const _RectPoster({
    required this.pic,
    required this.accent,
    required this.radius,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  final String pic;
  final Color accent;
  final double radius;
  final double width;
  final double height;
  final Color placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: pic.isEmpty
            ? ColoredBox(color: placeholder)
            : Image.network(
                pic,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) =>
                    ColoredBox(color: placeholder),
              ),
      ),
    );
  }
}

/// Shared image loader for the section posters: cover-fit
/// network image with the design surface as placeholder/error.
Widget _sectionImage(String pic, Color placeholder) {
  if (pic.isEmpty) return ColoredBox(color: placeholder);
  return Image.network(
    pic,
    fit: BoxFit.cover,
    errorBuilder: (BuildContext context, Object error,
            StackTrace? stackTrace) =>
        ColoredBox(color: placeholder),
  );
}

/// Ticket stub (午夜票根 "入场票推荐 · 虚线分隔"): the poster
/// silhouette itself is a ticket — rounded rect with a
/// semicircular bite out of each long edge at mid-height.
/// The bite is a real clip (not a painted circle), so it reads
/// on any page background.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.radius});

  final double radius;

  /// The notch depth is a fixed design constant (10, the value
  /// the previous line recorded as inferred); no caller varies
  /// it, so it is a const here rather than an optional
  /// parameter (flutter analyze flags never-passed optionals).
  static const double _notch = 10;

  @override
  Path getClip(Size size) {
    final Path rect = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    final Path left = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(0, size.height / 2), radius: _notch));
    final Path right = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width, size.height / 2), radius: _notch));
    return Path.combine(
        PathOperation.difference,
        Path.combine(PathOperation.difference, rect, left),
        right);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.radius != radius;
}

/// Outlines the ticket silhouette (same path as the clipper)
/// so the stub keeps its 1px accent border.
class _TicketOutlinePainter extends CustomPainter {
  const _TicketOutlinePainter({required this.radius, required this.accent});

  final double radius;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _TicketClipper(radius: radius).getClip(size),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_TicketOutlinePainter old) =>
      old.radius != radius || old.accent != accent;
}

/// A horizontal dashed line (ticket perforation / caption
/// divider). Drawn, not faked with a Border, so the dash
/// pattern is exact.
class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  /// Dash/gap are fixed design constants (5/4); no caller
  /// varies them, so they are literals here rather than
  /// optional parameters (flutter analyze flags never-passed
  /// optionals).
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter:
            _DashedLinePainter(color: color, dash: _dash, gap: _gap),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0),
          paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color || old.dash != dash || old.gap != gap;
}

class _PeekStickyGrid extends StatefulWidget {
  const _PeekStickyGrid({
    required this.heroHeight,
    required this.pinnedHeight,
    required this.sectionHeight,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.horizontalPadding,
    required this.bottomPadding,
    required this.hero,
    required this.pinnedHeader,
    required this.sectionHeader,
    required this.empty,
    required this.children,
  });

  final double heroHeight;
  final double pinnedHeight;
  final double sectionHeight;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double horizontalPadding;
  final double bottomPadding;
  final Widget hero;
  final Widget pinnedHeader;
  final Widget sectionHeader;
  final Widget empty;
  final List<Widget> children;

  @override
  State<_PeekStickyGrid> createState() => _PeekStickyGridState();
}

class _PeekStickyGridState extends State<_PeekStickyGrid> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_controller.hasClients) return;
      final ScrollPosition position = _controller.position;
      if (position.pixels > position.maxScrollExtent - 480) {
        PeekHomeHooks.onGridEndReached?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The native Showcase swap is on when the bridge set it, the
  /// items are present, and the template is in a grid display
  /// mode (list/textList keep the template's RowItem/TextItem
  /// rows).
  bool get _nativeShowcase =>
      PeekHomeHooks.nativeShowcase &&
      PeekHomeHooks.gridItems != null &&
      PeekHomeHooks.gridItems!.isNotEmpty &&
      PeekHomeHooks.displayStyle != 'list' &&
      PeekHomeHooks.displayStyle != 'textList';

  /// Grid columns under the swap: the style's config column key
  /// (cinema = 2 wide cards, collection = 1 full-width row);
  /// grid styles keep the template's own count (the user's
  /// display choice / editor columns).
  int get _gridColumns {
    if (!_nativeShowcase) return widget.crossAxisCount;
    final String? columns = ThemeDesignParams
        .nativeStyleConfigs[PeekHomeHooks.designParams?.featureKey]
        ?.columns;
    if (columns == 'cinema') return 2;
    if (columns == 'collection') return 1;
    return widget.crossAxisCount;
  }

  /// Grid ratio under the swap: the config table's ratio, or
  /// the template's own ratio when the style has no recorded
  /// ratio (aurora / noir / arcade); the collection styles use
  /// the native collectionRatio (2.4, the wide-row ratio).
  double get _gridRatio {
    if (!_nativeShowcase) return widget.childAspectRatio;
    final String? columns = ThemeDesignParams
        .nativeStyleConfigs[PeekHomeHooks.designParams?.featureKey]
        ?.columns;
    final double? ratio = ThemeDesignParams
        .nativeStyleConfigs[PeekHomeHooks.designParams?.featureKey]
        ?.ratio;
    if (ratio != null) return ratio;
    if (columns == 'collection') return 2.4;
    return widget.childAspectRatio;
  }

  SliverChildDelegate get _gridDelegate {
    if (!_nativeShowcase) {
      return SliverChildListDelegate(widget.children);
    }
    final List<PeekGridItem> items = PeekHomeHooks.gridItems!;
    return SliverChildBuilderDelegate(
      (BuildContext context, int index) => _NativeShowcase(
        item: items[index],
        design: PeekHomeHooks.designParams,
      ),
      childCount: items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _controller,
      slivers: <Widget>[
        // The native Feature hero (LeeCat's design layer) takes
        // the top slot when the bridge sets the hook — it
        // replaces the template's hero carousel for that style.
        if (PeekHomeHooks.nativeFeature &&
            PeekHomeHooks.recommendSection != null &&
            PeekHomeHooks.recommendSection!.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: _NativeFeature.heightFor(
                PeekHomeHooks.designParams,
                MediaQuery.orientationOf(context) == Orientation.landscape,
              ),
              child: _NativeFeature(
                items: PeekHomeHooks.recommendSection!,
                design: PeekHomeHooks.designParams,
              ),
            ),
          ),
        if (widget.heroHeight > 0)
          SliverToBoxAdapter(
            child: SizedBox(height: widget.heroHeight, child: widget.hero),
          ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            height: widget.pinnedHeight,
            child: widget.pinnedHeader,
          ),
        ),
        // The native grid's section header ("为你呈现 {{总数}} 部"):
        // the pool's lone "为你呈现" string sits next to a "{{0}} 部"
        // count string, and every root template puts its Section
        // header above a PeekStickyGrid that iterates
        // data.home.items — so the title belongs to the main grid,
        // not to a banner-fed recommend row (no root has such a
        // row; the only horizontal things are the Feature carousel
        // and the 54px tab row). The count is the grid's own total.
        if (PeekHomeHooks.nativeShowcase)
          SliverToBoxAdapter(
            child: _NativeSectionHeader(
              design: PeekHomeHooks.designParams,
              count: PeekHomeHooks.gridItems?.length ?? 0,
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
              height: widget.sectionHeight, child: widget.sectionHeader),
        ),
        if (widget.children.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: widget.empty)
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(widget.horizontalPadding, 4,
                widget.horizontalPadding, widget.bottomPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                childAspectRatio: _gridRatio,
                mainAxisSpacing: widget.mainAxisSpacing,
                crossAxisSpacing: widget.crossAxisSpacing,
              ),
              delegate: _gridDelegate,
            ),
          ),
      ],
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
