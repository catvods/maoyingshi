import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'global_theme.dart';
import 'home_theme.dart';
import 'ui_glass.dart';

/// The merged theme library: one theme = a home structure (an RFW
/// layout from home_theme.dart) bound to a whole-app palette (a
/// ThemeProfile package from global_theme.dart), the way LeeCat's
/// library holds one object carrying both. Applying a merged theme
/// writes both sides in one host call (applyMergedTheme in
/// C1ScreenActivity): the home_theme_id preference and the saved
/// profile. The Dart side then refreshes the homeThemeId notifier —
/// the B11 home rebuilds on it — and the shared uiConfig, so every
/// screen repaints; nothing needs a manual refresh or a restart.
///
/// The selection id space: a catalog structure id ('design-night'),
/// 'default' for the stock pairing, 'palette:<global id>' for a
/// palette-only entry (structure untouched), or a user merged
/// record id ('user-...'). Before any merged apply, the id is '' —
/// the pre-merge state, where structure and palette were picked
/// independently; the library header then shows the two apart.
///
/// Palettes are LeeCat-meta-shaped: 主色 (accent), 背景色
/// (background), 渐变色 (gradient), 面板色 (surface). The Lee
/// structures carry their exact exported meta values; the PeekPro
/// structures' palettes are derived from their catalog colours; the
/// global packages' palettes are equivalents in their documented
/// directions (their slot values are seed-generated, so a four
/// colour summary is necessarily a summary).
class MergedPalette {
  const MergedPalette({
    required this.accent,
    required this.background,
    required this.gradient,
    required this.surface,
  });

  final String accent;
  final String background;
  final String gradient;
  final String surface;

  Map<String, String> toMap() => <String, String>{
        'accent': accent,
        'background': background,
        'gradient': gradient,
        'surface': surface,
      };

  List<Color> get colors => <Color>[
        mergedHexColor(background) ?? const Color(0xFF455A64),
        mergedHexColor(gradient) ?? const Color(0xFF607D8B),
        mergedHexColor(accent) ?? const Color(0xFF90A4AE),
      ];

  bool get dark =>
      (mergedHexColor(background)?.computeLuminance() ?? 0) < 0.35;
}

