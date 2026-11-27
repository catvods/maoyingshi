import 'dart:async' show unawaited;
import 'dart:convert' show jsonEncode;

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;

import 'color_picker.dart';
import 'global_theme.dart';
import 'home_theme.dart';
import 'merged_theme.dart';
import 'ui_glass.dart';

/// The parametric theme editor, modeled on LeeCat's 新增我的主题
/// dialog: name, description, a palette preset dropdown feeding
/// four hex colours （主色 / 背景色 / 渐变色 / 面板色 — LeeCat's
/// accent / backgroundColors / surfaceColor), a structure dropdown
/// and a title-font dropdown — plus the component section the
/// meta model carries （布局 / 轮播 / 列数 / 圆角 / 导航）, because a
/// theme here is components as much as colours.
///
/// Saving materializes a user source theme: the structure's RFW
/// source with its leecat meta header rewritten to the form's
/// parameters, saved through the existing import path, and a merged
/// record binding that source to the palette (host-side). The
/// bridge and the shell bar read the parameters back out of the
/// meta, so what the form sets is what renders. Built-ins are never
/// overwritten; editing a record saves a fresh source and re-points
/// the record. Pops with the saved record's id.
class ThemeEditorPage extends StatefulWidget {
  const ThemeEditorPage({super.key, this.initial, this.editingId});

  /// Prefill: a record's parameters when editing, a catalog entry's
  /// when creating from a template, null for a blank new theme.
  final MergedThemeParams? initial;

  /// The merged record being edited, when [initial] came from one.
  final String? editingId;

  @override
  State<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

/// Builds the editor prefill for a catalog or user card: its
/// palette and structure, with the structure's component defaults
/// (or the record's own parameters for a merged record).
MergedThemeParams paramsFromMergedEntry(MergedThemeEntry entry) {
  if (entry.record != null) {
    final MergedThemeParams p = entry.record!.params;
    return MergedThemeParams(
      name: p.name,
      description: p.description,
      structureId: p.structureId,
      palette: p.palette,
      titleFont: p.titleFont,
      layout: p.layout,
      hero: p.hero,
      heroHeight: p.heroHeight,
      gridColumns: p.gridColumns,
      cardRadius: p.cardRadius,
      floatingNavigation: p.floatingNavigation,
      glassNavigation: p.glassNavigation,
      navigationOpacity: p.navigationOpacity,
    );
  }
  final String structureId = (entry.structureId == null ||
          entry.structureId!.isEmpty)
      ? homeThemeCatalog[1].id
      : entry.structureId!;
  final MergedComponentDefaults defaults =
      componentDefaultsFor(structureId);
  return MergedThemeParams(
    name: entry.name,
    structureId: structureId,
    palette: entry.palette ??
        globalPalettes[entry.globalId ?? ''] ??
        globalPalettes['']!,
    titleFont: defaults.titleFont,
    layout: defaults.layout,
    hero: defaults.hero,
    cardRadius: defaults.cardRadius,
    floatingNavigation: defaults.floatingNavigation,
    glassNavigation: defaults.glassNavigation,
    navigationOpacity: defaults.navigationOpacity,
  );
}

class _ThemeEditorPageState extends State<ThemeEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _accent;
  late final TextEditingController _background;
  late final TextEditingController _gradient;
  late final TextEditingController _surface;

  late String _structureId;
  late String _titleFont;
  late String _layout;
  late bool _hero;
  late double _heroHeight;
  late int _gridColumns;
  late double _cardRadius;
  late bool _floatingNavigation;
  late bool _glassNavigation;
  late double _navigationOpacity;
  bool _saving = false;

  /// The materialized source the record being edited owns, so a
  /// re-save can retire it once the record points at the new one.
  String? _oldSourceId;

