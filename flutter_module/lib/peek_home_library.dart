import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:rfw/rfw.dart';

import 'theme_design.dart';

/// The `peek.home` local widget library: the six custom widgets the
/// ported PeekPro home themes import next to `core.widgets`. The
/// themes are declarative RFW text (assets/peek_home); everything
/// stateful or platform-bound lives here, implemented against the
/// B11/B12 home data the bridge in themed_home.dart feeds in.
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
  /// carousel when the bridge sets it (currently only the disc
  /// style: LeeCat's vinyl Feature is the "SIDE A" disc panel,
  /// recovered verbatim from the design layer's embedded RFW
  /// fragment — see _NativeFeature). Other styles keep the
  /// template hero. PeekStickyGrid renders the Feature as the
  /// top sliver when this is true.
  static bool nativeFeature = false;
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
    });

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

/// LeeCat's native Feature hero for the disc style (vinyl),
/// recovered verbatim from the design layer's embedded RFW
/// fragment: a non-autoplaying carousel (viewportFraction 0.92)
/// of "SIDE A" cards — disc on the left (square aspect, fully
/// round clip, 28px spindle hole with a 5px accent ring),
/// title panel on the right ("SIDE A\n33 RPM", name, "● 落针，
/// 开场"). Height 270.0 is the style's record height in the
/// design layer's per-style config map (pool). Keyed on
/// posterShape 'disc', never on a theme id.
class _NativeFeature extends StatefulWidget {
  const _NativeFeature({required this.items, required this.design});

  static const double height = 270;

  final List<PeekRecommendItem> items;
  final ThemeDesignParams? design;

  @override
  State<_NativeFeature> createState() => _NativeFeatureState();
}

