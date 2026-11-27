import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';

import 'global_theme.dart';
import 'global_theme_editor_page.dart';
import 'home_theme.dart';
import 'home_theme_editor_page.dart';
import 'merged_theme.dart';
import 'pigeon/c1_messages.g.dart';
import 'theme_editor_page.dart';
import 'ui_glass.dart';

/// The merged theme library (routes /theme, /home-theme and
/// /global-theme all land here; the latter two open the matching
/// filter). One card per theme, where a theme is a home structure
/// bound to a whole-app palette — plus palette-only cards for the
/// global packages, which leave the structure alone.
///
/// Tapping a card applies it immediately (one host call writes the
/// structure and the palette; see merged_theme.dart). The app bar
/// keeps the source import menu （本地文件 / 粘贴源码） as the
/// advanced route, and each card's menu reaches the parametric
/// editor, the source editor, export and delete as its kind allows.
///
/// Back behaviour: entering this page is a host route assertion
/// (B7 row -> C1ScreenActivity.start -> onNewIntent recordPush ->
/// _showRoute replaces the root stack), so the host history holds
/// [/settings, /theme] and the host root back would land back on
/// the settings home — but only if Dart signals it. The PopScope
/// below converts a system back press into that signal
/// (closeScreen), exactly like every other top-level page; without
/// it the press dies at the root Navigator (this page is its only
/// route) and the unhandled pop closes the whole task to the
/// desktop. The filters are plain page state, never routes, and
/// both editors are pushed as plain routes above this page, so
/// back from an editor pops back here.
class ThemeLibraryPage extends StatefulWidget {
  const ThemeLibraryPage({super.key, this.initialFilter = 0});

  /// 0 = 全部， 1 = 内置， 2 = 我的， 3 = 仅配色.
  final int initialFilter;

  @override
  State<ThemeLibraryPage> createState() => _ThemeLibraryPageState();
}

class _ThemeLibraryPageState extends State<ThemeLibraryPage> {
  late int _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    unawaited(loadMergedThemeId());
    unawaited(loadMergedUserThemes());
    unawaited(loadUserThemes());
    unawaited(loadUserGlobalThemes());
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

  Future<void> _apply(MergedThemeEntry entry) async {
    final bool ok = await applyMergedTheme(entry);
    _toast(ok ? '已应用「${entry.name}」' : '应用失败');
  }