  @override
  void initState() {
    super.initState();
    final MergedThemeParams initial = widget.initial ??
        MergedThemeParams(
          name: '我的主题',
          structureId: 'design-night',
          palette: paletteForHomeEntry(homeThemeEntry('design-night'))!,
        );
    _name = TextEditingController(text: initial.name);
    _description = TextEditingController(text: initial.description);
    _accent = TextEditingController(text: initial.palette.accent);
    _background = TextEditingController(text: initial.palette.background);
    _gradient = TextEditingController(text: initial.palette.gradient);
    _surface = TextEditingController(text: initial.palette.surface);
    _structureId = initial.structureId;
    _titleFont = initial.titleFont;
    _layout = initial.layout;
    _hero = initial.hero;
    _heroHeight = initial.heroHeight;
    _gridColumns = initial.gridColumns;
    _cardRadius = initial.cardRadius;
    _floatingNavigation = initial.floatingNavigation;
    _glassNavigation = initial.glassNavigation;
    _navigationOpacity = initial.navigationOpacity;
    if (widget.editingId != null) {
      for (final MergedThemeRecord record in mergedUserThemes.value) {
        if (record.id == widget.editingId) {
          _oldSourceId = record.structureSourceId;
        }
      }
    }
    for (final TextEditingController c in <TextEditingController>[
      _accent, _background, _gradient, _surface,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name, _description, _accent, _background, _gradient, _surface,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _hex(TextEditingController controller) {
    String h = controller.text.trim().replaceAll('#', '');
    if (h.length != 6) return null;
    if (int.tryParse(h, radix: 16) == null) return null;
    return '#${h.toLowerCase()}';
  }

  Color _swatch(TextEditingController controller) =>
      mergedHexColor(controller.text) ?? Colors.transparent;

  List<(String, MergedPalette)> get _palettePresets =>
      <(String, MergedPalette)>[
        for (final GlobalThemeEntry entry in globalThemeCatalog)
          if (globalPalettes[entry.id] != null)
            ('${entry.name}（配色）', globalPalettes[entry.id]!),
        for (final HomeThemeEntry entry in homeThemeCatalog)
          if (entry.id.isNotEmpty && paletteForHomeEntry(entry) != null)
            (entry.name, paletteForHomeEntry(entry)!),
      ];

  List<(String, String)> get _structureOptions => <(String, String)>[
        for (final HomeThemeEntry entry in homeThemeCatalog)
          if (entry.id.isNotEmpty) (entry.id, entry.name),
        for (final HomeThemeEntry entry in userThemes.value)
          (entry.id, '${entry.name}（我的源码）'),
      ];

  String _labelFor(List<(String, String)> options, String value) {
    for (final option in options) {
      if (option.$1 == value) return option.$2;
    }
    return value;
  }

  Future<void> _pick(
    String title,
    List<(String, String)> options,
    String current,
    ValueChanged<String> onPick,
  ) async {
    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final option in options)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(option.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(option.$2)),
                          if (option.$1 == current)
                            Icon(Icons.check,
                                size: 18,
                                color:
                                    Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) onPick(picked);
  }

  MergedThemeParams? _collect() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _toast('请填写主题名称');
      return null;
    }
    final String? accent = _hex(_accent);
    final String? background = _hex(_background);
    final String? gradient = _hex(_gradient);
    final String? surface = _hex(_surface);
    if (accent == null || background == null || gradient == null || surface == null) {
      _toast('颜色要用 6 位十六进制，如 #c3d7b5');
      return null;
    }
    return MergedThemeParams(
      name: name,
      description: _description.text.trim(),
      structureId: _structureId,
      palette: MergedPalette(
        accent: accent,
        background: background,
        gradient: gradient,
        surface: surface,
      ),
      titleFont: _titleFont,
      layout: _layout,
      hero: _hero,
      heroHeight: _heroHeight,
      gridColumns: _gridColumns,
      cardRadius: _cardRadius,
      floatingNavigation: _floatingNavigation,
      glassNavigation: _glassNavigation,
      navigationOpacity: _navigationOpacity,
    );
  }

  /// The leecat meta header carrying every form parameter — the
  /// same shape LeeCat's own themes carry, plus the bridge's data
  /// parameters (heroHeight / gridColumns) and the parametric
  /// marker the bridge keys its injection on.
  String _metaJson(MergedThemeParams params) {
    return jsonEncode(<String, Object?>{
      'id': 'user-parametric',
      'name': params.name,
      'description': params.description,
      'accent': params.palette.accent,
      'backgroundColors': <String>[
        params.palette.background,
        params.palette.gradient,
      ],
      'cardRadius': params.cardRadius,
      'layout': params.layout,
      'hero': params.hero,
      'heroHeight': params.heroHeight,
      'gridColumns': params.gridColumns,
      'floatingNavigation': params.floatingNavigation,
      'glassNavigation': params.glassNavigation,
      'titleFont': params.titleFont,
      'surfaceColor': params.palette.surface,
      'navigationOpacity': params.navigationOpacity,
      'parametric': true,
      'structure': params.structureId,
    });
  }

