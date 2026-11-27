import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';

import 'home_theme.dart';
import 'home_theme_editor_page.dart';
import 'pigeon/c1_messages.g.dart';
import 'ui_glass.dart';

/// The home theme library (route /home-theme), modeled on the Lee
/// library: the active theme on top, filter chips （全部 / 内置 /
/// 我的） over one card grid, an import menu in the app bar (local
/// .lzt / .txt file, or pasted theme source — which now opens the
/// source editor) and a per-card menu with edit （编辑 on imported
/// themes, 编辑副本 on built-ins; the editor always saves into
/// 我的）, export, and delete for imported themes. Tapping a card
/// applies the theme immediately; the selection persists through
/// the host and the B11 home swaps its body live.
class HomeThemePage extends StatefulWidget {
  const HomeThemePage({super.key});

  @override
  State<HomeThemePage> createState() => _HomeThemePageState();
}

class _HomeThemePageState extends State<HomeThemePage> {
  /// 0 = 全部， 1 = 内置， 2 = 我的.
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    unawaited(loadUserThemes());
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

  Future<void> _importFile() async {
    try {
      final HomeThemeEntry? entry = await importUserTheme();
      if (entry != null) {
        setState(() => _filter = 2);
        _toast('已导入「${entry.name}」，点选即可应用');
      }
    } on PlatformException catch (e) {
      _toast(e.message ?? '导入失败');
    } catch (_) {
      _toast('导入失败');
    }
  }

  /// Paste-import goes through the source editor now: the big
  /// monospace box is a better paste surface than the old dialog,
  /// and the pasted source gets the same name field and parse
  /// check as an edit before it is saved as a user theme.
  Future<void> _importPaste() async {
    final HomeThemeEntry? entry =
        await Navigator.of(context).push<HomeThemeEntry>(
      MaterialPageRoute<HomeThemeEntry>(
        builder: (BuildContext context) => const HomeThemeEditorPage(
          title: '粘贴主题源码',
          startEmpty: true,
        ),
      ),
    );
    if (entry != null) {
      setState(() => _filter = 2);
      _toast('已保存「${entry.name}」，点选即可应用');
    }
  }

  /// 编辑 on an imported theme reopens its source; on a built-in
  /// it edits a copy — the save always lands in 我的， built-ins
  /// are never overwritten.
  Future<void> _edit(HomeThemeEntry entry) async {
    final bool mine = isUserThemeId(entry.id);
    final HomeThemeEntry? saved =
        await Navigator.of(context).push<HomeThemeEntry>(
      MaterialPageRoute<HomeThemeEntry>(
        builder: (BuildContext context) => HomeThemeEditorPage(
          title: mine ? '编辑主题' : '编辑副本',
          entry: entry,
          editingId: mine ? entry.id : null,
        ),
      ),
    );
    if (saved != null) {
      setState(() => _filter = 2);
      _toast('已保存「${saved.name}」，点选即可应用');
    }
  }

  Future<void> _export(HomeThemeEntry entry) async {
    try {
      final String text = await loadThemeText(entry.id);
      final bool ok = await exportThemeText('${entry.name}.lzt', text);
      _toast(ok ? '已导出「${entry.name}」' : '已取消导出');
    } catch (_) {
      _toast('导出失败');
    }
  }

  Future<void> _delete(HomeThemeEntry entry) async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: glassButtonColor(
            context,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          title: Text('删除「${entry.name}」？'),
          content: const Text('删除后无法恢复，需要重新导入主题文件。'),
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
      await deleteUserTheme(entry.id);
      _toast('已删除「${entry.name}」');
    } catch (_) {
      _toast('删除失败');
    }
  }

  void _onCardMenu(HomeThemeEntry entry, String action) {
    if (action == 'edit') unawaited(_edit(entry));
    if (action == 'export') unawaited(_export(entry));
    if (action == 'delete') unawaited(_delete(entry));
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
        title: const Text('首页主题'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入主题',
            onSelected: (String value) {
              if (value == 'file') unawaited(_importFile());
              if (value == 'paste') unawaited(_importPaste());
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'file',
                child: Text('本地 .lzt / .txt 文件'),
              ),
              const PopupMenuItem<String>(
                value: 'paste',
                child: Text('粘贴主题源码'),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: homeThemeId,
        builder: (BuildContext context, String activeId, Widget? child) {
          return ValueListenableBuilder<List<HomeThemeEntry>>(
            valueListenable: userThemes,
            builder: (BuildContext context, List<HomeThemeEntry> mine,
                Widget? child) {
              final HomeThemeEntry active = homeThemeEntry(activeId);
              final List<HomeThemeEntry> shown = switch (_filter) {
                1 => homeThemeCatalog,
                2 => mine,
                _ => <HomeThemeEntry>[...mine, ...homeThemeCatalog],
              };
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
                  _ThemeCard(entry: active, active: true, onTap: null),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      _FilterChip(
                        label: '全部 ${mine.length + homeThemeCatalog.length}',
                        selected: _filter == 0,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '内置 ${homeThemeCatalog.length}',
                        selected: _filter == 1,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '我的 ${mine.length}',
                        selected: _filter == 2,
                        onTap: () => setState(() => _filter = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '还没有导入的主题，点右上角导入 .lzt / .txt 主题文件，或粘贴主题源码。',
                        style: TextStyle(
                          fontSize: 13,
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
                        for (final HomeThemeEntry entry in shown)
                          _ThemeCard(
                            entry: entry,
                            active: entry.id == activeId,
                            onTap: () => setHomeThemeId(entry.id),
                            onMenu: entry.id.isEmpty
                                ? null
                                : (String action) =>
                                    _onCardMenu(entry, action),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '点选即应用，返回首页查看效果。主题只改变首页的样子，不影响站源与播放。卡片右上角菜单可导出主题文件，也可编辑源码（内置主题是编辑副本，永远另存为我的主题），我的主题还可以删除。',
                    style: TextStyle(
                      fontSize: 12,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: glassButtonColor(
            context,
            selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
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

  final HomeThemeEntry entry;
  final bool active;
  final VoidCallback? onTap;

  /// Card menu callback ('export' / 'delete'); null hides the menu
  /// (the default theme cannot be exported or deleted).
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
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(
                                isUserThemeId(entry.id) ? '编辑' : '编辑副本'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'export',
                            child: Text('导出'),
                          ),
                          if (isUserThemeId(entry.id))
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('删除'),
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
