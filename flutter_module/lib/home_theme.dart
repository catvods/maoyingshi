import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The home theme catalog: the ported PeekPro home themes plus the
/// built-in default (id ''). The theme files themselves live in
/// assets/peek_home/theme_<id>.rfwtxt and are rendered by the RFW
/// bridge in themed_home.dart; this file only owns the catalog the
/// picker page shows and the persisted selection.
///
/// Persistence goes through the ui_config MethodChannel: the host
/// (C1ScreenActivity) stores the id in its SharedPreferences, so the
/// choice survives engine restarts exactly like the glass settings.
class HomeThemeEntry {
  const HomeThemeEntry({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.colors,
    required this.dark,
    this.barTint,
    this.barAccent,
    this.barOpacity,
    this.barFloating,
  });

  /// '' for the built-in home; otherwise the theme file stem.
  final String id;
  final String name;

  /// Carousel / layout label, mirroring PeekPro's theme library.
  final String tag;
  final String description;

  /// Representative palette for the picker card's preview band.
  final List<Color> colors;

  /// Whether the theme itself is dark (picker card text contrast).
  final bool dark;

  /// Bottom-bar styling while this theme is active (the source
  /// apps restyle the navigation bar with the theme). Null on the
  /// default entry: the bar keeps the snapshot's own look.
  final Color? barTint;
  final Color? barAccent;

  /// Lee themes carry navigation styling in their metadata: the
  /// bar surface opacity (navigationOpacity) and whether the bar
  /// floats as a capsule or runs edge-to-edge (floatingNavigation).
  /// Null = keep the bar's own geometry/opacity.
  final double? barOpacity;
  final bool? barFloating;
}

