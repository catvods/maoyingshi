import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Global UI configuration shared by every Flutter screen in the app:
/// the liquid-glass parameters and the user's theme colors.
///
/// Both are owned by the host (Setting + ThemeController) and delivered
/// over a raw MethodChannel registered by C1ScreenActivity, mirroring
/// the c1_relaunch pattern (no Pigeon contract). Loaded once in main()
/// before runApp, refreshed whenever a top route is asserted (so
/// returning from a native editor or a settings toggle is picked up)
/// and after the personal page changes a glass setting.
///
/// Before this existed, only the home screen received the glass
/// parameters (in its B11 snapshot) and the Flutter theme was a
/// hard-coded seed color, so the liquid-glass switch governed one
/// screen and the native theme-color editor changed nothing the
/// Flutter UI painted.
class UiConfig {
  const UiConfig({
    required this.glassEnabled,
    required this.globalGlassEnabled,
    required this.globalBlur,
    required this.globalTranslucency,
    required this.glassBlur,
    required this.glassDistortion,
    required this.glassTranslucency,
    required this.glassDispersion,
    required this.darkMode,
    required this.scheme,
  });

  /// Liquid glass master switch (Setting.isLiquidGlass). Gates the
  /// home bottom bar's own glass; the all-components surfaces key
  /// off [globalGlassEnabled] instead, so the two switch separately.
  final bool glassEnabled;

  /// Global glass switch (Setting.isGlassGlobal, default off): the
  /// all-components [GlassSurface] treatment on cards, bars and
  /// chips across the Flutter UI. Independent of [glassEnabled] —
  /// and its parameters are independent too: [globalBlur] and
  /// [globalTranslucency] below, never the bar's values.
  final bool globalGlassEnabled;

  /// Backdrop blur sigma in dp for the global surfaces
  /// (Setting.getGlassGlobalBlur, 0..40).
  final double globalBlur;

  /// Translucency 0..1 for the global surfaces
  /// (Setting.getGlassGlobalTranslucency / 100).
  final double globalTranslucency;

  /// Backdrop blur sigma in dp (Setting.getGlassBlur, 0..40).
  final double glassBlur;

  /// Lens distortion dp (Setting.getGlassDistortion, 0..30). The
  /// shared surface does not refract; the home bar keeps its own
  /// lens. Retained here so every consumer reads one config object.
  final double glassDistortion;

  /// Translucency 0..1 (Setting.getGlassTranslucency / 100).
  final double glassTranslucency;

  /// Chromatic fringe flag (Setting.isGlassDispersion). Retained
  /// in the config contract; the rim gradient it once tinted was
  /// removed (it read as a gray band), so nothing consumes it here.
  final bool glassDispersion;

  final bool darkMode;

  /// The user's theme colors as a Material color scheme, built from
  /// the host's current ThemeTokens. Null until the host answers, in
  /// which case main.dart falls back to its historical seed theme.
  final ColorScheme? scheme;

  /// Defaults matching the host's own defaults, used before the first
  /// channel answer (and if the channel is unavailable).
  factory UiConfig.fallback() => const UiConfig(
        glassEnabled: true,
        globalGlassEnabled: false,
        globalBlur: 10,
        globalTranslucency: 0.5,
        glassBlur: 10,
        glassDistortion: 30,
        glassTranslucency: 0.5,
        glassDispersion: false,
        darkMode: false,
        scheme: null,
      );

  /// The tint alpha the native liquid-glass formula assigns the
  /// surface color (LiquidGlassConfig via the home bar): stronger tint
  /// when translucency is low.
  double get tintAlpha => (0.4 * (2 - 2 * glassTranslucency)).clamp(0.05, 0.8);

  /// True when glass surfaces should actually blur.
  bool get glassActive => glassEnabled && glassBlur > 0;

  /// The tint alpha for the global surfaces: the same formula as
  /// [tintAlpha], fed with the global translucency instead of the
  /// bar's, so the two chains never influence each other.
  double get globalTintAlpha =>
      (0.4 * (2 - 2 * globalTranslucency)).clamp(0.05, 0.8);

  /// True when the all-components glass surfaces should blur: the
  /// global switch is on and a global blur is configured. The shared
  /// surfaces key off this, never off [glassActive], so the bottom
  /// bar's switch can neither enable nor disable them.
  bool get globalGlassActive => globalGlassEnabled && globalBlur > 0;
}

