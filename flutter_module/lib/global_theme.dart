import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'ui_glass.dart';

/// The global theme catalog: whole-app palette packages (the
/// LeeCat-style 全局主题 library), the counterpart of the home theme
/// catalog in home_theme.dart. A home theme restyles only the home
/// screen's layout; a global theme recolors the whole app.
///
/// There is no Dart-side palette state to keep in sync: applying a
/// package goes through the ui_config MethodChannel, the host writes
/// the package's complete ThemeProfile through its ThemeProfileStore,
/// and this file then refreshes the shared [uiConfig], whose tokens
/// build the ColorScheme every Flutter screen paints with (native
/// screens resolve the same saved profile on create). The selection
/// therefore survives restarts exactly like the profile itself does.
///
/// Relationship with the 主题色彩 editor: a global theme is a preset
/// package over the same profile the editor edits. Applying one
/// overwrites the profile wholesale; editing colors afterwards makes
/// the host report the selection as [globalThemeCustomId] until
/// another package is applied.
class GlobalThemeEntry {
  const GlobalThemeEntry({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.colors,
    required this.dark,
  });

  /// '' for the built-in default; otherwise the package id the host
  /// catalog (GlobalThemes) knows. The two catalogs are mirrored.
  final String id;
  final String name;

  /// Short palette label on the picker card.
  final String tag;
  final String description;

  /// Representative palette for the picker card's preview band.
  final List<Color> colors;

  /// Whether the preview band is dark (card text contrast).
  final bool dark;
}

/// Host-reported selection when the saved profile is no package
/// (theme-color editor presets or hand edits).
const String globalThemeCustomId = 'custom';