const List<HomeThemeEntry> homeThemeCatalog = <HomeThemeEntry>[
  HomeThemeEntry(
    id: '',
    name: '默认主题',
    tag: '原生首页',
    description: '陌奥影视自带的首页，毛玻璃底栏与横幅轮播。',
    colors: <Color>[Color(0xFF0B57D0), Color(0xFF7FB3FF)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'aurora_prism',
    name: '极光棱镜',
    tag: '纤长轮播 · 自动播放',
    description: '深蓝夜空与光谱渐变，轮播纤长、卡片带霓虹描边。',
    colors: <Color>[Color(0xFF07101C), Color(0xFF35E7FF), Color(0xFF8E5CFF)],
    dark: true,
    barTint: Color(0xFF0D1B3E),
    barAccent: Color(0xFF35E7FF),
  ),
  HomeThemeEntry(
    id: 'bubble',
    name: '柔彩气泡',
    tag: '胖轮播 · 大圆角',
    description: '柔和马卡龙色，大圆角卡片像气泡一样轻盈。',
    colors: <Color>[Color(0xFFFF7FB5), Color(0xFFFFD3E0), Color(0xFFB5E7FF)],
    dark: false,
    barTint: Color(0xFFFFD3E0),
    barAccent: Color(0xFFFF7FB5),
  ),
  HomeThemeEntry(
    id: 'cloud_archive',
    name: '云幕典藏',
    tag: '竖版轮播 · 暗金玻璃',
    description: '为竖版海报设计的高级感主题，窄幅轮播、当前卡片抬升。',
    colors: <Color>[Color(0xFF10131A), Color(0xFFC9A86A)],
    dark: true,
    barTint: Color(0xFF10131A),
    barAccent: Color(0xFFC9A86A),
  ),
  HomeThemeEntry(
    id: 'crimson_cinema',
    name: '赤焰影院',
    tag: '超高轮播 · 沉浸主视觉',
    description: '黑红影院风格，超高轮播带来大面积主视觉冲击。',
    colors: <Color>[Color(0xFF1A0505), Color(0xFFE53935)],
    dark: true,
    barTint: Color(0xFF1A0505),
    barAccent: Color(0xFFE53935),
  ),
  HomeThemeEntry(
    id: 'editorial',
    name: '银幕杂志',
    tag: '无轮播 · 编辑排版',
    description: '像杂志内页一样排版：大编号、宽幅图、清晰的文字层级。',
    colors: <Color>[Color(0xFFF5F0E8), Color(0xFF212121)],
    dark: false,
    barTint: Color(0xFFF5F0E8),
    barAccent: Color(0xFFB03A2E),
  ),
  HomeThemeEntry(
    id: 'horizontal_gallery',
    name: '横向影廊',
    tag: '无轮播 · 宽幅剧照墙',
    description: '默认就是宽幅剧照墙，图片上直接叠渐变文字层。',
    colors: <Color>[Color(0xFF263238), Color(0xFF90A4AE)],
    dark: true,
    barTint: Color(0xFF263238),
    barAccent: Color(0xFF90A4AE),
  ),
  HomeThemeEntry(
    id: 'immersive_palette',
    name: '沉浸光影',
    tag: '海报取色 · 独立主视觉',
    description: '参考 TMDB 详情页：顶部主视觉承载海报与取色氛围。',
    colors: <Color>[Color(0xFF0B0B10), Color(0xFF5E35B1)],
    dark: true,
    barTint: Color(0xFF0B0B10),
    barAccent: Color(0xFF7C4DFF),
  ),
  HomeThemeEntry(
    id: 'ink_minimal',
    name: '墨白极简',
    tag: '无轮播 · 黑白极简',
    description: '最少装饰、黑白配色，布局可在海报、图文行、文字行间切换。',
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFF111111)],
    dark: false,
    barTint: Color(0xFFFFFFFF),
    barAccent: Color(0xFF111111),
  ),
  HomeThemeEntry(
    id: 'midnight_rank',
    name: '午夜榜单',
    tag: '无轮播 · 排名榜单',
    description: '以排名和文字为主的深夜榜单风，默认无图、靠名次说话。',
    colors: <Color>[Color(0xFF0D0D19), Color(0xFFFFE44D)],
    dark: true,
    barTint: Color(0xFF0B1026),
    barAccent: Color(0xFFFFB300),
  ),
  HomeThemeEntry(
    id: 'pixel_arcade',
    name: '像素街机',
    tag: '无轮播 · 硬边撞色',
    description: '方形组件、偏移硬阴影、醒目编号，街机厅的硬朗撞色。',
    colors: <Color>[Color(0xFFFFE44D), Color(0xFF2979FF)],
    dark: true,
    barTint: Color(0xFF141428),
    barAccent: Color(0xFFFFE44D),
  ),
  HomeThemeEntry(
    id: 'snow_glass',
    name: '雪境玻璃',
    tag: '矮轮播 · 轻量横幅',
    description: '低矮轮播加明亮卡片，像雪后初晴的通透玻璃感。',
    colors: <Color>[Color(0xFFF1F8FC), Color(0xFF75BDE8)],
    dark: false,
    barTint: Color(0xFFEAF3F7),
    barAccent: Color(0xFF3D7EA6),
  ),
  HomeThemeEntry(
    id: 'sunlit_gallery',
    name: '暖阳影廊',
    tag: '竖版层叠轮播 · 暖色',
    description: '明亮暖色的竖版层叠轮播，左右卡片像画廊一样排开。',
    colors: <Color>[Color(0xFFFFF3E0), Color(0xFFFF9800)],
    dark: false,
    barTint: Color(0xFFFFF3E0),
    barAccent: Color(0xFFEF6C00),
  ),
  HomeThemeEntry(
    id: 'terminal',
    name: '绿幕终端',
    tag: '无轮播 · 纯文字',
    description: '等宽字体的绿幕终端风，默认纯文字列表，冷静克制。',
    colors: <Color>[Color(0xFF001A00), Color(0xFF00E676)],
    dark: true,
    barTint: Color(0xFF031007),
    barAccent: Color(0xFF33FF99),
  ),
  HomeThemeEntry(
    id: 'vhs',
    name: '复古录像厅',
    tag: '窄幅胶片轮播',
    description: '一屏多张的胶片轮播，暖色渐变与方角标签带你回录像厅。',
    colors: <Color>[Color(0xFF2D1B4E), Color(0xFFFF7043)],
    dark: true,
    barTint: Color(0xFF2D1B4E),
    barAccent: Color(0xFFFF7043),
  ),
  // LeeCatVodSimplify's built-in themes (.lzt sources the user
  // exported from that app); same RFW contract, same peek.home
  // widgets, so they render through the same bridge.
  HomeThemeEntry(
    id: 'design-night',
    name: '午夜影院',
    tag: '宽幕推荐 · 沉浸海报墙',
    description: '柔光面板衬着沉浸海报墙，宽幕推荐像午夜场的大银幕。',
    colors: <Color>[Color(0xFF141917), Color(0xFF26342B), Color(0xFFC3D7B5)],
    dark: true,
    barTint: Color(0xFF141917),
    barAccent: Color(0xFFC3D7B5),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-ticket',
    name: '午夜票根',
    tag: '入场票推荐 · 编号片单',
    description: '虚线分隔的入场票版式，每部片都像一张存根票根。',
    colors: <Color>[Color(0xFF281B25), Color(0xFF4A2F38), Color(0xFFFFB78D)],
    dark: true,
    barTint: Color(0xFF281B25),
    barAccent: Color(0xFFFFB78D),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'refractive-glass',
    name: '折射玻璃',
    tag: 'iOS 风格 · 曲面折射',
    description: '曲面折射的通透玻璃感，干净明亮的 iOS 风格。',
    colors: <Color>[Color(0xFF18263C), Color(0xFF394667), Color(0xFF91BFFF)],
    dark: true,
    barTint: Color(0xFF18263C),
    barAccent: Color(0xFF91BFFF),
    barOpacity: 0.24,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-aurora',
    name: '极光巨幕',
    tag: '全景巨幕 · 渐层玻璃',
    description: '全景巨幕配渐层玻璃，宽幅影廊像极光铺开。',
    colors: <Color>[Color(0xFF12172E), Color(0xFF34376A), Color(0xFF7CF5E4)],
    dark: true,
    barTint: Color(0xFF12172E),
    barAccent: Color(0xFF7CF5E4),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-polar',
    name: '极地视窗',
    tag: '全景视窗 · 蓝色侧签',
    description: '独立标题底栏加蓝色侧签，像极地科考站的观察窗。',
    colors: <Color>[Color(0xFF112637), Color(0xFF224653), Color(0xFF82D8FF)],
    dark: true,
    barTint: Color(0xFF112637),
    barAccent: Color(0xFF82D8FF),
    barOpacity: 0.28,
    barFloating: false,
  ),
  HomeThemeEntry(
    id: 'design-rose',
    name: '桃雾浮光',
    tag: '柔雾渐层 · 非对称浮岛',
    description: '柔雾粉调里浮着非对称小岛，胶囊控件轻盈漂浮。',
    colors: <Color>[Color(0xFFF8E7E5), Color(0xFFE8CBD4), Color(0xFF935464)],
    dark: false,
    barTint: Color(0xFFF8E7E5),
    barAccent: Color(0xFF935464),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'rose-glass',
    name: '桃雾浮光 · 浅粉',
    tag: '浅粉首页 · 圆角海报',
    description: '浅粉底色配圆角海报，悬浮胶囊导航温柔干净。',
    colors: <Color>[Color(0xFFFFE8E3), Color(0xFFF3D9D5), Color(0xFF9C5B63)],
    dark: false,
    barTint: Color(0xFFFFE8E3),
    barAccent: Color(0xFF9C5B63),
    barOpacity: 0.35,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-album',
    name: '海盐相册',
    tag: '相册封面 · 拍立得卡片',
    description: '像翻一本海盐色相册，拍立得卡片留着白边题签。',
    colors: <Color>[Color(0xFFE6F0EE), Color(0xFFC3DDDA), Color(0xFF276E68)],
    dark: false,
    barTint: Color(0xFFE6F0EE),
    barAccent: Color(0xFF276E68),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'liquid-glass',
    name: '液态玻璃',
    tag: '深空底色 · 通透胶囊',
    description: '深空底色上漂浮通透胶囊，带流动放大透镜的液态玻璃。',
    colors: <Color>[Color(0xFF1C1E2A), Color(0xFF303548), Color(0xFFBDCAFF)],
    dark: true,
    barTint: Color(0xFF1C1E2A),
    barAccent: Color(0xFFBDCAFF),
    barOpacity: 0.24,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-radar',
    name: '深空雷达',
    tag: '雷达推荐台 · 环线装饰',
    description: '环线雷达扫过深空绿，片单像资源档案一样陈列。',
    colors: <Color>[Color(0xFF102D2B), Color(0xFF1C4B43), Color(0xFF89F6CB)],
    dark: true,
    barTint: Color(0xFF102D2B),
    barAccent: Color(0xFF89F6CB),
    barOpacity: 0.28,
    barFloating: false,
  ),
  HomeThemeEntry(
    id: 'design-paper',
    name: '玫瑰书房',
    tag: '书页刊头 · 编辑式片单',
    description: '书页般的刊头与细线目录，像在书房里翻一本影集。',
    colors: <Color>[Color(0xFFEEE4CF), Color(0xFFD7C3BD), Color(0xFF705666)],
    dark: false,
    barTint: Color(0xFFEEE4CF),
    barAccent: Color(0xFF705666),
    barOpacity: 0.28,
    barFloating: false,
  ),
  HomeThemeEntry(
    id: 'design-vinyl',
    name: '落日唱片',
    tag: '唱片式推荐 · 圆盘封面',
    description: '推荐位是一张落日色唱片，圆盘封面缓缓转出暖意。',
    colors: <Color>[Color(0xFF302019), Color(0xFF593829), Color(0xFFFFBD70)],
    dark: true,
    barTint: Color(0xFF302019),
    barAccent: Color(0xFFFFBD70),
    barOpacity: 0.28,
    barFloating: true,
  ),
  HomeThemeEntry(
    id: 'design-matrix',
    name: '赛博矩阵',
    tag: '终端式刊头 · 电路网格',
    description: '终端刊头加电路网格，方卡矩阵排得整整齐齐。',
    colors: <Color>[Color(0xFF211831), Color(0xFF36254B), Color(0xFFC9A0FF)],
    dark: true,
    barTint: Color(0xFF211831),
    barAccent: Color(0xFFC9A0FF),
    barOpacity: 0.28,
    barFloating: false,
  ),
  HomeThemeEntry(
    id: 'design-noir',
    name: '黑金典藏',
    tag: '对开首映 · 金线装帧',
    description: '黑金对开页像首映礼请柬，金线装帧带典藏序号。',
    colors: <Color>[Color(0xFF18130E), Color(0xFF322617), Color(0xFFE8C680)],
    dark: true,
    barTint: Color(0xFF18130E),
    barAccent: Color(0xFFE8C680),
    barOpacity: 0.28,
    barFloating: false,
  ),
];