  String _withMeta(String source, MergedThemeParams params) {
    final String header = '// leecat-theme: ${_metaJson(params)}';
    final int nl = source.indexOf('\n');
    final String first = nl >= 0 ? source.substring(0, nl) : source;
    if (first.contains('leecat-theme:')) {
      return header + (nl >= 0 ? source.substring(nl) : '');
    }
    return '$header\n$source';
  }

  /// Bakes the form's card radius into the materialized source.
  /// The templates draw their cards, tabs and chips with one
  /// dominant borderRadius literal — in the Lee templates it is
  /// the meta cardRadius itself, repeated verbatim — so rewriting
  /// the dominant literal to the chosen value is what makes the
  /// radius parameter real at render time (the meta copy alone
  /// only ever reached this page's preview). Literals that differ
  /// from the dominant one (a PeekPro structure's hero radius,
  /// say) keep their authored values. A source with no such
  /// literal is left alone.
  String _bakeCardRadius(String source, double radius) {
    final RegExp pattern =
        RegExp(r'borderRadius:\s*\[\s*\{\s*x:\s*([0-9]+(?:\.[0-9]+)?)\s*\}');
    final Map<String, int> counts = <String, int>{};
    for (final RegExpMatch match in pattern.allMatches(source)) {
      final String value = match.group(1)!;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) return source;
    String dominant = counts.keys.first;
    for (final String key in counts.keys) {
      if (counts[key]! > counts[dominant]!) dominant = key;
    }
    final String baked = radius.toStringAsFixed(1);
    if (dominant == baked) return source;
    return source.replaceAllMapped(pattern, (Match match) {
      if (match.group(1) != dominant) return match.group(0)!;
      return match.group(0)!.replaceFirst(dominant, baked);
    });
  }