class _NativeFeatureState extends State<_NativeFeature> {
  late final PageController _controller =
      PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeDesignParams? design = widget.design;
    final Color accent = design?.accent ?? const Color(0xFFFFBD70);
    final List<Color> bases = design?.backgroundColors ?? const <Color>[];
    final Color base =
        bases.isNotEmpty ? bases.first : const Color(0xFF302019);
    final String? fontFamily = PeekHomeHooks.titleFontFamily;
    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      itemBuilder: (BuildContext context, int index) {
        final PeekRecommendItem item = widget.items[index];
        return GestureDetector(
          onTap: () => PeekHomeHooks.onRecommendTap?.call(item.index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.53),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: accent.withValues(alpha: 0.27), width: 1),
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
                            _sectionImage(
                              item.pic,
                              design?.surfaceColor ??
                                  const Color(0xFF37474F),
                            ),
                            Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: accent, width: 5),
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
                            color: accent,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            item.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: const Color(0xFFFFF0DE),
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '● 落针，开场',
                          style: TextStyle(color: accent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// LeeCat's native design home renders recommend as a titled
/// section ("为你呈现") below the filter area — not as the RFW
/// template's hero carousel above the pinned header. The
/// exported RFW templates have no such section (their
/// sectionHeader is empty), so the design layer draws it here:
/// title row + a horizontal row of recommend posters whose
/// shape follows the theme's declared designStyle through
/// [ThemeDesignParams.posterShape] — disc for vinyl, ticket
/// stub for 午夜票根， polaroid for 海盐相册， radar rings for
/// 深空雷达， double gold frame for 黑金典藏， and so on (each
/// mapping evidenced by the theme's own description; see
/// theme_design.dart). Never keyed on a theme id.
class _NativeRecommendSection extends StatelessWidget {
  const _NativeRecommendSection({
    required this.items,
    required this.design,
  });

  final List<PeekRecommendItem> items;
  final ThemeDesignParams? design;

  // LeeCat's own section title, verbatim.
  static const String _title = '为你呈现';

  String get _shape => design?.posterShape ?? 'source';

  Color get _accent =>
      design?.accent ?? const Color(0xFFFFBD70);

  // The templates' two text colours: cream on dark bases,
  // graphite on light ones — same pair the Lee sources write
  // into their own captions.
  Color get _textColor {
    final List<Color> base = design?.backgroundColors ?? const <Color>[];
    if (base.isEmpty) return const Color(0xFFFFE8CD);
    return base.first.computeLuminance() < 0.35
        ? const Color(0xFFFFE8CD)
        : const Color(0xFF252A30);
  }

  // Per-shape item geometry: wide styles take a wider cell,
  // the polaroid carries its name inside the white frame.
  double get _itemWidth => switch (_shape) {
        'aurora' => 160,
        'cinema' => 180,
        _ => 108,
      };

  double get _posterHeight => switch (_shape) {
        'disc' => 108,
        'aurora' => 100,
        'cinema' => 112,
        'matrix' => 108,
        _ => 162,
      };

  bool get _nameInside => _shape == 'polaroid';

  double get _itemHeight => _posterHeight + (_nameInside ? 0 : 30);

  Widget _buildPoster(PeekRecommendItem item) {
    final String pic = item.pic;
    final Color placeholder =
        design?.surfaceColor ?? const Color(0xFF37474F);
    final double radius = design?.cardRadius ?? 16;
    switch (_shape) {
      case 'disc':
        return _DiscPoster(pic: pic, accent: _accent, size: 108);
      case 'ticket':
        return _TicketPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'polaroid':
        return _PolaroidPoster(
          pic: pic,
          name: item.name,
          fontFamily: PeekHomeHooks.titleFontFamily,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'radar':
        return _RadarPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'gold':
        return _GoldPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'paper':
        return _PaperPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'polar':
        return _PolarPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
      case 'matrix':
        return _MatrixPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 108,
          placeholder: placeholder,
        );
      case 'aurora':
        return _WidePoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 160,
          height: 100,
          placeholder: placeholder,
        );
      case 'cinema':
        return _WidePoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 180,
          height: 112,
          placeholder: placeholder,
        );
      case 'capsule':
        return _RectPoster(
          pic: pic,
          accent: _accent,
          radius: 30,
          width: 108,
          height: 162,
          placeholder: placeholder,
          glow: true,
        );
      default:
        return _RectPoster(
          pic: pic,
          accent: _accent,
          radius: radius,
          width: 108,
          height: 162,
          placeholder: placeholder,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fontFamily = PeekHomeHooks.titleFontFamily;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _title,
            style: TextStyle(
              fontFamily: fontFamily,
              color: _textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _itemHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 14),
              itemBuilder: (BuildContext context, int index) {
                final PeekRecommendItem item = items[index];
                return GestureDetector(
                  onTap: () =>
                      PeekHomeHooks.onRecommendTap?.call(item.index),
                  child: SizedBox(
                    width: _itemWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildPoster(item),
                        if (!_nameInside) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: _textColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One record disc: circular cover, accent ring, spindle dot.
/// The same treatment the carousel applies to vinyl's hero
/// slides, factored out for the native recommend section.
class _DiscPoster extends StatelessWidget {
  const _DiscPoster({
    required this.pic,
    required this.accent,
    required this.size,
  });

  final String pic;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
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
            child: ClipOval(
              child: pic.isEmpty
                  ? const ColoredBox(color: Color(0xFF37474F))
                  : Image.network(
                      pic,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error,
                              StackTrace? stackTrace) =>
                          const ColoredBox(color: Color(0xFF37474F)),
                    ),
            ),
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
/// cardRadius, 1px accent border). `glow` adds the soft accent
/// shadow the wide/capsule styles carry.
class _RectPoster extends StatelessWidget {
  const _RectPoster({
    required this.pic,
    required this.accent,
    required this.radius,
    required this.width,
    required this.height,
    required this.placeholder,
    this.glow = false,
  });

  final String pic;
  final Color accent;
  final double radius;
  final double width;
  final double height;
  final Color placeholder;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent, width: 1),
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
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
  const _TicketClipper({required this.radius, this.notch = 10});

  final double radius;
  final double notch;

  @override
  Path getClip(Size size) {
    final Path rect = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    final Path left = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(0, size.height / 2), radius: notch));
    final Path right = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width, size.height / 2), radius: notch));
    return Path.combine(
        PathOperation.difference,
        Path.combine(PathOperation.difference, rect, left),
        right);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.radius != radius || old.notch != notch;
}

class _TicketPoster extends StatelessWidget {
  const _TicketPoster({
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipPath(
            clipper: _TicketClipper(radius: radius),
            child: _sectionImage(pic, placeholder),
          ),
          // Dashed perforation across the stub, just above the
          // lower third — the "虚线分隔" of the description.
          Positioned(
            left: 8,
            right: 8,
            bottom: height * 0.28,
            child: _DashedLine(color: accent),
          ),
          CustomPaint(
            painter: _TicketOutlinePainter(radius: radius, accent: accent),
          ),
        ],
      ),
    );
  }
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
  const _DashedLine({required this.color, this.dash = 5, this.gap = 4});

