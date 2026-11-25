import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import 'home_theme.dart';
import 'pigeon/b11_home_messages.g.dart';

/// Floating glass bottom bar geometry (the native 88dp glass slot):
/// a 64dp capsule, 24dp side insets, floating 16dp above the window
/// bottom (plus the system inset, added at the placement site).
const double glassBarHeight = 64;
const double glassBarFloat = 16;
const double glassBarInsetX = 24;

/// The Dart copy of the native glass bottom bar (HomeActivity +
/// GlassNavBar): a floating capsule (64dp tall, 24dp side insets, 16dp
/// float — the native 88dp glass slot), the same items in the same
/// order, the same selection pill, the same glass parameters from the
/// host snapshot. A horizontal drag on the bar slides the single
/// selection pill with the finger and switches tabs on release
/// (native DampedDragAnimation, simplified — see
/// docs/b8-glass-geometry-fix.md); taps and the live long-press are
/// unchanged. Glass mode layers a BackdropFilter blur +
/// lens-magnification matrix over the wallpaper and scrolled content,
/// with native-aligned color-control washes, a soft-light saturation
/// lift, a top highlight and a dispersion fringe (see
/// docs/b8-home-glass-v2.md); plain mode (glass off) keeps the
/// capsule shape but renders opaque (see docs/b8-home-glass.md).
/// Icons are Material approximations of the native ic_nav_* drawables
/// (see docs/b8-b11-home.md V5).
class GlassBottomBar extends StatefulWidget {
  const GlassBottomBar({
    required this.screen,
    required this.onTap,
    required this.onLongPress,
    this.tintOverride,
    this.accentOverride,
    this.darkOverride,
    this.opacityOverride,
    this.edgeToEdge = false,
    this.bottomInset = 0,
  });

  final B11HomeScreen screen;
  final ValueChanged<B11NavItem> onTap;
  final ValueChanged<B11NavItem> onLongPress;

  /// Home-theme overrides: when a 首页主题 is selected, the bar
  /// follows the theme like it does in the source apps (their
  /// themes restyle the bottom navigation too) instead of keeping
  /// the snapshot's neutral glass look.
  final Color? tintOverride;
  final Color? accentOverride;
  final bool? darkOverride;

  /// Theme navigation opacity (Lee metadata navigationOpacity):
  /// replaces the translucency-derived tint alpha when set.
  final double? opacityOverride;

  /// Theme navigation shape (Lee metadata floatingNavigation):
  /// false renders the bar edge-to-edge (square, flush with the
  /// screen bottom, extending over the gesture inset) instead of
  /// the floating capsule.
  final bool edgeToEdge;

  /// Extra height below the 64dp content row in edge-to-edge mode
  /// (the device's bottom gesture inset), filled with the bar's
  /// own glass/tint so the strip reads as one piece.
  final double bottomInset;

  @override
  State<GlassBottomBar> createState() => GlassBottomBarState();
}

class GlassBottomBarState extends State<GlassBottomBar> {
  /// Pill position in tab-index units (fractional while dragging or
  /// animating). A TweenAnimationBuilder animates toward this target
  /// in ~220ms; during a drag the duration is zero so the pill
  /// follows the finger directly.
  double _pillTarget = 0;

  /// Last animated pill position, cached by the pill builder (plain
  /// field write, no setState): the drag-start position when a slide
  /// is interrupted mid-flight.
  double _pillCurrent = 0;

  bool _dragging = false;
  double _dragStartX = 0;
  double _dragStartIndex = 0;

  @override
  void initState() {
    super.initState();
    final int selected = _selectedIndex(_visibleItems(widget.screen));
    _pillTarget = (selected >= 0 ? selected : 0).toDouble();
    _pillCurrent = _pillTarget;
  }