  Future<void> _save() async {
    final MergedThemeParams? params = _collect();
    if (params == null || _saving) return;
    setState(() => _saving = true);
    try {
      final String source = await loadThemeText(params.structureId);
      final String text =
          _bakeCardRadius(_withMeta(source, params), params.cardRadius);
      try {
        parseLibraryFile(text);
      } catch (_) {
        _toast('主题源码不合法，无法保存');
        return;
      }
      final HomeThemeEntry? imported = await importUserThemeText(text);
      if (imported == null) {
        _toast('保存失败');
        return;
      }
      final String mergedId = await saveMergedTheme(
        id: widget.editingId,
        params: params,
        structureSourceId: imported.id,
      );
      // Retire the previous materialized source once the record
      // points at the new one — unless the home still uses it as a
      // standalone selection (then it stays a usable source theme).
      final String? oldSource = _oldSourceId;
      if (oldSource != null && oldSource != imported.id) {
        final bool stillUsedStandalone =
            homeThemeId.value == oldSource && mergedThemeId.value != mergedId;
        if (!stillUsedStandalone) {
          try {
            await deleteUserTheme(oldSource);
          } catch (_) {
            // A leftover file is harmless; the record is saved.
          }
        }
      }
      if (mounted) Navigator.of(context).pop(mergedId);
    } on PlatformException catch (e) {
      _toast(e.message ?? '保存失败');
    } catch (_) {
      _toast('保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: glassInputBorder(
              context,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(value, style: TextStyle(color: scheme.onSurface)),
        ),
      ),
    );
  }

  /// Opens the visual colour picker for one of the four palette
  /// fields; the picked colour lands back in the field's
  /// controller as '#rrggbb', so saving and applying downstream
  /// are untouched. Cancelling leaves the field as it was.
  Future<void> _pickColor(
    String label,
    TextEditingController controller,
  ) async {
    final Color initial =
        mergedHexColor(controller.text) ?? const Color(0xFF808080);
    final Color? picked = await showColorPickerDialog(
      context,
      title: label,
      initialColor: initial,
    );
    if (picked != null) controller.text = mergedColorHex(picked);
  }

  /// A palette field: swatch + hex readout, not a keyboard field.
  /// Tapping anywhere on the row opens the colour picker (which
  /// still offers a manual hex box inside, for those who want it).
  Widget _hexField(String label, TextEditingController controller) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => unawaited(_pickColor(label, controller)),
        borderRadius: BorderRadius.circular(28),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: glassInputBorder(
              context,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _swatch(controller),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
            ),
            suffixIcon: const Icon(Icons.palette),
          ),
          child: Text(
            controller.text.isEmpty ? '点按选择颜色' : controller.text,
            style: TextStyle(
              color: scheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  /// A value row in the settings family's idiom: tap opens the
  /// choice dialog (this codebase picks values from dialogs, not
  /// sliders).
  Widget _valueRow({
    required String label,
    required String valueLabel,
    required List<(String, String)> options,
    required String current,
    required ValueChanged<String> onPick,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => unawaited(_pick(label, options, current, onPick)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                valueLabel,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// A toggle row built from proven widgets (the codebase has no
  /// Switch usage): label left, a pill right.
  Widget _toggleRow({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: const TextStyle(fontSize: 14)),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                color: value ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value ? scheme.onPrimary : scheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final MergedPalette palette = MergedPalette(
      accent: _hex(_accent) ?? '#000000',
      background: _hex(_background) ?? '#000000',
      gradient: _hex(_gradient) ?? '#000000',
      surface: _hex(_surface) ?? '#000000',
    );
    final Color bg = mergedHexColor(palette.background) ?? Colors.black;
    final Color grad = mergedHexColor(palette.gradient) ?? Colors.black;
    final Color panel = mergedHexColor(palette.surface) ?? Colors.grey;
    final Color accent = mergedHexColor(palette.accent) ?? Colors.white;
    final bool dark = bg.computeLuminance() < 0.35;
    final Color onBg = dark ? Colors.white : const Color(0xFF1B1B1F);
    final String? fontFamily = switch (_titleFont) {
      'serif' => 'NotoSerifSC',
      'wenkai' => 'LXGWWenKaiLite',
      'mono' => 'monospace',
      _ => null,
    };
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[bg, grad],
        ),
        borderRadius: BorderRadius.circular(_cardRadius.clamp(4, 30)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _name.text.trim().isEmpty ? '我的主题' : _name.text.trim(),
            style: TextStyle(
              color: onBg,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(_cardRadius.clamp(4, 30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '面板 · 主色预览',
                    style: TextStyle(
                      color: panel.computeLuminance() < 0.35
                          ? Colors.white
                          : const Color(0xFF1B1B1F),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool editing = widget.editingId != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const GlassSurface(child: SizedBox.expand()),
        title: Text(editing ? '编辑我的主题' : '新增我的主题'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : () => unawaited(_save()),
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: <Widget>[
          TextField(
            controller: _name,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: '主题名称',
              border: glassInputBorder(
                context,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: _description,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: '描述（可选）',
              border: glassInputBorder(
                context,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          _dropdownField(
            label: '配色',
            value: '选择后填入下面四色',
            onTap: () => unawaited(_pick(
              '配色',
              <(String, String)>[
                for (int i = 0; i < _palettePresets.length; i++)
                  ('$i', _palettePresets[i].$1),
              ],
              '',
              (String value) {
                final MergedPalette palette =
                    _palettePresets[int.parse(value)].$2;
                setState(() {
                  _accent.text = palette.accent;
                  _background.text = palette.background;
                  _gradient.text = palette.gradient;
                  _surface.text = palette.surface;
                });
              },
            )),
          ),
          _hexField('主色', _accent),
          _hexField('背景色', _background),
          _hexField('渐变色', _gradient),
          _hexField('面板色', _surface),
          _dropdownField(
            label: '主题结构',
            value: _labelFor(_structureOptions, _structureId),
            onTap: () => unawaited(_pick(
              '主题结构',
              _structureOptions,
              _structureId,
              (String value) => setState(() => _structureId = value),
            )),
          ),
          _dropdownField(
            label: '标题字体',
            value: _labelFor(
              const <(String, String)>[
                ('sans', '默认'),
                ('serif', '衬线'),
                ('wenkai', '文楷'),
                ('mono', '等宽'),
              ],
              _titleFont,
            ),
            onTap: () => unawaited(_pick(
              '标题字体',
              const <(String, String)>[
                ('sans', '默认'),
                ('serif', '衬线'),
                ('wenkai', '文楷'),
                ('mono', '等宽'),
              ],
              _titleFont,
              (String value) => setState(() => _titleFont = value),
            )),
          ),
          const SizedBox(height: 6),
          Text(
            '组件',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _dropdownField(
            label: '布局',
            value: _labelFor(
              const <(String, String)>[
                ('posters', '海报墙'),
                ('landscape', '宽幅'),
                ('compact', '紧凑列表'),
              ],
              _layout,
            ),
            onTap: () => unawaited(_pick(
              '布局',
              const <(String, String)>[
                ('posters', '海报墙'),
                ('landscape', '宽幅'),
                ('compact', '紧凑列表'),
              ],
              _layout,
              (String value) => setState(() => _layout = value),
            )),
          ),
          _toggleRow(
            label: '轮播主视觉',
            value: _hero,
            onChanged: (bool value) => setState(() => _hero = value),
          ),
          if (_hero)
            _valueRow(
              label: '主视觉高度',
              valueLabel: '${_heroHeight.round()}',
              options: <(String, String)>[
                for (final int h in <int>[160, 180, 200, 220, 240, 260, 280, 300, 320])
                  ('$h', '$h'),
              ],
              current: '${_heroHeight.round()}',
              onPick: (String value) =>
                  setState(() => _heroHeight = double.parse(value)),
            ),
          _valueRow(
            label: '网格列数',
            valueLabel: '$_gridColumns 列',
            options: const <(String, String)>[
              ('2', '2 列'),
              ('3', '3 列'),
              ('4', '4 列'),
            ],
            current: '$_gridColumns',
            onPick: (String value) =>
                setState(() => _gridColumns = int.parse(value)),
          ),
          _valueRow(
            label: '卡片圆角',
            valueLabel: '${_cardRadius.round()}',
            options: <(String, String)>[
              for (final int r in <int>[4, 8, 12, 16, 18, 20, 22, 26, 30])
                ('$r', '$r'),
            ],
            current: '${_cardRadius.round()}',
            onPick: (String value) =>
                setState(() => _cardRadius = double.parse(value)),
          ),
          _toggleRow(
            label: '悬浮导航',
            subtitle: '底栏悬浮胶囊；关则贴边通栏',
            value: _floatingNavigation,
            onChanged: (bool value) =>
                setState(() => _floatingNavigation = value),
          ),
          _toggleRow(
            label: '玻璃导航',
            subtitle: '底栏半透明玻璃；关则实色',
            value: _glassNavigation,
            onChanged: (bool value) =>
                setState(() => _glassNavigation = value),
          ),
          _valueRow(
            label: '底栏透明度',
            valueLabel: _navigationOpacity.toStringAsFixed(2),
            options: const <(String, String)>[
              ('0.2', '0.20'),
              ('0.28', '0.28'),
              ('0.35', '0.35'),
              ('0.5', '0.50'),
              ('0.7', '0.70'),
              ('0.85', '0.85'),
              ('1.0', '1.00（实色）'),
            ],
            current: '$_navigationOpacity',
            onPick: (String value) =>
                setState(() => _navigationOpacity = double.parse(value)),
          ),
          const SizedBox(height: 10),
          _preview(),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              side: glassFrameSide(context),
              backgroundColor:
                  glassButtonColor(context, scheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _saving ? null : () => unawaited(_save()),
            child: Text(_saving ? '保存中…' : '保存'),
          ),
          const SizedBox(height: 10),
          Text(
            '保存后回到主题库点选即应用。结构决定首页的组件排布，配色决定全 App 的颜色；组件参数写进主题的元数据，首页桥与底栏会照着渲染。内置主题永远不会被覆盖。',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
