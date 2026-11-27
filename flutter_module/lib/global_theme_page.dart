import 'dart:async' show unawaited;

import 'package:material_ui/material_ui.dart';

import 'global_theme.dart';
import 'global_theme_editor_page.dart';
import 'pigeon/c1_messages.g.dart';
import 'ui_glass.dart';

/// The global theme library (route /global-theme): one card per
/// palette package, the active package on top, tap to apply. A
/// package is a whole-app ThemeProfile the host writes through its
/// profile store, and every screen (Flutter via the shared ui_config
/// tokens, native via ThemeController) follows the saved profile.
///
/// Below the built-in catalog sits 我的： packages the user built
/// in the editor (see global_theme_editor_page.dart). Built-ins can
/// only be used as editor templates — saving always creates or
/// updates a user package, never a built-in.
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
    unawaited(loadUserGlobalThemes());
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

  /// Opens the editor on [sourceId] as the template (or, when
  /// [editingId] is set, on that user package itself).
  Future<void> _openEditor({
    required String sourceId,
    String? editingId,
  }) async {
    final GlobalThemeEntry? saved =
        await Navigator.of(context).push<GlobalThemeEntry>(
      MaterialPageRoute<GlobalThemeEntry>(
        builder: (BuildContext context) => GlobalThemeEditorPage(
          sourceId: sourceId,
          editingId: editingId,
        ),
      ),
    );
    if (saved != null) _toast('已保存「${saved.name}」');
  }

  /// The 新建我的主题 button: start from the current selection as
  /// the template when there is one, else from the default package.
  void _create() {
    final String activeId = globalThemeId.value;
    unawaited(_openEditor(
      sourceId: activeId == globalThemeCustomId ? '' : activeId,
    ));
  }

  Future<void> _deleteUser(GlobalThemeEntry entry) async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: glassButtonColor(
            context,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          title: Text('删除「${entry.name}」？'),
          content: const Text('删除后无法恢复。正在用这套配色的话，颜色会保留，但选中状态会变为自定义。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                side: glassFrameSide(context),
                backgroundColor: glassButtonColor(
                  context,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (sure != true) return;
    try {
      await deleteUserGlobalTheme(entry.id);
      _toast('已删除「${entry.name}」');
    } catch (_) {
      _toast('删除失败');
    }
  }

  void _onCardMenu(GlobalThemeEntry entry, String action) {
    if (action == 'template') {
      unawaited(_openEditor(sourceId: entry.id));
    } else if (action == 'edit') {
      unawaited(_openEditor(sourceId: entry.id, editingId: entry.id));
    } else if (action == 'delete') {
      unawaited(_deleteUser(entry));
    }
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
          return ValueListenableBuilder<List<GlobalThemeEntry>>(
            valueListenable: userGlobalThemes,
            builder: (BuildContext context, List<GlobalThemeEntry> mine,
                Widget? child) {
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
                  Text(
                    '内置主题',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          onMenu: (String action) =>
                              _onCardMenu(entry, action),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Text(
                        '我的主题',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建我的主题'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (mine.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '还没有自己的主题。点「新建我的主题」，或在任意内置主题的菜单里选「以此为模板新建」，改一组配色存下来。',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        for (final GlobalThemeEntry entry in mine)
                          _ThemeCard(
                            entry: entry,
                            active: entry.id == activeId,
                            onTap: () => unawaited(_apply(entry)),
                            onMenu: (String action) =>
                                _onCardMenu(entry, action),
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
    this.onMenu,
  });

  final GlobalThemeEntry entry;
  final bool active;
  final VoidCallback? onTap;

  /// Card menu callback ('template' on built-ins; 'edit' / 'delete'
  /// on user packages); null hides the menu (the 当前主题 card).
  final void Function(String action)? onMenu;

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
                  if (onMenu != null)
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: bandText, size: 20),
                        padding: EdgeInsets.zero,
                        onSelected: onMenu,
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          if (isUserGlobalThemeId(entry.id)) ...<PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('编辑'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('删除'),
                            ),
                          ] else
                            const PopupMenuItem<String>(
                              value: 'template',
                              child: Text('以此为模板新建'),
                            ),
                        ],
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
