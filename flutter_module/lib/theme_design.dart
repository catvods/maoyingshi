import 'dart:convert';

import 'package:material_ui/material_ui.dart';

/// The design-layer parameters of a theme: the `// leecat-theme:`
/// meta header parsed into typed values, and the rendering
/// decisions derived from them.
///
/// LeeCat's own app carries the same model (its string table has
/// every meta key plus a HomeThemeDesignStyle enum): the RFW source
/// is the theme's structure, and this meta is what its design layer
/// consumes around the structure — the page background gradient,
/// the surface/accent colours, the design style's poster
/// treatment, the title font. Our port originally read only the
/// navigation fields (into the picker's hard-coded catalog) and,
/// for parametric editor themes, the component data fields; the
/// rest of the meta was dead text, which is why a theme like
/// 落日唱片 changed colours but kept a washed-out page and plain
/// rectangular posters. This class is the single consumption
/// channel: the bridge parses it for every meta-carrying theme and
/// the themed home + peek library render from it.
class ThemeDesignParams {
  const ThemeDesignParams({
    this.name,
    this.description,
    this.accent,
    this.backgroundColors = const <Color>[],
    this.surfaceColor,
    this.cardRadius,
    this.layout,
    this.hero,
    this.designStyle,
    this.titleFont,
    this.backgroundOpacity,
    this.panelOpacity,
    this.navigationOpacity,
    this.floatingNavigation,
    this.glassNavigation,
    this.liquidGlass = false,
    this.cinema = false,
    this.nativeDesign = false,
    this.parametric = false,
    this.heroHeight,
    this.gridColumns,
  });

  final String? name;
  final String? description;
  final Color? accent;

  /// The page base: the design layer paints this pair as the
  /// home's full-page gradient (top to bottom). The RFW templates
  /// never paint a page background themselves — every surface in
  /// them is a translucent tint written against this base.
  final List<Color> backgroundColors;
  final Color? surfaceColor;
  final double? cardRadius;
  final String? layout;

  /// Whether the recommend hero shows at all (liquid-glass's meta
  /// turns it off; the templates' hero switch reads the bridge's
  /// hasRecommend, which this feeds).
  final bool? hero;

  /// LeeCat's HomeThemeDesignStyle: names the design layer's
  /// per-style treatments (vinyl = record discs, cinema = poster
  /// wall, ticket = stub layout, ...). The treatments are
  /// rendered from the style's own description + accent/radius
  /// (see [posterShape]); exact native geometry stays
  /// evidence-limited (compiled into libapp.so).
  final String? designStyle;
  final String? titleFont;
  final double? backgroundOpacity;
  final double? panelOpacity;
  final double? navigationOpacity;
  final bool? floatingNavigation;
  final bool? glassNavigation;
  final bool liquidGlass;
  final bool cinema;
  final bool nativeDesign;

  /// The parametric editor's marker: only editor-materialized
  /// themes inject layout through the bridge's data fields (the
  /// built-in templates embody their layout in their source).
  final bool parametric;

  /// Editor-only component parameters (present solely in
  /// parametric metas).
  final double? heroHeight;
  final int? gridColumns;

  /// The poster treatment the design layer applies for this
  /// style. Each mapping is evidenced by the theme's own
  /// `description` in its leecat-theme meta (first-hand,
  /// LeeCat's own words) — e.g. vinyl 唱片式推荐 · 圆盘封面 →
  /// 'disc'; ticket 入场票推荐 · 虚线分隔 → 'ticket'; album
  /// 拍立得卡片 · 留白题签 → 'polaroid'; radar 环线装饰 →
  /// 'radar'; noir 金线装帧 · 典藏序号 → 'gold'; paper 细线
  /// 目录 → 'paper'; polar 蓝色侧签 → 'polar'; matrix 电路
  /// 网格 · 方卡矩阵 → 'matrix'; aurora 宽幅影廊 → 'aurora';
  /// cinema 宽幕推荐 · 沉浸海报墙 → 'cinema'; rose 非对称
  /// 浮岛 · 胶囊控件 → 'capsule'. 'source' (classic styles
  /// and anything unmapped) keeps the template's own Poster
  /// widget. The exact native geometry (notch depths, ring
  /// radii, serial placement) is compiled into LeeCat's
  /// libapp.so and not recoverable — the treatments here are
  /// the description's own named device, rendered in the
  /// theme's own accent/radius, never invented per theme id.
  String get posterShape => switch (designStyle) {
        'vinyl' => 'disc',
        'ticket' => 'ticket',
        'album' => 'polaroid',
        'radar' => 'radar',
        'noir' => 'gold',
        'paper' => 'paper',
        'polar' => 'polar',
        'matrix' => 'matrix',
        'aurora' => 'aurora',
        'cinema' => 'cinema',
        'rose' => 'capsule',
        _ => 'source',
      };