  @override
  void didUpdateWidget(GlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging) return;
    final int selected = _selectedIndex(_visibleItems(widget.screen));
    if (selected >= 0 && selected.toDouble() != _pillTarget) {
      // Plain assignment: build() runs right after didUpdateWidget,
      // and the new target animates the pill to the selected tab.
      // This also heals a drag-settle the host did not confirm: the
      // pill slides back to the selection the snapshot reports.
      _pillTarget = selected.toDouble();
    }
  }

  List<B11NavItem> _visibleItems(B11HomeScreen screen) =>
      screen.navItems.where((B11NavItem item) => item.visible).toList();

  int _selectedIndex(List<B11NavItem> items) => items.indexWhere(
        (B11NavItem item) => item.token == widget.screen.selectedNavToken,
      );

  IconData _iconFor(String token) {
    switch (token) {
      case 'live':
        return Icons.live_tv_outlined;
      case 'drama':
        return Icons.movie_outlined;
      case 'following':
        return Icons.subscriptions_outlined;
      case 'local_source':
        return Icons.folder_open_outlined;
      case 'setting':
        return Icons.settings_outlined;
      case 'vod':
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final B11HomeScreen screen = widget.screen;
    final List<B11NavItem> items = _visibleItems(screen);
    if (items.isEmpty) return const SizedBox.shrink();
    final bool dark = widget.darkOverride ?? screen.darkMode;
    final Color accent = widget.accentOverride ?? Color(screen.accentColor);
    final Color surface = widget.tintOverride ??
        (dark ? const Color(0xFF1E1E20) : const Color(0xFFF4F4F6));
    final Color unselected = dark
        ? Colors.white.withAlpha(184)
        : Colors.black.withAlpha(158);
    final BorderRadius capsule = widget.edgeToEdge
        ? BorderRadius.zero
        : BorderRadius.circular(glassBarHeight / 2);
    final Widget rowContent = Row(
        children: items.map((B11NavItem item) {
          final bool selected = item.token == screen.selectedNavToken;
          final Color color = selected ? accent : unselected;
          final Widget label = Text(
            item.label,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
          final Widget icon = Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(_iconFor(item.token), size: 22, color: color),
              if (item.badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badgeCount > 99
                          ? '99+'
                          : item.badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
          final Widget content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 2),
              label,
            ],
          );
          // No per-item pill background: the shared sliding pill
          // overlay below draws the selection background, so taps
          // and bar drags share one pill.
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onTap(item),
              onLongPress: () => widget.onLongPress(item),
              child: Center(child: content),
            ),
          );
        }).toList(),
    );
    // Sliding selection pill + bar drag (b8-glass-geometry): one pill
    // overlay shared by taps and drags, positioned in tab-index units
    // so it can follow the finger continuously and animate to the
    // selected tab. The drag recognizer lives on the bar overlay only
    // (self-contained: bar drags never reach the grid, grid drags
    // never reach the bar); the gesture arena disambiguates it from
    // the item tap/long-press recognizers — a press without movement
    // past slop still taps, a hold still long-presses, movement past
    // slop hands the gesture to the drag (native inspectDragGestures
    // semantics). The pill is clipped to the capsule so end-overshoot
    // never pokes outside the bar in the opaque path.
    final Widget barContent = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.maxWidth.isFinite) return rowContent;
        final double cellWidth = constraints.maxWidth / items.length;
        final double pillWidth = (cellWidth - 10).clamp(40.0, 60.0);
        const double pillHeight = 48;
        final int selected = _selectedIndex(items);
        final bool showPill = _dragging || selected >= 0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (DragStartDetails details) {
            setState(() {
              _dragging = true;
              _dragStartX = details.globalPosition.dx;
              _dragStartIndex = _pillCurrent;
              _pillTarget = _pillCurrent;
            });
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            final double raw = _dragStartIndex +
                (details.globalPosition.dx - _dragStartX) / cellWidth;
            final double maxIndex = (items.length - 1).toDouble();
            final double damped = raw < 0
                ? raw * 0.3
                : (raw > maxIndex
                    ? maxIndex + (raw - maxIndex) * 0.3
                    : raw);
            setState(() => _pillTarget = damped);
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            final int target =
                _pillTarget.round().clamp(0, items.length - 1);
            final bool changed = target != selected;
            setState(() {
              _dragging = false;
              _pillTarget = target.toDouble();
            });
            if (changed) widget.onTap(items[target]);
          },
          onHorizontalDragCancel: () {
            setState(() {
              _dragging = false;
              _pillTarget = (selected >= 0 ? selected : 0).toDouble();
            });
          },
          child: ClipRRect(
            borderRadius: capsule,
            child: Stack(
              children: [
                if (showPill)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _pillTarget),
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          // Silver-gray selection pill (the accent
                          // blue read as a watermark smudge on the
                          // glass; the selected icon/label keep the
                          // accent color).
                          color: dark
                              ? const Color(0xFF9AA0A6).withAlpha(80)
                              : const Color(0xFFADB3BC).withAlpha(110),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    builder: (BuildContext context, double pillIndex,
                        Widget? child) {
                      // Cache only (no setState): the drag-start
                      // position when a slide is interrupted.
                      _pillCurrent = pillIndex;
                      return Positioned(
                        left:
                            (pillIndex + 0.5) * cellWidth - pillWidth / 2,
                        top: (glassBarHeight - pillHeight) / 2,
                        width: pillWidth,
                        height: pillHeight,
                        child: child!,
                      );
                    },
                  ),
                rowContent,
              ],
            ),
          ),
        );
      },
    );
    final double blur = screen.glassBlurDp.toDouble();
    if (!screen.glassEnabled || blur <= 0) {
      // Glass off: opaque capsule, unchanged (b8-home-glass D3).
      return Container(
        height: glassBarHeight + widget.bottomInset,
        decoration: BoxDecoration(
          color: widget.opacityOverride == null
              ? surface
              : surface.withValues(alpha: widget.opacityOverride!),
          borderRadius: capsule,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: barContent,
        ),
      );
    }
    // Liquid-glass parameters, aligned to the native formulas in
    // LiquidGlassConfig.kt (translucency t in 0..1; see
    // docs/b8-home-glass-v2.md). At the defaults (t = 0.5) the
    // brightness/contrast terms are neutral and saturation is 1.5.
    final double t = screen.glassTranslucency / 100;
    final double tintAlpha =
        (widget.opacityOverride ?? (0.4 * (2 - 2 * t))).clamp(0.05, 0.9);
    final double brightness = (0.5 - t).clamp(0.0, 0.5) * 0.12;
    final double contrast = 1 - (0.5 - t).clamp(0.0, 0.5) * 0.25;
    final double saturation = 1.5 - (t - 0.5).clamp(0.0, 0.5);
    // Saturation lift: a second blurred backdrop composited with
    // soft-light over the first (see the Stack below). Strength
    // follows the native saturation term; zero when saturation is 1.
    // The lift is kept very low: at higher strengths the soft-light
    // copy smears the backdrop's colors into a muddy haze and the
    // glass reads dirty instead of clear.
    final double liftAlpha = ((saturation - 1) * 0.3).clamp(0.0, 0.10);
    // Lens approximation: a uniform magnification about the bar
    // center. Native refracts up to distortionDp at the rim; the
    // uniform scale keeps the sliding misalignment cue — content
    // inside the bar no longer lines up with content outside it.
    final double lensScale =
        1 + (screen.glassDistortionDp / 600).clamp(0.0, 0.08);
    final bool useLens = screen.glassDistortionDp > 0 && lensScale > 1.001;
    return Container(
      // Drop shadow outside the clip: two layers for depth — a soft
      // ambient shadow that lifts the capsule off the wallpaper and a
      // tighter contact shadow that grounds its lower edge. (Was a
      // single 12dp shadow; the bar read flat against bright
      // wallpapers.)
      decoration: BoxDecoration(
        borderRadius: capsule,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(dark ? 64 : 36),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(dark ? 70 : 44),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: capsule,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            ImageFilter filter =
                ImageFilter.blur(sigmaX: blur, sigmaY: blur);
            if (useLens && constraints.maxWidth.isFinite) {
              final double cx = constraints.maxWidth / 2;
              const double cy = glassBarHeight / 2;
              final Matrix4 lens = Matrix4.identity()
                ..translateByVector3(Vector3(cx, cy, 0.0))
                ..scaleByVector3(Vector3.all(lensScale))
                ..translateByVector3(Vector3(-cx, -cy, 0.0));
              filter = ImageFilter.compose(
                outer: filter,
                inner: ImageFilter.matrix(
                  lens.storage,
                  filterQuality: FilterQuality.medium,
                ),
              );
            }
            return BackdropFilter(
              filter: filter,
              child: SizedBox(
                height: glassBarHeight + widget.bottomInset,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        // Clean frosted tint: in light mode the
                        // surface color is blended toward white, so
                        // the bar reads as bright, clear glass rather
                        // than tinted plastic over the backdrop.
                        color: (dark
                                ? surface
                                : Color.lerp(surface, Colors.white, 0.45)!)
                            .withAlpha((tintAlpha * 255).round()),
                      ),
                    ),
                    if (liftAlpha > 0.01)
                      Positioned.fill(
                        child: Opacity(
                          opacity: liftAlpha,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: blur,
                              sigmaY: blur,
                            ),
                            blendMode: BlendMode.softLight,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    if (brightness > 0.001)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white
                              .withAlpha((brightness * 255).round()),
                        ),
                      ),
                    if (contrast < 0.999)
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF808080).withAlpha(
                            ((1 - contrast) * 0.5 * 255).round(),
                          ),
                        ),
                      ),
                    Positioned.fill(child: _buildHighlight()),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: glassBarHeight,
                      child: barContent,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Top-edge highlight + dispersion fringe (native Highlight.Default
  /// approximation). The gradient is a static rim: white fading down
  /// from the top edge, with a faint cyan top / magenta bottom split
  /// when dispersion is on. Painted above the tint, below the icons.
  Widget _buildHighlight() {
    final bool dispersion = widget.screen.glassDispersion;
    // A bright top rim only — light catching the capsule's top edge.
    // (A shaded lower edge was tried for thickness and removed: it
    // grayed the lower half of the bar and made the glass look
    // dirty. Depth comes from the drop shadow, not from darkening
    // the glass itself.)
    final double topAlpha =
        (widget.darkOverride ?? widget.screen.darkMode) ? 0.22 : 0.34;
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.edgeToEdge
            ? BorderRadius.zero
            : BorderRadius.circular(glassBarHeight / 2),
        border: Border.all(
          color: Colors.white.withAlpha(36),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dispersion
              ? [
                  const Color(0xFFE8FFFF).withAlpha(48),
                  Colors.white.withAlpha((topAlpha * 255).round()),
                  Colors.transparent,
                  const Color(0xFFFFE8F0).withAlpha(20),
                ]
              : [
                  Colors.white.withAlpha((topAlpha * 255).round()),
                  Colors.transparent,
                ],
          stops: dispersion
              ? const [0.0, 0.18, 0.45, 1.0]
              : const [0.0, 0.45],
        ),
      ),
    );
  }
}