  final Color color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, dash: dash, gap: gap),
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

/// Polaroid (海盐相册 "拍立得卡片 · 留白题签"): white frame,
/// thick bottom strip carrying the title in ink — the name
/// lives inside the frame, not below it.
class _PolaroidPoster extends StatelessWidget {
  const _PolaroidPoster({
    required this.pic,
    required this.name,
    required this.fontFamily,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  final String pic;
  final String name;
  final String? fontFamily;
  final double width;
  final double height;
  final Color placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDF8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(child: _sectionImage(pic, placeholder)),
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: const Color(0xFF252A30),
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Radar (深空雷达 "环线装饰"): concentric accent rings over
/// the poster + a blip dot, clipped to the poster bounds.
class _RadarPoster extends StatelessWidget {
  const _RadarPoster({
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
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _sectionImage(pic, placeholder),
            Center(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: accent.withValues(alpha: 0.35), width: 1),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: accent.withValues(alpha: 0.5), width: 1),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: accent),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: accent, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold frame (黑金典藏 "金线装帧 · 典藏序号"): double gold
/// rule — outer 1px accent + inner 1px at half alpha, inset.
class _GoldPoster extends StatelessWidget {
  const _GoldPoster({
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: _sectionImage(pic, placeholder),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: accent, width: 1),
            ),
          ),
          Positioned(
            left: 5,
            top: 5,
            right: 5,
            bottom: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular((radius - 2).clamp(0, 99)),
                border: Border.all(
                    color: accent.withValues(alpha: 0.55), width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper (玫瑰书房 "细线目录"): the poster with a fine accent
/// rule under it — the editorial list's divider.
class _PaperPoster extends StatelessWidget {
  const _PaperPoster({
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
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _sectionImage(pic, placeholder),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.6), width: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(height: 1, color: accent.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

/// Polar (极地视窗 "蓝色侧签"): a vertical accent tab on the
/// poster's left edge.
class _PolarPoster extends StatelessWidget {
  const _PolarPoster({
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _RectPoster(
            pic: pic,
            accent: accent,
            radius: radius,
            width: width,
            height: height,
            placeholder: placeholder,
          ),
          Positioned(
            left: 0,
            top: 14,
            bottom: 14,
            width: 5,
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matrix (赛博矩阵 "电路网格 · 方卡矩阵"): square card with
/// a faint circuit grid over the image.
class _MatrixPoster extends StatelessWidget {
  const _MatrixPoster({
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
    final Color line = accent.withValues(alpha: 0.18);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _sectionImage(pic, placeholder),
            Positioned(left: width / 3, top: 0, bottom: 0, width: 1,
                child: ColoredBox(color: line)),
            Positioned(left: width * 2 / 3, top: 0, bottom: 0, width: 1,
                child: ColoredBox(color: line)),
            Positioned(top: height / 3, left: 0, right: 0, height: 1,
                child: ColoredBox(color: line)),
            Positioned(top: height * 2 / 3, left: 0, right: 0, height: 1,
                child: ColoredBox(color: line)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: accent, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide poster (极光巨幕 "宽幅影廊" / 午夜影院 "宽幕推荐"):
/// landscape frame with a soft accent glow.
class _WidePoster extends StatelessWidget {
  const _WidePoster({
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
    return _RectPoster(
      pic: pic,
      accent: accent,
      radius: radius,
      width: width,
      height: height,
      placeholder: placeholder,
      glow: true,
    );
  }
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
              height: _NativeFeature.height,
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
        // The native-design recommend section ("为你呈现"):
        // LeeCat's native design home puts it below the filter
        // area, inside the scrolling content. The exported RFW
        // templates carry no such section, so the design layer
        // injects it here when the bridge sets the hook.
        if (PeekHomeHooks.recommendSection != null &&
            PeekHomeHooks.recommendSection!.isNotEmpty)
          SliverToBoxAdapter(
            child: _NativeRecommendSection(
              items: PeekHomeHooks.recommendSection!,
              design: PeekHomeHooks.designParams,
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
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                mainAxisSpacing: widget.mainAxisSpacing,
                crossAxisSpacing: widget.crossAxisSpacing,
              ),
              delegate: SliverChildListDelegate(widget.children),
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