const List<GlobalThemeEntry> globalThemeCatalog = <GlobalThemeEntry>[
  GlobalThemeEntry(
    id: '',
    name: '默认',
    tag: '系统默认',
    description: '陌奥影视的默认配色：蓝色基调，浅色清爽、深色沉稳。',
    colors: <Color>[Color(0xFF0B57D0), Color(0xFF7FB3FF)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'light-warm',
    name: '浅色',
    tag: '暖白 · 橙金',
    description: '暖白底色配橙金强调，页面文字统一为石墨灰。按狸猫「浅色」的方向复刻。',
    colors: <Color>[Color(0xFFFBF5EA), Color(0xFFD98E32)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'dark',
    name: '深色',
    tag: '石墨 · 深色',
    description: '整套切到深色外观：石墨灰基调，夜间使用更护眼。按狸猫「深色」的方向复刻。',
    colors: <Color>[Color(0xFF17191C), Color(0xFF596168)],
    dark: true,
  ),
  GlobalThemeEntry(
    id: 'bright',
    name: '亮色主题',
    tag: '冷白 · 蓝色',
    description: '冷白底色与蓝色强调，清爽明快。狸猫主题库的「亮色主题」。',
    colors: <Color>[Color(0xFFF6F9FC), Color(0xFF1565C0)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'warm-cinema',
    name: '暖白影院',
    tag: '暖白 · 青铜',
    description: '奶油暖白配青铜金，像老影院亮起的灯光。狸猫的「暖白影院」。',
    colors: <Color>[Color(0xFFF5F0E6), Color(0xFF8A5A2B)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'ocean',
    name: '澄海蓝',
    tag: '海蓝 · 青绿',
    description: '深海蓝主色带青绿，清凉通透，浅深两套都耐看。',
    colors: <Color>[Color(0xFF1565C0), Color(0xFF006B74)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'forest',
    name: '松林绿',
    tag: '森绿 · 赭石',
    description: '松林绿主色配赭石，沉稳自然。',
    colors: <Color>[Color(0xFF386A20), Color(0xFF80561D)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'rose',
    name: '蔷薇红',
    tag: '玫红 · 紫灰',
    description: '蔷薇红主色带紫灰，温柔又醒目。',
    colors: <Color>[Color(0xFFAE315B), Color(0xFF705289)],
    dark: false,
  ),
  GlobalThemeEntry(
    id: 'wallpaper',
    name: '壁纸取色',
    tag: '跟随壁纸',
    description: '配色从当前壁纸自动提取，换一张壁纸就换一套。',
    colors: <Color>[Color(0xFF6750A4), Color(0xFFB0A6D6)],
    dark: false,
  ),
];

GlobalThemeEntry? globalThemeEntry(String id) {
  for (final GlobalThemeEntry entry in userGlobalThemes.value) {
    if (entry.id == id) return entry;
  }
  for (final GlobalThemeEntry entry in globalThemeCatalog) {
    if (entry.id == id) return entry;
  }
  return null;
}

/// The live selection, as the host reports it: a catalog id, or
/// [globalThemeCustomId] when the saved profile is no package.
final ValueNotifier<String> globalThemeId = ValueNotifier<String>('');

const MethodChannel _globalThemeChannel =
    MethodChannel('com.github.maoyingshi.osc.tv/ui_config');

/// Loads the current selection from the host. Never throws.
Future<void> loadGlobalThemeId() async {
  try {
    final String? id =
        await _globalThemeChannel.invokeMethod<String>('getGlobalThemeId');
    if (id != null) globalThemeId.value = id;
  } catch (_) {
    // Keep the current value when the host cannot answer.
  }
}

/// Applies a package through the host and refreshes the shared UI
/// config, so every screen — this picker first — repaints with the
/// new palette immediately. Returns false (and restores the previous
/// selection) when the host rejects the package.
Future<bool> setGlobalThemeId(String id) async {
  final String before = globalThemeId.value;
  globalThemeId.value = id;
  try {
    final bool? ok =
        await _globalThemeChannel.invokeMethod<bool>('setGlobalThemeId', id);
    if (ok != true) {
      globalThemeId.value = before;
      return false;
    }
  } catch (_) {
    globalThemeId.value = before;
    return false;
  }
  await loadUiConfig();
  return true;
}

// ---------------------------------------------------------------------------
// User global themes (editor)
//
// Packages the user builds in the global theme editor. They are
// stored by the host as complete ThemeProfiles (UserGlobalThemes)
// and apply through the same setGlobalThemeId path as a built-in
// package; ids start with 'user-'. Built-ins are never overwritten —
// the editor only ever writes here, using a built-in (or an existing
// user package) as its template base.
// ---------------------------------------------------------------------------

final ValueNotifier<List<GlobalThemeEntry>> userGlobalThemes =
    ValueNotifier<List<GlobalThemeEntry>>(<GlobalThemeEntry>[]);

bool isUserGlobalThemeId(String id) => id.startsWith('user-');

/// The core color slots the editor form exposes, per light/dark
/// mode. Mirrors the host's GLOBAL_THEME_CORE_SLOTS in
/// C1ScreenActivity; the host fills every one with a concrete value
/// (the profile's own, or the resolved token when unset).
const List<String> globalThemeCoreSlots = <String>[
  'primary',
  'primaryContainer',
  'surface',
  'surfaceContainer',
  'surfaceContainerHigh',
  'onSurface',
  'onSurfaceVariant',
  'outline',
];

Color? _globalHex(String hex) {
  String h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final int? v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

GlobalThemeEntry _userGlobalEntryFromHost(Map<dynamic, dynamic> map) {
  final String id = '${map['id'] ?? ''}';
  final String name = '${map['name'] ?? ''}';
  final Color surface =
      _globalHex('${map['surface'] ?? ''}') ?? const Color(0xFF455A64);
  final Color primary =
      _globalHex('${map['primary'] ?? ''}') ?? const Color(0xFF90A4AE);
  return GlobalThemeEntry(
    id: id,
    name: name.isEmpty ? '未命名主题' : name,
    tag: '我的主题',
    description: '在主题编辑器里自己配的全局配色，点选即应用。',
    colors: <Color>[surface, primary],
    dark: surface.computeLuminance() < 0.35,
  );
}

/// (Re)loads the user package list from the host. Never throws.
Future<void> loadUserGlobalThemes() async {
  try {
    final List<dynamic>? raw = await _globalThemeChannel
        .invokeMethod<List<dynamic>>('listUserGlobalThemes');
    final List<GlobalThemeEntry> entries = <GlobalThemeEntry>[];
    for (final dynamic item in raw ?? const <dynamic>[]) {
      if (item is Map<dynamic, dynamic>) {
        entries.add(_userGlobalEntryFromHost(item));
      }
    }
    userGlobalThemes.value = entries;
  } catch (_) {
    // Keep the current list when the host cannot answer.
  }
}

/// The editor form's starting values for a package: its name and
/// the core slot colors of both modes, every slot concrete.
class GlobalThemeEditorData {
  const GlobalThemeEditorData({
    required this.name,
    required this.light,
    required this.dark,
  });

  final String name;
  final Map<String, String> light;
  final Map<String, String> dark;
}

Map<String, String> _slotMap(Object? raw) {
  final Map<String, String> out = <String, String>{};
  if (raw is Map<dynamic, dynamic>) {
    for (final String slot in globalThemeCoreSlots) {
      out[slot] = '${raw[slot] ?? ''}';
    }
  }
  return out;
}

/// Loads a package's editor data (built-in catalog id, '' for the
/// default, or a user package id). Throws on host errors.
Future<GlobalThemeEditorData> getGlobalThemeEditorData(String id) async {
  final Map<dynamic, dynamic>? map = await _globalThemeChannel
      .invokeMethod<Map<dynamic, dynamic>>('getGlobalThemeEditorData', id);
  if (map == null) throw StateError('global theme not found: $id');
  return GlobalThemeEditorData(
    name: '${map['name'] ?? ''}',
    light: _slotMap(map['light']),
    dark: _slotMap(map['dark']),
  );
}

/// Saves the editor form as a user package: [id] is the user
/// package being edited (null when creating), [baseId] the template
/// package a creation starts from. Returns the saved entry after
/// refreshing the list. Throws on host errors.
Future<GlobalThemeEntry?> saveUserGlobalTheme({
  String? id,
  required String baseId,
  required String name,
  required Map<String, String> light,
  required Map<String, String> dark,
}) async {
  final Map<dynamic, dynamic>? map =
      await _globalThemeChannel.invokeMethod<Map<dynamic, dynamic>>(
    'saveUserGlobalTheme',
    <String, Object>{
      'id': id ?? '',
      'baseId': baseId,
      'name': name,
      'light': light,
      'dark': dark,
    },
  );
  if (map == null) return null;
  await loadUserGlobalThemes();
  final String savedId = '${map['id'] ?? ''}';
  for (final GlobalThemeEntry entry in userGlobalThemes.value) {
    if (entry.id == savedId) return entry;
  }
  return null;
}

/// One imported global-theme JSON file.
class ImportedGlobalTheme {
  const ImportedGlobalTheme({
    required this.id,
    required this.name,
    required this.existed,
  });

  final String id;
  final String name;

  /// True when a package with this name was already stored (the
  /// import reported it as already there instead of duplicating it).
  final bool existed;
}

/// Imports one global theme from its JSON form (name + the four
/// palette colours) through the host: the host builds the full
/// light+dark profile from the colours with the same builder the
/// merged editor uses (GlobalThemes.buildPaletteProfile) and stores
/// and stores it as a user package (UserGlobalThemes, the same store
/// the editor writes). Returns the saved entry after refreshing the
/// list. Throws on host errors.
Future<ImportedGlobalTheme> importGlobalTheme({
  required String name,
  required String accent,
  required String background,
  required String gradient,
  required String surface,
}) async {
  final Map<dynamic, dynamic>? map =
      await _globalThemeChannel.invokeMethod<Map<dynamic, dynamic>>(
    'importGlobalTheme',
    <String, Object>{
      'name': name,
      'accent': accent,
      'background': background,
      'gradient': gradient,
      'surface': surface,
    },
  );
  if (map == null) throw StateError('global theme import failed');
  await loadUserGlobalThemes();
  return ImportedGlobalTheme(
    id: '${map['id'] ?? ''}',
    name: '${map['name'] ?? name}',
    existed: map['existed'] == true,
  );
}

/// Imports one global theme from its v2 JSON form (name + seedColor +
/// the complete light/dark slot sets) through the host: the host saves
/// the slots as-is as a user package (UserGlobalThemes, the same store
/// the editor writes) after the same validation the editor's saves go
/// through. Unlike the v1 four-colour form, nothing is generated here —
/// the file already carries every slot. Returns the saved entry after
/// refreshing the list. Throws on host errors.
Future<ImportedGlobalTheme> importGlobalThemeV2({
  required String name,
  required String seedColor,
  required Map<String, Object> light,
  required Map<String, Object> dark,
}) async {
  final Map<dynamic, dynamic>? map =
      await _globalThemeChannel.invokeMethod<Map<dynamic, dynamic>>(
    'importGlobalTheme',
    <String, Object>{
      'version': 2,
      'name': name,
      'seedColor': seedColor,
      'light': light,
      'dark': dark,
    },
  );
  if (map == null) throw StateError('global theme import failed');
  await loadUserGlobalThemes();
  return ImportedGlobalTheme(
    id: '${map['id'] ?? ''}',
    name: '${map['name'] ?? name}',
    existed: map['existed'] == true,
  );
}

/// Deletes a user package. The applied profile is data of its own,
/// so deleting the package that is currently applied leaves the
/// colors in place; the selection then reads as 自定义， exactly
/// like a theme-color hand edit.
Future<void> deleteUserGlobalTheme(String id) async {
  await _globalThemeChannel.invokeMethod<void>('deleteUserGlobalTheme', id);
  await loadUserGlobalThemes();
  await loadGlobalThemeId();
}