/// The live configuration. Widgets that paint glass surfaces listen to
/// this, so flipping the switch repaints every screen at once.
final ValueNotifier<UiConfig> uiConfig =
    ValueNotifier<UiConfig>(UiConfig.fallback());

const MethodChannel _uiConfigChannel =
    MethodChannel('com.github.maoyingshi.osc.tv/ui_config');

Color _argb(Object? value) =>
    Color(((value as num?)?.toInt() ?? 0) & 0xFFFFFFFF);

/// Fetches the current configuration from the host and publishes it.
/// Never throws: on any failure the previous config stays in place.
Future<void> loadUiConfig() async {
  try {
    final Map<Object?, Object?>? map =
        await _uiConfigChannel.invokeMapMethod<Object?, Object?>(
      'getUiConfig',
    );
    if (map == null) return;
    final bool dark = map['darkMode'] == true;
    final ColorScheme scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: _argb(map['primary']),
      onPrimary: _argb(map['onPrimary']),
      primaryContainer: _argb(map['primaryContainer']),
      onPrimaryContainer: _argb(map['onPrimaryContainer']),
      secondary: _argb(map['secondary']),
      onSecondary: _argb(map['onSecondary']),
      secondaryContainer: _argb(map['secondaryContainer']),
      onSecondaryContainer: _argb(map['onSecondaryContainer']),
      tertiary: _argb(map['tertiary']),
      onTertiary: _argb(map['onTertiary']),
      error: _argb(map['error']),
      onError: _argb(map['onError']),
      errorContainer: _argb(map['errorContainer']),
      onErrorContainer: _argb(map['onErrorContainer']),
      surface: _argb(map['surface']),
      onSurface: _argb(map['onSurface']),
      onSurfaceVariant: _argb(map['onSurfaceVariant']),
      outline: _argb(map['outline']),
      outlineVariant: _argb(map['outlineVariant']),
      surfaceContainerLowest: _argb(map['surfaceContainerLowest']),
      surfaceContainerLow: _argb(map['surfaceContainerLow']),
      surfaceContainer: _argb(map['surfaceContainer']),
      surfaceContainerHigh: _argb(map['surfaceContainerHigh']),
      surfaceContainerHighest: _argb(map['surfaceContainerHighest']),
      surfaceDim: _argb(map['surfaceDim']),
      surfaceBright: _argb(map['surfaceBright']),
      inverseSurface: _argb(map['inverseSurface']),
      onInverseSurface: _argb(map['inverseOnSurface']),
      inversePrimary: _argb(map['inversePrimary']),
      scrim: _argb(map['scrim']),
      shadow: _argb(map['shadow']),
    );
    uiConfig.value = UiConfig(
      glassEnabled: map['glassEnabled'] == true,
      globalGlassEnabled: map['glassGlobalEnabled'] == true,
      globalBlur: ((map['glassGlobalBlurDp'] as num?)?.toDouble() ?? 10),
      globalTranslucency:
          (((map['glassGlobalTranslucency'] as num?)?.toDouble() ?? 50) /
                  100)
              .clamp(0.0, 1.0),
      glassBlur: ((map['glassBlurDp'] as num?)?.toDouble() ?? 10),
      glassDistortion: ((map['glassDistortionDp'] as num?)?.toDouble() ?? 30),
      glassTranslucency:
          (((map['glassTranslucency'] as num?)?.toDouble() ?? 50) / 100)
              .clamp(0.0, 1.0),
      glassDispersion: map['glassDispersion'] == true,
      darkMode: dark,
      scheme: scheme,
    );
  } catch (_) {
    // Keep the previous config; a later route assertion retries.
  }
}

/// Marks a subtree whose backdrop is already being blurred by an
/// ancestor [GlassSurface]. A nested [GlassSurface] inside the scope
/// paints its tint and rim only, without a second [BackdropFilter]:
/// stacked backdrop filters over an already-blurred backdrop buy
/// nothing visually, cost a full extra blur pass each, and were a
/// prime suspect in the stutter that got the first all-components
/// glass rollout reverted.
class _GlassBlurScope extends InheritedWidget {
  const _GlassBlurScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassBlurScope>() != null;

  @override
  bool updateShouldNotify(_GlassBlurScope oldWidget) => false;
}

