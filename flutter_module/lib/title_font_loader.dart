import 'dart:io' show File;
import 'dart:typed_data' show ByteData, Uint8List;
import 'package:flutter/services.dart' show FontLoader, MethodChannel;

/// 标题字体（衬线/文楷）的按需加载：两款字体不再随包内置，改走「标题字体」模块。
///
/// 流程：主题（或编辑器预览）要用 NotoSerifSC / LXGWWenKaiLite 时，
/// 先问宿主拿模块目录里的字体文件路径，读出字节后经 [FontLoader] 注册到当前引擎；
/// 未安装模块、路径为空或注册失败时返回 false，调用方保持原样渲染
/// （Flutter 对未注册的 family 会回落系统默认字体，不会出豆腐块）。
///
/// 只记成功：失败不缓存，下次切换主题/重进页面会再试一次（用户装好模块后无需重启）。
/// 成功即永久：字体注册进引擎后随缓存引擎常驻，同一进程内不再重复加载。
const MethodChannel _fontChannel =
    MethodChannel('com.github.maoyingshi.osc.tv/ui_config');

/// 已注册进当前引擎的字体 family（进程内常驻，随缓存引擎共存亡）。
final Set<String> _loadedFamilies = <String>{};

/// 本包管理的字体 family（与 ModuleDefinition.FONTS.files 一致）。
bool isModuleTitleFontFamily(String? family) =>
    family == 'NotoSerifSC' || family == 'LXGWWenKaiLite';

/// 确保 [family] 已注册进当前引擎。已注册返回 true；否则问宿主取模块内文件路径，
/// 读字节后注册。未安装/读不到/注册失败返回 false（调用方回落系统字体）。
Future<bool> ensureTitleFontLoaded(String family) async {
  if (_loadedFamilies.contains(family)) return true;
  try {
    final String? path =
        await _fontChannel.invokeMethod<String>('getFontFilePath', family);
    if (path == null || path.isEmpty) return false;
    final Uint8List bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) return false;
    final FontLoader loader = FontLoader(family);
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loadedFamilies.add(family);
    return true;
  } catch (_) {
    return false;
  }
}
