import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';
import 'package:rfw/formats.dart';

import 'home_theme.dart';
import 'ui_glass.dart';

/// The home theme source editor: a full-screen monospace source
/// box with an editable display name, reached from the theme
/// library — 编辑 on an imported theme, 编辑副本 on a built-in one,
/// and as the paste-import surface. Saving always lands in "我的"
/// through the same host import path a picked file takes (same
/// validation, same md5-id storage); a built-in is never
/// overwritten, and editing an imported theme replaces its file
/// with the new save (the old md5 file is removed once the new one
/// is stored). Before saving, the source must parse with the very
/// RFW parser the home bridge runs on every theme, so a broken edit
/// is refused here instead of failing on the home screen.
///
/// Pops with the saved [HomeThemeEntry], or null when backed out.
class HomeThemeEditorPage extends StatefulWidget {
  const HomeThemeEditorPage({
    super.key,
    required this.title,
    this.entry,
    this.editingId,
    this.startEmpty = false,
  });

  final String title;

  /// The theme whose source loads into the editor (a built-in for
  /// 编辑副本， the theme itself for 编辑）; null for paste-import.
  final HomeThemeEntry? entry;

  /// The imported theme being edited, whose stored file this save
  /// supersedes; null when the save is a fresh user theme.
  final String? editingId;

  /// Paste-import: start from an empty source box instead of
  /// loading [entry]'s source.
  final bool startEmpty;

  @override
  State<HomeThemeEditorPage> createState() => _HomeThemeEditorPageState();
}

class _HomeThemeEditorPageState extends State<HomeThemeEditorPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final HomeThemeEntry? entry = widget.entry;
    if (entry != null) {
      _nameController.text =
          widget.editingId != null ? entry.name : '${entry.name} 副本';
      if (!widget.startEmpty) {
        _loading = true;
        unawaited(_loadSource(entry.id));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _loadSource(String id) async {
    try {
      final String text = await loadThemeText(id);
      if (!mounted) return;
      _sourceController.text = text;
    } catch (_) {
      if (mounted) _showError('主题源码读取失败');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving || _loading) return;
    String text = _sourceController.text;
    if (text.trim().isEmpty) {
      _showError('请先填写或粘贴主题源码');
      return;
    }
    final String name = _nameController.text.trim();
    if (name.isNotEmpty) text = rewriteThemeDisplayName(text, name);
    // The same parser themed_home runs on every theme load: if it
    // cannot read the source, the home screen could not either.
    try {
      final parsed = parseLibraryFile(text);
      if (parsed.widgets.isEmpty) {
        throw StateError('源码里没有定义任何 widget');
      }
    } catch (e) {
      _showError('源码无法解析，未保存：$e');
      return;
    }
    setState(() => _saving = true);
    try {
      final HomeThemeEntry? entry = await importUserThemeText(text);
      if (entry == null) {
        _showError('保存失败');
        return;
      }
      // Editing an imported theme: the save stored a new md5 file,
      // so drop the superseded one (re-pointing the selection first
      // when the edited theme is the active one).
      final String? oldId = widget.editingId;
      if (oldId != null && oldId != entry.id) {
        if (homeThemeId.value == oldId) await setHomeThemeId(entry.id);
        await deleteUserTheme(oldId);
      }
      if (mounted) Navigator.of(context).pop(entry);
    } on PlatformException catch (e) {
      _showError(e.message ?? '保存失败');
    } catch (_) {
      _showError('保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
        actions: <Widget>[
          TextButton(
            onPressed: (_saving || _loading) ? null : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '主题名',
                      hintText: '保存后显示在主题库里',
                      border: glassInputBorder(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _sourceController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText: '粘贴或编辑 .lzt / .rfwtxt 主题源码（RFW 文本）',
                        alignLabelWithHint: true,
                        border: glassInputBorder(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '保存为「我的主题」，不会覆盖原主题；改 leecat 头里的 accent 等元数据，底栏配色会跟着变。保存前会先做一次源码解析校验。',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  // Clearance so the last source lines stay reachable
                  // above the resident glass bottom bar.
                  const SizedBox(height: 84),
                ],
              ),
            ),
    );
  }
}