  /// The font family the title font parameter resolves to. The
  /// serif and wenkai families are the very font files LeeCat
  /// bundles (assets/fonts, SIL OFL 1.1), registered in the
  /// module pubspec under the same family names LeeCat uses.
  String? get titleFontFamily => switch (titleFont) {
        'serif' => 'NotoSerifSC',
        'wenkai' => 'LXGWWenKaiLite',
        'mono' => 'monospace',
        _ => null,
      };

  /// The full-page background the design layer paints behind the
  /// themed home: the background pair as a vertical gradient (a
  /// single colour paints flat). Null when the theme declares no
  /// background (the PeekPro themes paint their own).
  BoxDecoration? get backgroundDecoration {
    if (backgroundColors.isEmpty) return null;
    if (backgroundColors.length == 1) {
      return BoxDecoration(color: backgroundColors.first);
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: backgroundColors,
      ),
    );
  }

  static Color? _hex(Object? value) {
    if (value is! String) return null;
    String h = value.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final int? v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  /// Parses the leecat meta header out of a theme source's first
  /// line. Returns null when the source carries no meta (the
  /// PeekPro themes) or the header is malformed.
  static ThemeDesignParams? fromSource(String text) {
    final int nl = text.indexOf('\n');
    final String first = (nl >= 0 ? text.substring(0, nl) : text).trim();
    if (!first.contains('leecat-theme:')) return null;
    final int open = first.indexOf('{');
    final int close = first.lastIndexOf('}');
    if (open < 0 || close <= open) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(first.substring(open, close + 1));
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final Map<dynamic, dynamic> meta = decoded;
    String? string(String key) {
      final Object? v = meta[key];
      return v is String ? v : null;
    }

    double? number(String key) {
      final Object? v = meta[key];
      return v is num ? v.toDouble() : null;
    }

    bool? flag(String key) {
      final Object? v = meta[key];
      return v is bool ? v : null;
    }

    final List<Color> backgrounds = <Color>[];
    final Object? rawBackgrounds = meta['backgroundColors'];
    if (rawBackgrounds is List) {
      for (final Object? entry in rawBackgrounds) {
        final Color? color = _hex(entry);
        if (color != null) backgrounds.add(color);
      }
    }
    final double? columns = number('gridColumns');
    return ThemeDesignParams(
      name: string('name'),
      description: string('description'),
      accent: _hex(meta['accent']),
      backgroundColors: backgrounds,
      surfaceColor: _hex(meta['surfaceColor']),
      cardRadius: number('cardRadius'),
      layout: string('layout'),
      hero: flag('hero'),
      designStyle: string('designStyle'),
      titleFont: string('titleFont'),
      backgroundOpacity: number('backgroundOpacity'),
      panelOpacity: number('panelOpacity'),
      navigationOpacity: number('navigationOpacity'),
      floatingNavigation: flag('floatingNavigation'),
      glassNavigation: flag('glassNavigation'),
      liquidGlass: flag('liquidGlass') ?? false,
      cinema: flag('cinema') ?? false,
      nativeDesign: flag('nativeDesign') ?? false,
      parametric: flag('parametric') ?? false,
      heroHeight: number('heroHeight'),
      gridColumns: columns?.round(),
    );
  }
}