HomeThemeEntry homeThemeEntry(String id) {
  for (final HomeThemeEntry entry in userThemes.value) {
    if (entry.id == id) return entry;
  }
  for (final HomeThemeEntry entry in homeThemeCatalog) {
    if (entry.id == id) return entry;
  }
  return homeThemeCatalog.first;
}

/// The live selection. The B11 home listens to this and swaps its
/// body between the built-in home and the RFW themed home.
final ValueNotifier<String> homeThemeId = ValueNotifier<String>('');

const MethodChannel _homeThemeChannel =
    MethodChannel('com.github.maoyingshi.osc.tv/ui_config');

/// Loads the persisted selection from the host. Never throws.
Future<void> loadHomeThemeId() async {
  try {
    final String? id =
        await _homeThemeChannel.invokeMethod<String>('getHomeThemeId');
    if (id != null && id.isNotEmpty) homeThemeId.value = id;
  } catch (_) {
    // Keep the default theme when the host cannot answer.
  }
}

/// Persists a new selection and publishes it live.
Future<void> setHomeThemeId(String id) async {
  homeThemeId.value = id;
  try {
    await _homeThemeChannel.invokeMethod<void>('setHomeThemeId', id);
  } catch (_) {
    // The notifier already applied the change for this session.
  }
}