/// A surface painted with the app's liquid glass when the global
/// glass switch is on, and with its plain solid color when it is
/// off.
///
/// Mirrors the home bar's recipe (b8-home-glass): a backdrop blur
/// under a translucent tint of the surface color, framed by a
/// defined 1px rim (no highlight gradient — a sheen read as a
/// gray band on every surface and was removed). The frame is
/// mode-aware: white in dark mode, black in light mode, each at
/// an alpha chosen to stay clearly visible — a white-only frame
/// is invisible on light glass at any alpha, and a flat 1px
/// hairline reads as an edge, never as a band. Glass off (or
/// blur 0) renders the
/// exact solid surface the caller would have painted before, so the
/// switch is a pure appearance change. The on/off, the blur and
/// the tint all come from the global glass parameters (their own
/// Setting values), never from the bottom bar's chain.
///
/// Performance shape (scrolling lists stuttered with the switch
/// on):
/// - The glass result is wrapped in a [RepaintBoundary], so one
///   list row's repaint never invalidates its neighbours.
/// - A surface measured below the blur threshold (see
///   [_glassBlurMinHeight] / [_glassBlurMinArea]) skips its
///   [BackdropFilter] and paints tint + frame only: at that size
///   a blur is indistinguishable from the tint, while every
///   filter still costs a full save-layer blur pass. The poster
///   badges and title strips on media cards are the main case —
///   a scrolling grid used to carry up to three backdrop
///   filters per card.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.solidColor,
    this.tintColor,
    this.padding,
    this.showRim = true,
  });

  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  /// Color painted when glass is off. Defaults to the theme surface.
  final Color? solidColor;

  /// Base color the glass tint is derived from. Defaults to
  /// [solidColor].
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;
  final bool showRim;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

/// Painted height under which a [GlassSurface] skips its backdrop
/// blur: 32dp is about three times the default sigma (10), so the
/// whole surface is edge and the blur has nothing left to soften
/// that the tint does not already cover.
const double _glassBlurMinHeight = 32;

/// Painted area under which a [GlassSurface] skips its backdrop
/// blur even when it is tall enough: 8192dp² (say 128×64) is
/// about the smallest patch whose blur reads as more than its
/// tint.
const double _glassBlurMinArea = 8192;

class _GlassSurfaceState extends State<GlassSurface> {
  final GlobalKey _surfaceKey = GlobalKey();

  /// Whether the last measured painted size fell below the blur
  /// threshold. Starts false (blur, the historical behaviour);
  /// a small surface settles into tint-only a frame after it is
  /// first laid out — an invisible swap at that size.
  bool _belowBlurThreshold = false;
  bool _measureQueued = false;

  /// Schedules a one-off painted-size read after the next frame.
  /// Called from the builder below, so config flips and parent
  /// rebuilds re-measure; the queued flag keeps it to one
  /// callback per frame, and state only changes when the
  /// verdict flips.
  void _queueMeasure() {
    if (_measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (!mounted) return;
      final Size? size = _surfaceKey.currentContext?.size;
      if (size == null) return;
      final bool small = size.height < _glassBlurMinHeight ||
          size.width * size.height < _glassBlurMinArea;
      if (small != _belowBlurThreshold) {
        setState(() => _belowBlurThreshold = small);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Whether an ancestor GlassSurface is already blurring the
    // backdrop; read here because the builder below runs under this
    // widget, where the scope it installs must not count itself.
    final bool nested = _GlassBlurScope.of(context);
    return ValueListenableBuilder<UiConfig>(
      valueListenable: uiConfig,
      builder: (BuildContext context, UiConfig cfg, Widget? _) {
        final BorderRadiusGeometry radius =
            widget.borderRadius ?? BorderRadius.zero;
        final Color solid =
            widget.solidColor ?? Theme.of(context).colorScheme.surface;
        if (!cfg.globalGlassActive) {
          return Container(
            decoration: BoxDecoration(color: solid, borderRadius: radius),
            padding: widget.padding,
            child: widget.child,
          );
        }
        _queueMeasure();
        final Color base = widget.tintColor ?? solid;
        final double brightness =
            (0.5 - cfg.globalTranslucency).clamp(0.0, 0.5) * 0.12;
        final Widget stack = Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: base.withAlpha((cfg.globalTintAlpha * 255).round()),
              ),
            ),
            if (brightness > 0.001)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withAlpha((brightness * 255).round()),
                ),
              ),
            Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
            if (widget.showRim)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius.resolve(
                        Directionality.of(context),
                      ),
                      border: Border.all(
                        // The frame: a flat 1px hairline, no
                        // gradient, in the shared frame color
                        // (see _glassFrameColor).
                        color: _glassFrameColor(cfg.darkMode),
                        width: 1,
                      ),
                      // Deliberately no highlight gradient here:
                      // a top sheen read as a gray band across
                      // every glass surface (user-reported). The
                      // rim is the 1px border only; the glass
                      // itself is the blur + tint below.
                    ),
                  ),
                ),
              ),
          ],
        );
        // Anti-nesting: inside an already-blurred GlassSurface, add
        // only the tint/rim layer — no second BackdropFilter (see
        // _GlassBlurScope). Below-threshold surfaces take the same
        // filterless path (see _glassBlurMinHeight). The scope is
        // installed only when the backdrop really is blurred, by
        // this surface or an ancestor, so a small tint-only
        // surface does not make its children skip a blur they
        // still need.
        final bool blur = !nested && !_belowBlurThreshold;
        final Widget body = blur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: cfg.globalBlur,
                  sigmaY: cfg.globalBlur,
                ),
                child: stack,
              )
            : stack;
        final Widget scoped =
            (blur || nested) ? _GlassBlurScope(child: body) : body;
        // RepaintBoundary: in a scrolling list each surface's
        // glass becomes its own layer, so a neighbour's repaint
        // (a splash, a progress tick) never re-rasterises it.
        return RepaintBoundary(
          child: ClipRRect(
            key: _surfaceKey,
            borderRadius: radius,
            child: scoped,
          ),
        );
      },
    );
  }
}