/// Shell-level host for [GlassBottomBar]: keeps the bar resident
/// across top-level page switches (it lives in MaterialApp's builder,
/// above the root Navigator, so a page swap never unmounts it) and
/// hides it while the user scrolls down through content; scrolling
/// back up brings it back. The bar renders on the main section
/// routes only (home, lab, the settings family); player, detail and
/// other full-screen routes keep the screen to themselves.
///
/// Items, selection and glass parameters come from the same host
/// snapshot the home page uses (B11HostApi.getHomeShell), and taps
/// take the same host path the home page's bar took
/// (openBottomBarItem), so behavior is unchanged — only the bar's
/// owner moved.
class ShellGlassBarHost extends StatefulWidget {
  const ShellGlassBarHost({
    super.key,
    required this.routeListenable,
    required this.child,
  });

  /// The shell's current top-level route (main.dart's shellRoute).
  final ValueListenable<String> routeListenable;
  final Widget child;

  @override
  State<ShellGlassBarHost> createState() => _ShellGlassBarHostState();
}

class _ShellGlassBarHostState extends State<ShellGlassBarHost> {
  final B11HostApi _api = B11HostApi();
  B11HomeScreen? _screen;
  bool _hidden = false;
  String _route = '/';
  String _themeId = '';

  @override
  void initState() {
    super.initState();
    _route = widget.routeListenable.value;
    widget.routeListenable.addListener(_onRouteChanged);
    _themeId = homeThemeId.value;
    homeThemeId.addListener(_onThemeChanged);
    _load();
  }