Color? mergedHexColor(String hex) {
  String h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final int? v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

String mergedColorHex(Color color) {
  final int v = (color.r * 255).round() << 16 |
      (color.g * 255).round() << 8 |
      (color.b * 255).round();
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// The exact palettes of the Lee structures, from their exported
/// leecat-theme meta headers (accent / backgroundColors / surfaceColor).
const Map<String, MergedPalette> _leePalettes = <String, MergedPalette>{
  'design-night': MergedPalette(
      accent: '#c3d7b5', background: '#141917', gradient: '#26342b', surface: '#222a25'),
  'design-ticket': MergedPalette(
      accent: '#ffb78d', background: '#281b25', gradient: '#4a2f38', surface: '#3b2935'),
  'refractive-glass': MergedPalette(
      accent: '#91bfff', background: '#18263c', gradient: '#394667', surface: '#243650'),
  'design-aurora': MergedPalette(
      accent: '#7cf5e4', background: '#12172e', gradient: '#34376a', surface: '#202943'),
  'design-polar': MergedPalette(
      accent: '#82d8ff', background: '#112637', gradient: '#224653', surface: '#1e394a'),
  'design-rose': MergedPalette(
      accent: '#935464', background: '#f8e7e5', gradient: '#e8cbd4', surface: '#fff6f3'),
  // rose-glass and liquid-glass carry no surfaceColor in their meta;
  // theirs is derived from the background pair, like the host does.
  'rose-glass': MergedPalette(
      accent: '#9c5b63', background: '#ffe8e3', gradient: '#f3d9d5', surface: '#fdf0ec'),
  'design-album': MergedPalette(
      accent: '#276e68', background: '#e6f0ee', gradient: '#c3ddda', surface: '#f9fcf9'),
  'liquid-glass': MergedPalette(
      accent: '#bdcaff', background: '#1c1e2a', gradient: '#303548', surface: '#262a3d'),
  'design-radar': MergedPalette(
      accent: '#89f6cb', background: '#102d2b', gradient: '#1c4b43', surface: '#1a3b36'),
  'design-paper': MergedPalette(
      accent: '#705666', background: '#eee4cf', gradient: '#d7c3bd', surface: '#faf5e7'),
  'design-vinyl': MergedPalette(
      accent: '#ffbd70', background: '#302019', gradient: '#593829', surface: '#443024'),
  'design-matrix': MergedPalette(
      accent: '#c9a0ff', background: '#211831', gradient: '#36254b', surface: '#30223f'),
  'design-noir': MergedPalette(
      accent: '#e8c680', background: '#18130e', gradient: '#322617', surface: '#292117'),
};

/// Palettes for the PeekPro structures, derived from each catalog
/// entry's own colours (accent = its bar accent, background = its
/// base colour, gradient/surface picked from the same family).
const Map<String, MergedPalette> _peekPalettes = <String, MergedPalette>{
  'aurora_prism': MergedPalette(
      accent: '#35E7FF', background: '#07101C', gradient: '#8E5CFF', surface: '#0D1B3E'),
  'bubble': MergedPalette(
      accent: '#FF7FB5', background: '#FFD3E0', gradient: '#B5E7FF', surface: '#FFF2F6'),
  'cloud_archive': MergedPalette(
      accent: '#C9A86A', background: '#10131A', gradient: '#3D3428', surface: '#1A1E28'),
  'crimson_cinema': MergedPalette(
      accent: '#E53935', background: '#1A0505', gradient: '#4A0E0E', surface: '#260808'),
  'editorial': MergedPalette(
      accent: '#B03A2E', background: '#F5F0E8', gradient: '#E8DFCE', surface: '#FDFBF7'),
  'horizontal_gallery': MergedPalette(
      accent: '#90A4AE', background: '#263238', gradient: '#37474F', surface: '#303E46'),
  'immersive_palette': MergedPalette(
      accent: '#7C4DFF', background: '#0B0B10', gradient: '#4527A0', surface: '#17171F'),
  'ink_minimal': MergedPalette(
      accent: '#111111', background: '#FFFFFF', gradient: '#E8E8E8', surface: '#F7F7F7'),
  'midnight_rank': MergedPalette(
      accent: '#FFB300', background: '#0B1026', gradient: '#232052', surface: '#12122B'),
  'pixel_arcade': MergedPalette(
      accent: '#FFE44D', background: '#141428', gradient: '#2979FF', surface: '#1D1D33'),
  'snow_glass': MergedPalette(
      accent: '#3D7EA6', background: '#EAF3F7', gradient: '#BFE0F2', surface: '#F7FBFD'),
  'sunlit_gallery': MergedPalette(
      accent: '#EF6C00', background: '#FFF3E0', gradient: '#FFD54F', surface: '#FFFAF2'),
  'terminal': MergedPalette(
      accent: '#33FF99', background: '#031007', gradient: '#0A2E14', surface: '#061A0C'),
  'vhs': MergedPalette(
      accent: '#FF7043', background: '#2D1B4E', gradient: '#4A2A6E', surface: '#3A2560'),
};

/// Four-colour summaries of the global packages, for the merged
/// catalog cards and the editor's palette dropdown. Equivalents in
/// each package's documented direction (see GlobalThemes).
const Map<String, MergedPalette> globalPalettes = <String, MergedPalette>{
  '': MergedPalette(
      accent: '#0B57D0', background: '#FFFFFF', gradient: '#D3E3FD', surface: '#F0F4F9'),
  'light-warm': MergedPalette(
      accent: '#A65D13', background: '#FBF5EA', gradient: '#EAD9BE', surface: '#FFFDF8'),
  'dark': MergedPalette(
      accent: '#8A939C', background: '#17191C', gradient: '#2A2E33', surface: '#1F2226'),
  'bright': MergedPalette(
      accent: '#1565C0', background: '#F6F9FC', gradient: '#D3E3FD', surface: '#FFFFFF'),
  'warm-cinema': MergedPalette(
      accent: '#8A5A2B', background: '#F5F0E6', gradient: '#E4D3AC', surface: '#FBF7EE'),
  'ocean': MergedPalette(
      accent: '#1565C0', background: '#EFF6FA', gradient: '#C8E6E0', surface: '#FFFFFF'),
  'forest': MergedPalette(
      accent: '#386A20', background: '#F1F7EC', gradient: '#D3E4C0', surface: '#FBFEF8'),
  'rose': MergedPalette(
      accent: '#AE315B', background: '#FBF0F4', gradient: '#EBC7D6', surface: '#FFFBFC'),
  'wallpaper': MergedPalette(
      accent: '#6750A4', background: '#F4F0FA', gradient: '#D8CDF0', surface: '#FFFFFF'),
};

/// The palette a home catalog entry pairs with in the merged
/// library; null for the default entry (it pairs with the default
/// global package instead) and for entries without palette data.
MergedPalette? paletteForHomeEntry(HomeThemeEntry entry) {
  final MergedPalette? known =
      _leePalettes[entry.id] ?? _peekPalettes[entry.id];
  if (known != null) return known;
  if (isUserThemeId(entry.id) && entry.barAccent != null &&
      entry.colors.length >= 2) {
    // An imported source theme with a leecat meta header: its
    // palette is the meta's accent + background pair; the surface
    // is derived from the pair like the host derives it.
    final Color surface =
        Color.lerp(entry.colors[0], entry.colors[1], 0.3) ?? entry.colors[0];
    return MergedPalette(
      accent: mergedColorHex(entry.barAccent!),
      background: mergedColorHex(entry.colors[0]),
      gradient: mergedColorHex(entry.colors[1]),
      surface: mergedColorHex(surface),
    );
  }
  return null;
}

/// Component-parameter defaults the parametric editor starts from
/// for a structure: the Lee structures' own meta values where they
/// exist, one generic set everywhere else.
class MergedComponentDefaults {
  const MergedComponentDefaults({
    this.layout = 'posters',
    this.hero = true,
    this.cardRadius = 16,
    this.floatingNavigation = true,
    this.glassNavigation = false,
    this.navigationOpacity = 0.28,
    this.titleFont = 'sans',
  });

  final String layout;
  final bool hero;
  final double cardRadius;
  final bool floatingNavigation;
  final bool glassNavigation;
  final double navigationOpacity;
  final String titleFont;
}

const Map<String, MergedComponentDefaults> _leeComponentDefaults =
    <String, MergedComponentDefaults>{
  'design-night': MergedComponentDefaults(
      layout: 'posters', cardRadius: 18, navigationOpacity: 0.28),
  'design-ticket': MergedComponentDefaults(
      layout: 'compact', cardRadius: 22, navigationOpacity: 0.28),
  'refractive-glass': MergedComponentDefaults(
      layout: 'posters', cardRadius: 26, glassNavigation: true, navigationOpacity: 0.24),
  'design-aurora': MergedComponentDefaults(
      layout: 'landscape', cardRadius: 26, navigationOpacity: 0.28),
  'design-polar': MergedComponentDefaults(
      layout: 'landscape', cardRadius: 20, floatingNavigation: false, navigationOpacity: 0.28),
  'design-rose': MergedComponentDefaults(
      layout: 'posters', cardRadius: 30, navigationOpacity: 0.28),
  'rose-glass': MergedComponentDefaults(
      layout: 'posters', cardRadius: 28, navigationOpacity: 0.35),
  'design-album': MergedComponentDefaults(
      layout: 'posters', cardRadius: 12, navigationOpacity: 0.28),
  'liquid-glass': MergedComponentDefaults(
      layout: 'posters', hero: false, cardRadius: 22, navigationOpacity: 0.24),
  'design-radar': MergedComponentDefaults(
      layout: 'compact', cardRadius: 18, floatingNavigation: false, navigationOpacity: 0.28),
  'design-paper': MergedComponentDefaults(
      layout: 'compact', cardRadius: 8, floatingNavigation: false, navigationOpacity: 0.28, titleFont: 'serif'),
  'design-vinyl': MergedComponentDefaults(
      layout: 'posters', cardRadius: 28, navigationOpacity: 0.28, titleFont: 'serif'),
  'design-matrix': MergedComponentDefaults(
      layout: 'posters', cardRadius: 4, floatingNavigation: false, navigationOpacity: 0.28, titleFont: 'mono'),
  'design-noir': MergedComponentDefaults(
      layout: 'posters', cardRadius: 6, floatingNavigation: false, navigationOpacity: 0.28, titleFont: 'serif'),
};

MergedComponentDefaults componentDefaultsFor(String structureId) =>
    _leeComponentDefaults[structureId] ?? const MergedComponentDefaults();

/// The parametric editor's full form state: identity, the four
/// colours, the structure, and the component parameters. This is
/// also the shape a user merged record stores host-side.
class MergedThemeParams {
  MergedThemeParams({
    required this.name,
    this.description = '',
    required this.structureId,
    required this.palette,
    this.titleFont = 'sans',
    this.layout = 'posters',
    this.hero = true,
    this.heroHeight = 220,
    this.gridColumns = 3,
    this.cardRadius = 16,
    this.floatingNavigation = true,
    this.glassNavigation = false,
    this.navigationOpacity = 0.28,
  });

  String name;
  String description;
  String structureId;
  MergedPalette palette;
  String titleFont;
  String layout;
  bool hero;
  double heroHeight;
  int gridColumns;
  double cardRadius;
  bool floatingNavigation;
  bool glassNavigation;
  double navigationOpacity;
}

/// A user merged theme record, as the host reports it: the editor
/// parameters plus the materialized structure source it owns.
class MergedThemeRecord {
  const MergedThemeRecord({
    required this.id,
    required this.params,
    required this.structureSourceId,
    required this.structureRef,
  });

  final String id;
  final MergedThemeParams params;
  final String structureSourceId;
  final String structureRef;

  String get name => params.name;
}

/// One card in the merged library. Exactly one apply shape:
/// a structure + palette pair (catalog/user), a palette-only entry
/// ([structureId] null, [globalId] set), or a user merged record
/// ([record] set, applied host-side from the record).
class MergedThemeEntry {
  const MergedThemeEntry({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.colors,
    required this.dark,
    this.structureId,
    this.palette,
    this.globalId,
    this.record,
    this.homeEntry,
    this.globalEntry,
  });

  /// The merged selection id (see the file comment).
  final String id;
  final String name;
  final String tag;
  final String description;
  final List<Color> colors;
  final bool dark;

  /// Home structure to write on apply; null leaves the structure.
  final String? structureId;

  /// Four-colour palette to write on apply; null when [globalId]
  /// names a package instead.
  final MergedPalette? palette;

  /// Global package to apply (built-in or user palette package).
  final String? globalId;

  /// The user merged record this card stands for, when it is one.
  final MergedThemeRecord? record;

  /// The home catalog entry behind a structure card (source editor
  /// and export work on it).
  final HomeThemeEntry? homeEntry;

  /// The global catalog entry behind a palette-only card.
  final GlobalThemeEntry? globalEntry;

  bool get isUser =>
      record != null ||
      (homeEntry != null && isUserThemeId(homeEntry!.id)) ||
      (globalEntry != null && isUserGlobalThemeId(globalEntry!.id));

  bool get isPaletteOnly => structureId == null && record == null;
}

/// The built-in merged catalog: every home structure paired with
/// its palette, then the global packages as palette-only entries.
List<MergedThemeEntry> mergedCatalog() {
  final List<MergedThemeEntry> out = <MergedThemeEntry>[];
  for (final HomeThemeEntry entry in homeThemeCatalog) {
    if (entry.id.isEmpty) {
      out.add(MergedThemeEntry(
        id: 'default',
        name: entry.name,
        tag: entry.tag,
        description: entry.description,
        colors: entry.colors,
        dark: entry.dark,
        structureId: '',
        globalId: '',
        homeEntry: entry,
      ));
      continue;
    }
    final MergedPalette? palette = paletteForHomeEntry(entry);
    out.add(MergedThemeEntry(
      id: entry.id,
      name: entry.name,
      tag: entry.tag,
      description: entry.description,
      colors: palette?.colors ?? entry.colors,
      dark: palette?.dark ?? entry.dark,
      structureId: entry.id,
      palette: palette,
      homeEntry: entry,
    ));
  }
  for (final GlobalThemeEntry entry in globalThemeCatalog) {
    if (entry.id.isEmpty) continue;
    final MergedPalette? palette = globalPalettes[entry.id];
    out.add(MergedThemeEntry(
      id: 'palette:${entry.id}',
      name: entry.name,
      tag: '仅配色 · ${entry.tag}',
      description: entry.description,
      colors: palette?.colors ?? entry.colors,
      dark: palette?.dark ?? entry.dark,
      globalId: entry.id,
      globalEntry: entry,
    ));
  }
  return out;
}

/// Palette-only cards for the user's own global packages.
List<MergedThemeEntry> mergedUserGlobalEntries(
    List<GlobalThemeEntry> packages) {
  return <MergedThemeEntry>[
    for (final GlobalThemeEntry entry in packages)
      MergedThemeEntry(
        id: 'palette:${entry.id}',
        name: entry.name,
        tag: '仅配色 · 我的',
        description: entry.description,
        colors: entry.colors,
        dark: entry.dark,
        globalId: entry.id,
        globalEntry: entry,
      ),
  ];
}

/// Structure cards for imported user source themes that no merged
/// record owns (records render their own cards).
List<MergedThemeEntry> mergedUserSourceEntries(
    List<MergedThemeRecord> records, List<HomeThemeEntry> sources) {
  final Set<String> owned = <String>{
    for (final MergedThemeRecord record in records) record.structureSourceId,
  };
  return <MergedThemeEntry>[
    for (final HomeThemeEntry entry in sources)
      if (!owned.contains(entry.id))
        MergedThemeEntry(
          id: entry.id,
          name: entry.name,
          tag: entry.tag,
          description: entry.description,
          colors: entry.colors,
          dark: entry.dark,
          structureId: entry.id,
          palette: paletteForHomeEntry(entry),
          homeEntry: entry,
        ),
  ];
}

/// Cards for the user's merged records.
List<MergedThemeEntry> mergedRecordEntries(List<MergedThemeRecord> records) {
  return <MergedThemeEntry>[
    for (final MergedThemeRecord record in records)
      MergedThemeEntry(
        id: record.id,
        name: record.params.name,
        tag: '我的主题',
        description: record.params.description.isEmpty
            ? '参数编辑器创建的主题：结构与配色一体应用。'
            : record.params.description,
        colors: record.params.palette.colors,
        dark: record.params.palette.dark,
        record: record,
      ),
  ];
}

// ---------------------------------------------------------------------------
// Selection + host channel
// ---------------------------------------------------------------------------

/// The live merged selection (see the file comment for the id
/// space). '' until the first merged apply.
final ValueNotifier<String> mergedThemeId = ValueNotifier<String>('');

final ValueNotifier<List<MergedThemeRecord>> mergedUserThemes =
    ValueNotifier<List<MergedThemeRecord>>(<MergedThemeRecord>[]);

const MethodChannel _mergedChannel =
    MethodChannel('com.github.maoyingshi.osc.tv/ui_config');

Future<void> loadMergedThemeId() async {
  try {
    final String? id =
        await _mergedChannel.invokeMethod<String>('getMergedThemeId');
    if (id != null) mergedThemeId.value = id;
  } catch (_) {
    // Keep the current value when the host cannot answer.
  }
}

MergedThemeRecord _recordFromHost(Map<dynamic, dynamic> map) {
  String text(String key) => '${map[key] ?? ''}';
  double number(String key, double fallback) {
    final Object? value = map[key];
    return value is num ? value.toDouble() : fallback;
  }

  final MergedPalette palette = MergedPalette(
    accent: text('accent'),
    background: text('background'),
    gradient: text('gradient'),
    surface: text('surface'),
  );
  return MergedThemeRecord(
    id: text('id'),
    structureSourceId: text('structureSourceId'),
    structureRef: text('structureRef'),
    params: MergedThemeParams(
      name: text('name'),
      description: text('description'),
      structureId: text('structureRef'),
      palette: palette,
      titleFont: text('titleFont').isEmpty ? 'sans' : text('titleFont'),
      layout: text('layout').isEmpty ? 'posters' : text('layout'),
      hero: map['hero'] != false,
      heroHeight: number('heroHeight', 220),
      gridColumns: number('gridColumns', 3).round(),
      cardRadius: number('cardRadius', 16),
      floatingNavigation: map['floatingNavigation'] != false,
      glassNavigation: map['glassNavigation'] == true,
      navigationOpacity: number('navigationOpacity', 0.28),
    ),
  );
}

Future<void> loadMergedUserThemes() async {
  try {
    final List<dynamic>? raw =
        await _mergedChannel.invokeMethod<List<dynamic>>('listMergedThemes');
    final List<MergedThemeRecord> records = <MergedThemeRecord>[];
    for (final dynamic item in raw ?? const <dynamic>[]) {
      if (item is Map<dynamic, dynamic>) records.add(_recordFromHost(item));
    }
    mergedUserThemes.value = records;
  } catch (_) {
    // Keep the current list when the host cannot answer.
  }
}

/// Applies a merged theme: one host call writes the structure and
/// the palette; the notifiers and the shared UI config are then
/// refreshed from the result, so the home rebuilds on the new
/// structure and every screen repaints with the new palette.
/// Returns false when the host rejects the apply.
Future<bool> applyMergedTheme(MergedThemeEntry entry) async {
  final Map<String, Object?> args = <String, Object?>{
    'mergedId': entry.id,
    'name': entry.name,
  };
  if (entry.record != null) {
    args['userMerged'] = true;
  } else {
    if (entry.structureId != null) args['structureId'] = entry.structureId;
    if (entry.globalId != null) {
      args['globalId'] = entry.globalId;
    } else if (entry.palette != null) {
      args['palette'] = entry.palette!.toMap();
    }
  }
  try {
    final Map<dynamic, dynamic>? result = await _mergedChannel
        .invokeMethod<Map<dynamic, dynamic>>('applyMergedTheme', args);
    mergedThemeId.value = entry.id;
    final String? structureId = result?['structureId'] as String?;
    if (structureId != null && structureId != homeThemeId.value) {
      homeThemeId.value = structureId;
    }
    await loadGlobalThemeId();
    await loadUiConfig();
    return true;
  } catch (_) {
    return false;
  }
}

/// Saves the parametric editor's form as a merged record. The
/// editor materializes the structure source first (through the
/// existing user-theme import path) and passes its id as
/// [structureSourceId]; [structureRef] remembers the structure the
/// source came from, for re-editing. Returns the record id.
Future<String> saveMergedTheme({
  required String? id,
  required MergedThemeParams params,
  required String structureSourceId,
}) async {
  final Map<dynamic, dynamic>? result =
      await _mergedChannel.invokeMethod<Map<dynamic, dynamic>>(
    'saveMergedTheme',
    <String, Object?>{
      'id': id ?? '',
      'name': params.name,
      'description': params.description,
      'structureSourceId': structureSourceId,
      'structureRef': params.structureId,
      'accent': params.palette.accent,
      'background': params.palette.background,
      'gradient': params.palette.gradient,
      'surface': params.palette.surface,
      'layout': params.layout,
      'hero': params.hero,
      'heroHeight': params.heroHeight,
      'gridColumns': params.gridColumns,
      'cardRadius': params.cardRadius,
      'floatingNavigation': params.floatingNavigation,
      'glassNavigation': params.glassNavigation,
      'navigationOpacity': params.navigationOpacity,
      'titleFont': params.titleFont,
    },
  );
  await loadMergedUserThemes();
  await loadMergedThemeId();
  final String savedId = '${result?['id'] ?? ''}';
  if (savedId.isEmpty) throw StateError('merged theme save failed');
  // Saving the live record re-applies it host-side; keep the home
  // structure notifier in step with the (possibly new) source.
  final String? sourceId = result?['structureSourceId'] as String?;
  if (sourceId != null &&
      mergedThemeId.value == savedId &&
      sourceId != homeThemeId.value) {
    homeThemeId.value = sourceId;
  }
  await loadUiConfig();
  return savedId;
}

/// Deletes a merged record host-side and returns the structure id
/// the home uses afterwards ('' when it fell back to the default).
/// The caller deletes the record's materialized source file.
Future<String> deleteMergedThemeRecord(String id) async {
  final Map<dynamic, dynamic>? result = await _mergedChannel
      .invokeMethod<Map<dynamic, dynamic>>('deleteMergedTheme', id);
  await loadMergedUserThemes();
  await loadMergedThemeId();
  return '${result?['structureId'] ?? ''}';
}
