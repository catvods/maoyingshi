import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:rfw/rfw.dart';

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
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00000000), Color(0xB3000000)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              if (remarks.isNotEmpty)
                Text(
                  remarks,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
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

  Widget _pageChild(int index, double pageWidth) {
    final Widget child = widget.children[index];
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
