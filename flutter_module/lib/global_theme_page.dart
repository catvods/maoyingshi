import 'dart:async' show unawaited;

import 'package:material_ui/material_ui.dart';

import 'global_theme.dart';
import 'pigeon/c1_messages.g.dart';
import 'ui_glass.dart';

/// The global theme library (route /global-theme): one card per
/// palette package, the active package on top, tap to apply. Unlike
/// the home theme library there is nothing to import or export here —
/// a package is a whole-app ThemeProfile the host writes through its
/// profile store, and every screen (Flutter via the shared ui_config
/// tokens, native via ThemeController) follows the saved profile.
class GlobalThemePage extends StatefulWidget {
  const GlobalThemePage({super.key});

  @override
  State<GlobalThemePage> createState() => _GlobalThemePageState();
}

class _GlobalThemePageState extends State<GlobalThemePage> {
  @override
  void initState() {
    super.initState();
    unawaited(loadGlobalThemeId());
  }

  Future<void> _onBack() async {
    try {
      await C1HostApi().closeScreen();
    } catch (_) {
      // The host is gone; nothing to go back to.
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _apply(GlobalThemeEntry entry) async {
    if (entry.id == globalThemeId.value) return;
    final bool ok = await setGlobalThemeId(entry.id);
    _toast(ok ? '已应用「${entry.name}」' : '应用失败，请重试');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const GlassSurface(child: SizedBox.expand()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: const Text('全局主题'),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: globalThemeId,
        builder: (BuildContext context, String activeId, Widget? child) {
          final GlobalThemeEntry? active = globalThemeEntry(activeId);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              Text(
                '当前主题',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (active != null)
                _ThemeCard(entry: active, active: true, onTap: null)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: glassButtonColor(
                      context,
                      scheme.surfaceContainerHigh,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    '自定义配色（来自「主题色彩」的单独调色）。点选下面任意一套，即切换为全局主题。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  for (final GlobalThemeEntry entry in globalThemeCatalog)
                    _ThemeCard(
                      entry: entry,
                      active: entry.id == activeId,
                      onTap: () => unawaited(_apply(entry)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '点选即应用，整个应用的配色随之改变：首页、搜索、设置、详情和原生页面都会跟随。全局主题只管配色，不改首页布局（布局在「首页主题」里换）；应用一套会覆盖「主题色彩」里的单独调色，之后再去那边微调，这里的选中会变为自定义。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final GlobalThemeEntry entry;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bandText = entry.dark ? Colors.white : const Color(0xFF1B1B1F);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: entry.colors,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      entry.name,
                      style: TextStyle(
                        color: bandText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (active)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '使用中',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                entry.tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                entry.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
