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