  @override
  void dispose() {
    widget.routeListenable.removeListener(_onRouteChanged);
    homeThemeId.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() => _themeId = homeThemeId.value);
  }

  void _onRouteChanged() {
    if (!mounted) return;
    setState(() {
      _route = widget.routeListenable.value;
      _hidden = false;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final B11HomeScreen screen = await _api.getHomeShell();
      if (mounted) setState(() => _screen = screen);
    } catch (_) {
      // Host not answering (native-home fallback): keep the last
      // snapshot; the bar simply stays as it was.
    }
  }

  bool get _barRoute =>
      _route == '/home' ||
      _route == '/lab' ||
      _route == '/keep' ||
      _route.startsWith('/settings');

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      final double delta = notification.scrollDelta ?? 0;
      if (delta > 3 && !_hidden) {
        setState(() => _hidden = true);
      } else if (delta < -3 && _hidden) {
        setState(() => _hidden = false);
      }
    }
    return false;
  }

  void _onTap(B11NavItem item) {
    // On the home page itself, 'vod' is the current section (the
    // home page's bar treated it as a no-op); from anywhere else it
    // goes through the host like every other item.
    if (item.token == 'vod' && _route == '/home') return;
    unawaited(_api.openBottomBarItem(item.token));
    // A page switch reloads the snapshot through the route listener;
    // when the route does not change (a home tab switch), refresh
    // the selection shortly after instead.
    Future<void>.delayed(const Duration(milliseconds: 400), _load);
    Future<void>.delayed(const Duration(milliseconds: 1000), _load);
  }

  void _onLongPress(B11NavItem item) {
    unawaited(_api.longPressBottomBarItem(item.token));
  }

  @override
  Widget build(BuildContext context) {
    final B11HomeScreen? screen = _screen;
    final bool show = _barRoute && screen != null;
    final HomeThemeEntry entry = homeThemeEntry(_themeId);
    // Theme navigation shape (Lee metadata): floating themes keep
    // the capsule; the rest run the bar edge-to-edge over the
    // gesture inset.
    final bool floating = entry.barFloating ?? true;
    final double inset = MediaQuery.paddingOf(context).bottom;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          if (show)
            Positioned(
              left: floating ? glassBarInsetX : 0,
              right: floating ? glassBarInsetX : 0,
              bottom: floating ? glassBarFloat + inset : 0,
              child: IgnorePointer(
                ignoring: _hidden,
                child: AnimatedSlide(
                  offset: _hidden ? const Offset(0, 1.8) : Offset.zero,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  // Material ancestor: at shell level there is
                  // no Scaffold above the bar, and without one
                  // its labels fall back to the framework's
                  // yellow underline text style.
                  child: Material(
                    type: MaterialType.transparency,
                    child: GlassBottomBar(
                      screen: screen,
                      onTap: _onTap,
                      onLongPress: _onLongPress,
                      tintOverride: entry.barTint,
                      accentOverride: entry.barAccent,
                      darkOverride:
                          entry.barTint == null ? null : entry.dark,
                      opacityOverride: entry.barOpacity,
                      edgeToEdge: !floating,
                      bottomInset: floating ? 0 : inset,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