/// The background color for a Material-style button or chip whose
/// style only takes a color: the translucent glass tint while the
/// global glass switch is on, the plain color while it is off.
/// Large surfaces should use [GlassSurface] so they get the real
/// backdrop blur.
Color glassButtonColor(BuildContext context, Color base) {
  final UiConfig cfg = uiConfig.value;
  if (!cfg.globalGlassActive) return base;
  return base.withAlpha((cfg.globalTintAlpha * 255).round());
}

/// The one frame color shared by [GlassSurface]'s rim and every
/// framed control below: white at alpha 72 in dark mode (the home
/// bar's alpha-36 rim, doubled, so it clearly reads), black at
/// alpha 36 in light mode — a white frame on light glass stays
/// invisible no matter the alpha, and a flat 1px hairline reads
/// as an edge, never as a band.
Color _glassFrameColor(bool darkMode) =>
    darkMode ? Colors.white.withAlpha(72) : Colors.black.withAlpha(36);

/// The frame as a [BorderSide] for tint-only controls that have a
/// border slot (a button's `styleFrom(side:)`, a chip's `side`):
/// the [GlassSurface] frame while the global glass switch is on,
/// null while it is off, so an inactive control keeps exactly the
/// border (or lack of one) it had before.
BorderSide? glassFrameSide(BuildContext context) {
  final UiConfig cfg = uiConfig.value;
  if (!cfg.globalGlassActive) return null;
  return BorderSide(color: _glassFrameColor(cfg.darkMode), width: 1);
}

/// The frame as an [OutlineInputBorder] for text fields that
/// already draw an outline border: identical to a default
/// `OutlineInputBorder()` while the global glass is off (same
/// default side, same default 4dp radius unless [borderRadius]
/// is given), the glass frame while it is on.
OutlineInputBorder glassInputBorder(
  BuildContext context, {
  BorderRadius? borderRadius,
}) {
  final BorderSide? side = glassFrameSide(context);
  return OutlineInputBorder(
    borderRadius:
        borderRadius ?? const BorderRadius.all(Radius.circular(4)),
    borderSide: side ?? const BorderSide(),
  );
}

/// The frame as a [Border] for a [BoxDecoration] that has no
/// border yet: null while the global glass is off.
Border? glassFrameBoxBorder(BuildContext context) {
  final BorderSide? side = glassFrameSide(context);
  if (side == null) return null;
  return Border.all(color: side.color, width: side.width);
}

/// The frame as a rounded-rectangle shape for a [Card] that does
/// not set its own shape: null while the global glass is off (the
/// card keeps its theme shape), a framed shape with the given
/// corner radius while it is on.
RoundedRectangleBorder? glassFrameShape(
  BuildContext context,
  double radius,
) {
  final BorderSide? side = glassFrameSide(context);
  if (side == null) return null;
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );
}

/// Wraps dialog content in a [GlassSurface]-backed transparent
/// [Dialog], so dialogs join the same glass treatment.
Widget glassDialog({required Widget child, double radius = 28}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
    child: GlassSurface(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    ),
  );
}
