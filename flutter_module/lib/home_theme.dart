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
  ),
  HomeThemeEntry(
    id: 'bubble',
    name: '柔彩气泡',
    tag: '胖轮播 · 大圆角',
    description: '柔和马卡龙色，大圆角卡片像气泡一样轻盈。',
    colors: <Color>[Color(0xFFFF7FB5), Color(0xFFFFD3E0), Color(0xFFB5E7FF)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'cloud_archive',
    name: '云幕典藏',
    tag: '竖版轮播 · 暗金玻璃',
    description: '为竖版海报设计的高级感主题，窄幅轮播、当前卡片抬升。',
    colors: <Color>[Color(0xFF10131A), Color(0xFFC9A86A)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'crimson_cinema',
    name: '赤焰影院',
    tag: '超高轮播 · 沉浸主视觉',
    description: '黑红影院风格，超高轮播带来大面积主视觉冲击。',
    colors: <Color>[Color(0xFF1A0505), Color(0xFFE53935)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'editorial',
    name: '银幕杂志',
    tag: '无轮播 · 编辑排版',
    description: '像杂志内页一样排版：大编号、宽幅图、清晰的文字层级。',
    colors: <Color>[Color(0xFFF5F0E8), Color(0xFF212121)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'horizontal_gallery',
    name: '横向影廊',
    tag: '无轮播 · 宽幅剧照墙',
    description: '默认就是宽幅剧照墙，图片上直接叠渐变文字层。',
    colors: <Color>[Color(0xFF263238), Color(0xFF90A4AE)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'immersive_palette',
    name: '沉浸光影',
    tag: '海报取色 · 独立主视觉',
    description: '参考 TMDB 详情页：顶部主视觉承载海报与取色氛围。',
    colors: <Color>[Color(0xFF0B0B10), Color(0xFF5E35B1)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'ink_minimal',
    name: '墨白极简',
    tag: '无轮播 · 黑白极简',
    description: '最少装饰、黑白配色，布局可在海报、图文行、文字行间切换。',
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFF111111)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'midnight_rank',
    name: '午夜榜单',
    tag: '无轮播 · 排名榜单',
    description: '以排名和文字为主的深夜榜单风，默认无图、靠名次说话。',
    colors: <Color>[Color(0xFF0D0D19), Color(0xFFFFE44D)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'pixel_arcade',
    name: '像素街机',
    tag: '无轮播 · 硬边撞色',
    description: '方形组件、偏移硬阴影、醒目编号，街机厅的硬朗撞色。',
    colors: <Color>[Color(0xFFFFE44D), Color(0xFF2979FF)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'snow_glass',
    name: '雪境玻璃',
    tag: '矮轮播 · 轻量横幅',
    description: '低矮轮播加明亮卡片，像雪后初晴的通透玻璃感。',
    colors: <Color>[Color(0xFFF1F8FC), Color(0xFF75BDE8)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'sunlit_gallery',
    name: '暖阳影廊',
    tag: '竖版层叠轮播 · 暖色',
    description: '明亮暖色的竖版层叠轮播，左右卡片像画廊一样排开。',
    colors: <Color>[Color(0xFFFFF3E0), Color(0xFFFF9800)],
    dark: false,
  ),
  HomeThemeEntry(
    id: 'terminal',
    name: '绿幕终端',
    tag: '无轮播 · 纯文字',
    description: '等宽字体的绿幕终端风，默认纯文字列表，冷静克制。',
    colors: <Color>[Color(0xFF001A00), Color(0xFF00E676)],
    dark: true,
  ),
  HomeThemeEntry(
    id: 'vhs',
    name: '复古录像厅',
    tag: '窄幅胶片轮播',
    description: '一屏多张的胶片轮播，暖色渐变与方角标签带你回录像厅。',
    colors: <Color>[Color(0xFF2D1B4E), Color(0xFFFF7043)],
    dark: true,
  ),
];

HomeThemeEntry homeThemeEntry(String id) {
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