// ---------------------------------------------------------------------------
// Imported user themes
//
// Theme files the user picks (.lzt / .rfwtxt — the same RFW text the
// built-ins use) are stored by the host under its files dir and
// listed here. Ids start with 'user-'; the bridge loads their source
// through the channel instead of rootBundle.
// ---------------------------------------------------------------------------

final ValueNotifier<List<HomeThemeEntry>> userThemes =
    ValueNotifier<List<HomeThemeEntry>>(<HomeThemeEntry>[]);

bool isUserThemeId(String id) => id.startsWith('user-');

Color? _metaHex(String hex) {
  String h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final int? v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

String? _metaString(String meta, String key) {
  final RegExpMatch? m =
      RegExp('"$key"\\s*:\\s*"(#[0-9a-fA-F]{6,8})"').firstMatch(meta);
  return m?.group(1);
}

HomeThemeEntry _userEntryFromHost(Map<dynamic, dynamic> map) {
  final String id = '${map['id'] ?? ''}';
  final String name = '${map['name'] ?? ''}';
  final String meta = '${map['meta'] ?? ''}';
  // The leecat meta header (when present) carries the palette and
  // the navigation styling, same as the built-in Lee themes.
  List<Color> colors = const <Color>[Color(0xFF455A64), Color(0xFF90A4AE)];
  bool dark = true;
  final RegExpMatch? bg = RegExp(
          r'"backgroundColors"\s*:\s*\[\s*"(#[0-9a-fA-F]{6,8})"\s*,\s*"(#[0-9a-fA-F]{6,8})"')
      .firstMatch(meta);
  if (bg != null) {
    final Color? a = _metaHex(bg.group(1)!);
    final Color? b = _metaHex(bg.group(2)!);
    if (a != null && b != null) {
      colors = <Color>[a, b];
      dark = a.computeLuminance() < 0.35;
    }
  }
  final Color? accent = _metaHex(_metaString(meta, 'accent') ?? '');
  final RegExpMatch? nav = RegExp(r'"navigationOpacity"\s*:\s*([0-9.]+)')
      .firstMatch(meta);
  // A meta that turns glass navigation off wants a solid bar: the
  // bar's opacity override is the switch the shell bar honours.
  final bool glassNavOff = meta.contains('"glassNavigation": false') ||
      meta.contains('"glassNavigation":false');
  return HomeThemeEntry(
    id: id,
    name: name.isEmpty ? '未命名主题' : name,
    tag: '我的主题',
    description: '从主题文件导入，点选即应用。',
    colors: colors,
    dark: dark,
    barTint: colors.first,
    barAccent: accent,
    barOpacity: glassNavOff
        ? 1.0
        : (nav == null ? null : double.tryParse(nav.group(1)!)),
    barFloating: meta.contains('"floatingNavigation": false') ||
            meta.contains('"floatingNavigation":false')
        ? false
        : null,
  );
}

/// (Re)loads the imported-theme list from the host. Never throws.
Future<void> loadUserThemes() async {
  try {
    final List<dynamic>? raw =
        await _homeThemeChannel.invokeMethod<List<dynamic>>('listUserThemes');
    final List<HomeThemeEntry> entries = <HomeThemeEntry>[];
    for (final dynamic item in raw ?? const <dynamic>[]) {
      if (item is Map<dynamic, dynamic>) entries.add(_userEntryFromHost(item));
    }
    userThemes.value = entries;
  } catch (_) {
    // Keep the current list when the host cannot answer.
  }
}

Future<HomeThemeEntry?> _afterImport(Map<dynamic, dynamic>? map) async {
  if (map == null) return null;
  await loadUserThemes();
  final String id = '${map['id'] ?? ''}';
  for (final HomeThemeEntry entry in userThemes.value) {
    if (entry.id == id) return entry;
  }
  return _userEntryFromHost(map);
}

/// Opens the host file picker and imports the chosen theme file.
/// Returns the imported entry, or null when the user cancelled.
/// A [PlatformException] with a readable message signals a bad file.
Future<HomeThemeEntry?> importUserTheme() async {
  return _afterImport(await _homeThemeChannel
      .invokeMethod<Map<dynamic, dynamic>>('importUserTheme'));
}

/// Imports theme source pasted by the user (the Lee library's
/// second import route). Same validation as the file route.
Future<HomeThemeEntry?> importUserThemeText(String text) async {
  return _afterImport(await _homeThemeChannel
      .invokeMethod<Map<dynamic, dynamic>>('importUserThemeText', text));
}

/// Deletes an imported theme; a deleted active theme falls back
/// to the built-in default.
Future<void> deleteUserTheme(String id) async {
  await _homeThemeChannel.invokeMethod<void>('deleteUserTheme', id);
  if (homeThemeId.value == id) await setHomeThemeId('');
  await loadUserThemes();
}

/// The theme's RFW source: the bundled asset for built-ins, the
/// host-stored file for imported themes.
Future<String> loadThemeText(String id) async {
  if (isUserThemeId(id)) {
    final String? text =
        await _homeThemeChannel.invokeMethod<String>('getUserThemeText', id);
    if (text == null || text.isEmpty) {
      throw StateError('user theme file missing: $id');
    }
    return text;
  }
  return rootBundle.loadString('assets/peek_home/theme_$id.rfwtxt');
}

/// Saves theme source to a user-chosen document through the host.
/// Returns false when the user cancelled the save dialog.
Future<bool> exportThemeText(String fileName, String text) async {
  final bool? ok = await _homeThemeChannel.invokeMethod<bool>(
      'exportThemeText', <String, String>{'name': fileName, 'text': text});
  return ok ?? false;
}

/// One entry unpacked from a theme .zip by the host: [name] is the
/// file name inside the zip; [text] is its UTF-8 source (null when
/// the host skipped the entry, with the reason in [error]).
class ThemeZipEntry {
  const ThemeZipEntry({required this.name, this.text, this.error});

  final String name;
  final String? text;
  final String? error;
}

/// Picks a .zip and returns its theme sources for Dart-side import
/// (each entry goes through importUserThemeText, so validation and
/// md5 dedup match the single-file route). Returns null when the
/// user cancelled the picker; a [PlatformException] signals a bad
/// zip (not a .zip file, too many files, too big).
Future<List<ThemeZipEntry>?> importThemeZip() async {
  final List<dynamic>? raw = await _homeThemeChannel
      .invokeMethod<List<dynamic>>('importThemeZip');
  if (raw == null) return null;
  final List<ThemeZipEntry> entries = <ThemeZipEntry>[];
  for (final dynamic item in raw) {
    if (item is Map<dynamic, dynamic>) {
      entries.add(ThemeZipEntry(
        name: '${item['name'] ?? ''}',
        text: item['text'] as String?,
        error: item['error'] as String?,
      ));
    }
  }
  return entries;
}

/// Saves a batch of themes as one .zip through the host: [files]
/// are {'name': entry file name, 'text': RFW source} maps, zipped
/// host-side (this module has no archive dependency). Returns false
/// when the user cancelled the save dialog.
Future<bool> exportThemeZip(
    String fileName, List<Map<String, String>> files) async {
  final bool? ok = await _homeThemeChannel.invokeMethod<bool>(
      'exportThemeZip', <String, Object>{'name': fileName, 'files': files});
  return ok ?? false;
}

// ---------------------------------------------------------------------------
// Theme editor support
//
// The editor saves through the very same import path as a picked or
// pasted file (host validation, md5 id, files/home_themes storage);
// the only editor-specific step is writing the display name the
// user typed into the source, in exactly the place the host's
// display-name parser reads it: the leecat meta header's "name"
// when the source carries one, else the leading // comment line
// (prepended when the source has neither).
// ---------------------------------------------------------------------------

/// Returns [text] with its reported display name rewritten to
/// [name]. A name that sanitizes to empty leaves the source alone
/// (the host then derives the name as it does for imports).
String rewriteThemeDisplayName(String text, String name) {
  String clean =
      name.replaceAll(RegExp(r'[\n\r"\\$]'), ' ').trim();
  if (clean.length > 40) clean = clean.substring(0, 40);
  if (clean.isEmpty) return text;
  final int nl = text.indexOf('\n');
  final String first = (nl >= 0 ? text.substring(0, nl) : text).trim();
  final String rest = nl >= 0 ? text.substring(nl) : '';
  if (first.contains('leecat-theme:') && first.contains('{')) {
    final RegExp nameKey = RegExp(r'"name"\s*:\s*"[^"]*"');
    if (nameKey.hasMatch(first)) {
      return first.replaceFirst(nameKey, '"name": "$clean"') + rest;
    }
    final int brace = first.indexOf('{');
    final String tail = first.substring(brace + 1);
    final String injected =
        tail.trimLeft().startsWith('}') ? '"name": "$clean" ' : '"name": "$clean", ';
    return first.substring(0, brace + 1) + injected + tail + rest;
  }
  if (first.startsWith('//')) return '// $clean$rest';
  return '// $clean\n$text';
}