  Future<void> _create() async {
    final String? saved = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) => const ThemeEditorPage(),
      ),
    );
    if (saved != null) {
      setState(() => _filter = 2);
      _toast('已保存，点选即可应用');
    }
  }

  Future<void> _editParametric(MergedThemeEntry entry) async {
    final String? saved = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) => ThemeEditorPage(
          initial: paramsFromMergedEntry(entry),
          editingId: entry.record?.id,
        ),
      ),
    );
    if (saved != null) {
      setState(() => _filter = 2);
      _toast('已保存，点选即可应用');
    }
  }

  /// The source editor stays as the advanced entry: on an imported
  /// theme it edits its source; on a built-in, a copy.
  Future<void> _editSource(HomeThemeEntry entry) async {
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

  Future<void> _editGlobalPackage(GlobalThemeEntry entry) async {
    final GlobalThemeEntry? saved =
        await Navigator.of(context).push<GlobalThemeEntry>(
      MaterialPageRoute<GlobalThemeEntry>(
        builder: (BuildContext context) => GlobalThemeEditorPage(
          sourceId: entry.id,
          editingId: isUserGlobalThemeId(entry.id) ? entry.id : null,
        ),
      ),
    );
    if (saved != null) _toast('已保存「${saved.name}」');
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

  Future<void> _export(HomeThemeEntry entry) async {
    try {
      final String text = await loadThemeText(entry.id);
      final bool ok = await exportThemeText('${entry.name}.lzt', text);
      _toast(ok ? '已导出「${entry.name}」' : '已取消导出');
    } catch (_) {
      _toast('导出失败');
    }
  }

  /// A zip-safe file name for one exported theme: illegal
  /// characters become '_', and names that collide after
  /// sanitizing get a ' (2)' / ' (3)' suffix before the extension.
  String _zipEntryName(String name, Set<String> used) {
    String base =
        name.replaceAll(RegExp(r'[\/\\:*?"<>|\x00-\x1F]'), '_').trim();
    if (base.isEmpty) base = '未命名主题';
    String stem = base;
    int n = 2;
    while (used.contains('$stem.lzt')) {
      stem = '$base ($n)';
      n++;
    }
    used.add('$stem.lzt');
    return '$stem.lzt';
  }

  /// Shows a batch result: how many went through and, for the ones
  /// that did not, each name with its reason. A toast cannot hold a
  /// list, so failures always get this dialog.
  Future<void> _showBatchResult(
      String title, String summary, List<String> failures) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: glassButtonColor(
            context,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          title: Text(title),
          content: Text('$summary\n${failures.join('\n')}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importBatch() async {
    List<ThemeZipEntry>? entries;
    try {
      entries = await importThemeZip();
    } on PlatformException catch (e) {
      _toast(e.message ?? '导入失败');
      return;
    } catch (_) {
      _toast('导入失败');
      return;
    }
    if (entries == null) return;
    if (entries.isEmpty) {
      _toast('压缩包里没有主题文件');
      return;
    }
    final Set<String> before = <String>{
      for (final HomeThemeEntry e in userThemes.value) e.id,
    };
    final List<String> imported = <String>[];
    final List<String> existed = <String>[];
    final List<String> failures = <String>[];
    for (final ThemeZipEntry zipEntry in entries) {
      if (zipEntry.text == null) {
        failures.add('${zipEntry.name}：${zipEntry.error ?? '无法读取'}');
        continue;
      }
      try {
        final HomeThemeEntry? entry =
            await importUserThemeText(zipEntry.text!);
        if (entry == null) {
          failures.add('${zipEntry.name}：导入失败');
        } else if (before.contains(entry.id)) {
          existed.add(entry.name);
        } else {
          imported.add(entry.name);
        }
      } on PlatformException catch (e) {
        failures.add('${zipEntry.name}：${e.message ?? '不是有效的主题源码'}');
      } catch (_) {
        failures.add('${zipEntry.name}：导入失败');
      }
    }
    if (mounted) setState(() => _filter = 2);
    if (failures.isEmpty) {
      _toast(existed.isEmpty
          ? '已导入 ${imported.length} 个主题'
          : '已导入 ${imported.length} 个主题，${existed.length} 个已存在');
    } else {
      await _showBatchResult(
        '批量导入结果',
        '已导入 ${imported.length} 个'
            '${existed.isEmpty ? '' : '，${existed.length} 个已存在'}，'
            '${failures.length} 个失败：',
        failures,
      );
    }
  }

  Future<void> _exportBatch() async {
    final List<MergedThemeEntry> mine = <MergedThemeEntry>[
      ...mergedRecordEntries(mergedUserThemes.value),
      ...mergedUserSourceEntries(
          mergedUserThemes.value, userThemes.value),
    ];
    if (mine.isEmpty) {
      _toast('还没有自己的主题可导出');
      return;
    }
    final List<Map<String, String>> files = <Map<String, String>>[];
    final List<String> failures = <String>[];
    final Set<String> usedNames = <String>{};
    for (final MergedThemeEntry entry in mine) {
      final MergedThemeRecord? record = entry.record;
      final HomeThemeEntry? homeEntry = entry.homeEntry;
      final String sourceId =
          record != null ? record.structureSourceId : (homeEntry?.id ?? '');
      if (sourceId.isEmpty) {
        failures.add('${entry.name}：没有可导出的源码');
        continue;
      }
      try {
        String text = await loadThemeText(sourceId);
        if (record != null) {
          text = rewriteThemeDisplayName(text, record.params.name);
        }
        files.add(<String, String>{
          'name': _zipEntryName(entry.name, usedNames),
          'text': text,
        });
      } catch (_) {
        failures.add('${entry.name}：源码读取失败');
      }
    }
    if (files.isEmpty) {
      await _showBatchResult('批量导出结果', '没有主题导出成功，失败：', failures);
      return;
    }
    try {
      final bool ok = await exportThemeZip('陌奥影视主题.zip', files);
      if (!ok) {
        _toast('已取消导出');
        return;
      }
      if (failures.isEmpty) {
        _toast('已导出 ${files.length} 个主题');
      } else {
        await _showBatchResult(
          '批量导出结果',
          '已导出 ${files.length} 个主题，${failures.length} 个失败：',
          failures,
        );
      }
    } on PlatformException catch (e) {
      _toast(e.message ?? '导出失败');
    } catch (_) {
      _toast('导出失败');
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: glassButtonColor(
            context,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          title: Text(title),
          content: Text(body),
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
    return sure ?? false;
  }

  Future<void> _delete(MergedThemeEntry entry) async {
    if (!await _confirm('删除「${entry.name}」？', '删除后无法恢复。')) return;
    try {
      if (entry.record != null) {
        final MergedThemeRecord record = entry.record!;
        final String nowStructure = await deleteMergedThemeRecord(record.id);
        if (nowStructure != homeThemeId.value) {
          homeThemeId.value = nowStructure;
        }
        if (homeThemeId.value != record.structureSourceId) {
          await deleteUserTheme(record.structureSourceId);
        }
        await loadMergedThemeId();
      } else if (entry.globalEntry != null &&
          isUserGlobalThemeId(entry.globalEntry!.id)) {
        await deleteUserGlobalTheme(entry.globalEntry!.id);
      } else if (entry.homeEntry != null) {
        await deleteUserTheme(entry.homeEntry!.id);
      }
      _toast('已删除「${entry.name}」');
    } catch (_) {
      _toast('删除失败');
    }
  }

  void _onCardMenu(MergedThemeEntry entry, String action) {
    switch (action) {
      case 'parametric':
        unawaited(_editParametric(entry));
      case 'source':
        if (entry.homeEntry != null) unawaited(_editSource(entry.homeEntry!));
      case 'globalEdit':
        if (entry.globalEntry != null) {
          unawaited(_editGlobalPackage(entry.globalEntry!));
        }
      case 'export':
        if (entry.homeEntry != null) unawaited(_export(entry.homeEntry!));
      case 'delete':
        unawaited(_delete(entry));
    }
  }

  List<PopupMenuEntry<String>> _menuItems(MergedThemeEntry entry) {
    final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];
    if (entry.record != null) {
      items.add(const PopupMenuItem<String>(
          value: 'parametric', child: Text('编辑')));
      items.add(const PopupMenuItem<String>(
          value: 'delete', child: Text('删除')));
      return items;
    }
    if (entry.isPaletteOnly) {
      if (entry.globalEntry != null && isUserGlobalThemeId(entry.globalEntry!.id)) {
        items.add(const PopupMenuItem<String>(
            value: 'globalEdit', child: Text('编辑配色')));
        items.add(const PopupMenuItem<String>(
            value: 'parametric', child: Text('以此新建主题')));
        items.add(const PopupMenuItem<String>(
            value: 'delete', child: Text('删除')));
      } else {
        items.add(const PopupMenuItem<String>(
            value: 'parametric', child: Text('以此新建主题')));
        items.add(const PopupMenuItem<String>(
            value: 'globalEdit', child: Text('以此为模板新建（配色）')));
      }
      return items;
    }
    // Structure cards.
    items.add(PopupMenuItem<String>(
      value: 'parametric',
      child: Text(entry.isUser ? '编辑' : '编辑副本'),
    ));
    if (entry.homeEntry != null && entry.homeEntry!.id.isNotEmpty) {
      items.add(PopupMenuItem<String>(
        value: 'source',
        child: Text(isUserThemeId(entry.homeEntry!.id) ? '源码编辑' : '源码编辑（副本）'),
      ));
      if (entry.homeEntry!.id.isNotEmpty)
        items.add(const PopupMenuItem<String>(
            value: 'export', child: Text('导出')));
      if (isUserThemeId(entry.homeEntry!.id)) {
        items.add(const PopupMenuItem<String>(
            value: 'delete', child: Text('删除')));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // System back takes the same path as the app-bar arrow
    // (_onBack -> closeScreen -> the host pops its route history
    // back to /settings). Every other top-level page carries this
    // PopScope; this page shipped without one, so a system back
    // press fell through the root Navigator to the system and
    // closed the task to the desktop.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        unawaited(_onBack());
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const GlassSurface(child: SizedBox.expand()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: const Text('主题'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入 / 导出',
            onSelected: (String value) {
              if (value == 'file') unawaited(_importFile());
              if (value == 'paste') unawaited(_importPaste());
              if (value == 'batchImport') unawaited(_importBatch());
              if (value == 'batchExport') unawaited(_exportBatch());
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
              const PopupMenuItem<String>(
                value: 'batchImport',
                child: Text('批量导入（.zip）'),
              ),
              const PopupMenuItem<String>(
                value: 'batchExport',
                child: Text('批量导出（.zip）'),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: mergedThemeId,
        builder: (BuildContext context, String activeMergedId, Widget? _) {
          return ValueListenableBuilder<List<MergedThemeRecord>>(
            valueListenable: mergedUserThemes,
            builder: (BuildContext context,
                List<MergedThemeRecord> records, Widget? _) {
              return ValueListenableBuilder<List<HomeThemeEntry>>(
                valueListenable: userThemes,
                builder: (BuildContext context,
                    List<HomeThemeEntry> sources, Widget? _) {
                  return ValueListenableBuilder<List<GlobalThemeEntry>>(
                    valueListenable: userGlobalThemes,
                    builder: (BuildContext context,
                        List<GlobalThemeEntry> userGlobals, Widget? _) {
                      return _body(
                        context,
                        scheme,
                        activeMergedId,
                        records,
                        sources,
                        userGlobals,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ColorScheme scheme,
    String activeMergedId,
    List<MergedThemeRecord> records,
    List<HomeThemeEntry> sources,
    List<GlobalThemeEntry> userGlobals,
  ) {
    final List<MergedThemeEntry> catalog = mergedCatalog();
    final List<MergedThemeEntry> structures = <MergedThemeEntry>[
      for (final MergedThemeEntry e in catalog) if (!e.isPaletteOnly) e,
    ];
    final List<MergedThemeEntry> palettesOnly = <MergedThemeEntry>[
      for (final MergedThemeEntry e in catalog) if (e.isPaletteOnly) e,
      ...mergedUserGlobalEntries(userGlobals),
    ];
    final List<MergedThemeEntry> mine = <MergedThemeEntry>[
      ...mergedRecordEntries(records),
      ...mergedUserSourceEntries(records, sources),
      ...mergedUserGlobalEntries(userGlobals),
    ];
    final List<MergedThemeEntry> shown = switch (_filter) {
      1 => structures,
      2 => mine,
      3 => palettesOnly,
      _ => <MergedThemeEntry>[
          ...mergedRecordEntries(records),
          ...mergedUserSourceEntries(records, sources),
          ...catalog,
          ...mergedUserGlobalEntries(userGlobals),
        ],
    };
    MergedThemeEntry? active;
    for (final MergedThemeEntry e in <MergedThemeEntry>[
      ...mine,
      ...catalog,
      ...mergedUserGlobalEntries(userGlobals),
    ]) {
      if (e.id == activeMergedId) active = e;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text(
          '当前主题',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (active != null)
          _MergedCard(entry: active, active: true, onTap: null)
        else
          _CurrentSummaryCard(scheme: scheme),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            side: glassFrameSide(context),
            backgroundColor: glassButtonColor(context, scheme.primaryContainer),
            foregroundColor: scheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => unawaited(_create()),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add, size: 18),
              SizedBox(width: 6),
              Text('新建我的主题'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _FilterChip(
              label: '全部 ${mine.length + catalog.length}',
              selected: _filter == 0,
              onTap: () => setState(() => _filter = 0),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '内置 ${structures.length}',
              selected: _filter == 1,
              onTap: () => setState(() => _filter = 1),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '我的 ${mine.length}',
              selected: _filter == 2,
              onTap: () => setState(() => _filter = 2),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '仅配色 ${palettesOnly.length}',
              selected: _filter == 3,
              onTap: () => setState(() => _filter = 3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _filter == 2
                  ? '还没有自己的主题，点「新建我的主题」用参数编辑器做一套，或从右上角导入主题文件。'
                  : '这里还没有主题。',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
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
              for (final MergedThemeEntry entry in shown)
                _MergedCard(
                  entry: entry,
                  active: entry.id == activeMergedId,
                  onTap: () => unawaited(_apply(entry)),
                  menuItems: _menuItems(entry),
                  onMenu: (String action) => _onCardMenu(entry, action),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          '点选即应用：结构与配色一起生效，返回首页直接看新样子。「仅配色」的卡只换全 App 颜色，不动首页结构。卡片菜单里可以打开参数编辑器改组件与配色，或进源码编辑（高级）。',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The pre-merge state header: no merged theme has been applied
/// yet, so the current structure and palette are reported apart
/// (they were picked independently and both still hold).
class _CurrentSummaryCard extends StatelessWidget {
  const _CurrentSummaryCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: homeThemeId,
      builder: (BuildContext context, String structureId, Widget? _) {
        return ValueListenableBuilder<String>(
          valueListenable: globalThemeId,
          builder: (BuildContext context, String paletteId, Widget? _) {
            final HomeThemeEntry structure = homeThemeEntry(structureId);
            final GlobalThemeEntry? palette = globalThemeEntry(paletteId);
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '首页结构「${structure.name}」 · 配色「${palette?.name ?? '自定义'}」'
                  '（分别沿用之前的选择，在下方点任意主题即合并应用）',
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
            );
          },
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _MergedCard extends StatelessWidget {
  const _MergedCard({
    required this.entry,
    required this.active,
    required this.onTap,
    this.menuItems,
    this.onMenu,
  });

  final MergedThemeEntry entry;
  final bool active;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>>? menuItems;
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
                  if (menuItems != null && menuItems!.isNotEmpty)
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: bandText, size: 20),
                        padding: EdgeInsets.zero,
                        onSelected: onMenu,
                        itemBuilder: (BuildContext context) => menuItems!,
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
