import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';

import 'color_picker.dart';
import 'global_theme.dart';
import 'ui_glass.dart';

/// The global theme editor: a color form over a package's core
/// slots — name, then the light and dark palettes (primary /
/// containers / surfaces / text / outline). It opens on a template:
/// a built-in package （以此为模板新建 or the page's 新建）, or an
/// existing user package being edited. Saving always writes a user
/// package through the host (never over a built-in); the host
/// starts from the template's full ThemeProfile and overrides just
/// these core slots, so slots the form does not expose keep the
/// template's character. Colors are picked from the shared
/// visual colour picker (preset swatches + HSV sliders) or typed
/// as #RRGGBB hex.
///
/// Pops with the saved [GlobalThemeEntry], or null when backed out.
class GlobalThemeEditorPage extends StatefulWidget {
  const GlobalThemeEditorPage({
    super.key,
    required this.sourceId,
    this.editingId,
  });

  /// The package whose values prefill the form: a built-in catalog
  /// id ('' = default) for a creation, the user package itself for
  /// an edit.
  final String sourceId;

  /// The user package being edited; null when creating a new one
  /// from [sourceId] as the template.
  final String? editingId;

  @override
  State<GlobalThemeEditorPage> createState() => _GlobalThemeEditorPageState();
}

/// Form labels for the core slots, in form order (the order of
/// [globalThemeCoreSlots]).
const Map<String, String> _slotLabels = <String, String>{
  'primary': '主色',
  'primaryContainer': '主色容器',
  'surface': '背景',
  'surfaceContainer': '表面（卡片）',
  'surfaceContainerHigh': '表面（高层）',
  'onSurface': '文字',
  'onSurfaceVariant': '次要文字',
  'outline': '描边',
};

String? _normalizeHex(String raw) {
  String h = raw.trim().replaceAll('#', '');
  if (h.length == 3) {
    h = h.split('').map((String c) => '$c$c').join();
  }
  if (h.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(h)) return null;
  return '#${h.toUpperCase()}';
}

Color? _hexColor(String raw) {
  final String? normalized = _normalizeHex(raw);
  if (normalized == null) return null;
  return Color(0xFF000000 | int.parse(normalized.substring(1), radix: 16));
}

class _GlobalThemeEditorPageState extends State<GlobalThemeEditorPage> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, TextEditingController> _light =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _dark =
      <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final String slot in globalThemeCoreSlots) {
      _light[slot] = TextEditingController()
        ..addListener(_refresh);
      _dark[slot] = TextEditingController()..addListener(_refresh);
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final TextEditingController c in _light.values) {
      c.dispose();
    }
    for (final TextEditingController c in _dark.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final GlobalThemeEditorData data =
          await getGlobalThemeEditorData(widget.sourceId);
      if (!mounted) return;
      _nameController.text = widget.editingId != null
          ? data.name
          : (data.name.isEmpty ? '' : '${data.name} 副本');
      for (final String slot in globalThemeCoreSlots) {
        _light[slot]!.text = data.light[slot] ?? '';
        _dark[slot]!.text = data.dark[slot] ?? '';
      }
    } catch (_) {
      if (mounted) _showError('主题配色读取失败');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// The same visual colour picker as the merged theme editor:
  /// preset swatches + HSV sliders, confirmed back into the
  /// field as '#RRGGBB'. The row's hex box stays for typing.
  Future<void> _pickColor(
    String label,
    TextEditingController controller,
  ) async {
    final Color initial =
        _hexColor(controller.text) ?? const Color(0xFF808080);
    final Color? picked = await showColorPickerDialog(
      context,
      title: label,
      initialColor: initial,
    );
    if (picked != null) {
      controller.text = colorPickerHex(picked, upperCase: true);
    }
  }

  Map<String, String>? _collect(Map<String, TextEditingController> fields) {
    final Map<String, String> out = <String, String>{};
    for (final String slot in globalThemeCoreSlots) {
      final String? value = _normalizeHex(fields[slot]!.text);
      if (value == null) return null;
      out[slot] = value;
    }
    return out;
  }

  Future<void> _save() async {
    if (_saving || _loading) return;
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('请填写主题名');
      return;
    }
    final Map<String, String>? light = _collect(_light);
    final Map<String, String>? dark = _collect(_dark);
    if (light == null || dark == null) {
      _showError('有颜色不是有效的 #RRGGBB，请检查');
      return;
    }
    setState(() => _saving = true);
    try {
      final GlobalThemeEntry? entry = await saveUserGlobalTheme(
        id: widget.editingId,
        baseId: widget.sourceId,
        name: name,
        light: light,
        dark: dark,
      );
      if (entry == null) {
        _showError('保存失败');
        return;
      }
      // Editing the package that is currently applied: re-apply it
      // so the edits take effect immediately.
      if (widget.editingId != null &&
          globalThemeId.value == widget.editingId) {
        await setGlobalThemeId(widget.editingId!);
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

  Widget _slotField(String label, TextEditingController controller) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color? swatch = _hexColor(controller.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          InkWell(
            onTap: () => unawaited(_pickColor(label, controller)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: swatch ?? scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: swatch == null
                  ? Icon(Icons.error_outline, size: 16, color: scheme.error)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText: '#RRGGBB',
                isDense: true,
                border: glassInputBorder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTile(String title, Map<String, TextEditingController> fields) {
    final Color surface =
        _hexColor(fields['surface']!.text) ?? const Color(0xFF888888);
    final Color primary =
        _hexColor(fields['primary']!.text) ?? const Color(0xFF444444);
    final Color onSurface =
        _hexColor(fields['onSurface']!.text) ?? const Color(0xFF222222);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '主色按钮',
                style: TextStyle(
                  fontSize: 11,
                  color: primary.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSection(String title, Map<String, TextEditingController> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (final String slot in globalThemeCoreSlots)
          _slotField(_slotLabels[slot]!, fields[slot]!),
      ],
    );
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
        title: Text(widget.editingId != null ? '编辑全局主题' : '新建全局主题'),
        actions: <Widget>[
          TextButton(
            onPressed: (_saving || _loading) ? null : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '主题名',
                    hintText: '保存后显示在全局主题库的「我的」里',
                    border: glassInputBorder(context),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _previewTile('浅色预览', _light),
                    const SizedBox(width: 12),
                    _previewTile('深色预览', _dark),
                  ],
                ),
                const SizedBox(height: 20),
                _modeSection('浅色配色', _light),
                const SizedBox(height: 8),
                _modeSection('深色配色', _dark),
                const SizedBox(height: 4),
                Text(
                  '保存为「我的主题」，不会覆盖用作模板的内置主题。表单之外的配色槽位沿用模板，应用后整个应用跟随。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                // Clearance above the resident glass bottom bar.
                const SizedBox(height: 84),
              ],
            ),
    );
  }
}
