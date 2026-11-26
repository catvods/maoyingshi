import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'ui_glass.dart';

/// The shared visual colour picker for the theme editors: a
/// preset swatch grid, HSV sliders with gradient tracks, a live
/// preview with a hex readout, and a manual hex field as the
/// secondary entry. Confirming returns the picked colour;
/// cancelling (or dismissing) returns null and changes nothing.
/// Hand-rolled on material_ui primitives — no picker package.

/// Preset swatches: neutrals, a chromatic spread, and the app's
/// own signature theme colours （午夜影院 / 亮色 / 暖白影院）.
const List<String> colorPickerPresets = <String>[
  '#FFFFFF', '#E8EAED', '#BDC1C6', '#80868B', '#5F6368', '#3C4043',
  '#000000',
  '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
  '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548',
  '#C3D7B5', '#BDCAFF', '#F5F0E6', '#141917',
];

/// Formats [color] as '#RRGGBB' (lowercase unless [upperCase]).
String colorPickerHex(Color color, {bool upperCase = false}) {
  final int v = (color.r * 255).round() << 16 |
      (color.g * 255).round() << 8 |
      (color.b * 255).round();
  final String hex = '#${v.toRadixString(16).padLeft(6, '0')}';
  return upperCase ? hex.toUpperCase() : hex;
}

Color? _parseHex(String raw) {
  String h = raw.trim().replaceAll('#', '');
  if (h.length == 3) {
    h = h.split('').map((String c) => '$c$c').join();
  }
  if (h.length != 6) return null;
  final int? v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// (hue 0..360, saturation 0..1, value 0..1) for [color].
(double, double, double) _hsvOf(Color color) {
  final double r = color.r, g = color.g, b = color.b;
  final double max = math.max(r, math.max(g, b));
  final double min = math.min(r, math.min(g, b));
  final double d = max - min;
  double h = 0;
  if (d > 0) {
    if (max == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (max == g) {
      h = 60 * ((b - r) / d + 2);
    } else {
      h = 60 * ((r - g) / d + 4);
    }
  }
  if (h < 0) h += 360;
  final double s = max == 0 ? 0 : d / max;
  return (h, s, max);
}

Color _colorOfHsv(double h, double s, double v) {
  final double c = v * s;
  final double x = c * (1 - ((h / 60) % 2 - 1).abs());
  final double m = v - c;
  double r = 0, g = 0, b = 0;
  if (h < 60) {
    r = c;
    g = x;
  } else if (h < 120) {
    r = x;
    g = c;
  } else if (h < 180) {
    g = c;
    b = x;
  } else if (h < 240) {
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  return Color.fromARGB(
    255,
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  );
}

/// Opens the picker for [initialColor]; resolves to the confirmed
/// colour, or null when the user cancels.
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required String title,
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) =>
        _ColorPickerDialog(title: title, initialColor: initialColor),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.title, required this.initialColor});

  final String title;
  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _h;
  late double _s;
  late double _v;
  late final TextEditingController _hexController;

  Color get _color => _colorOfHsv(_h, _s, _v);

  @override
  void initState() {
    super.initState();
    final (double, double, double) hsv = _hsvOf(widget.initialColor);
    _h = hsv.$1;
    _s = hsv.$2;
    _v = hsv.$3;
    _hexController = TextEditingController(
      text: colorPickerHex(widget.initialColor, upperCase: true),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  /// Moves the working colour; the hex field follows unless the
  /// change came from typing in it.
  void _setHsv(double h, double s, double v, {bool fromHex = false}) {
    setState(() {
      _h = h;
      _s = s;
      _v = v;
      if (!fromHex) {
        _hexController.text = colorPickerHex(_color, upperCase: true);
      }
    });
  }

  void _onHexChanged(String raw) {
    final Color? parsed = _parseHex(raw);
    if (parsed == null) return;
    final (double, double, double) hsv = _hsvOf(parsed);
    _setHsv(hsv.$1, hsv.$2, hsv.$3, fromHex: true);
  }

  Widget _presetSwatch(Color preset, Color current) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool selected = colorPickerHex(preset) == colorPickerHex(current);
    return InkWell(
      onTap: () {
        final (double, double, double) hsv = _hsvOf(preset);
        _setHsv(hsv.$1, hsv.$2, hsv.$3);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: preset,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 16,
                color: preset.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String readout,
    required double fraction,
    required List<Color> gradient,
    required Color thumbColor,
    required ValueChanged<double> onChanged,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                readout,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          _GradientSlider(
            fraction: fraction,
            gradient: gradient,
            thumbColor: thumbColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = _color;
    final String currentHex = colorPickerHex(color, upperCase: true);
    final Color onColor =
        color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return AlertDialog(
      backgroundColor: glassButtonColor(
        context,
        scheme.surfaceContainerHigh,
      ),
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final String hex in colorPickerPresets)
                    _presetSwatch(_parseHex(hex)!, color),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Text(
                  currentHex,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hexController,
                onChanged: _onHexChanged,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: '十六进制',
                  hintText: '#RRGGBB',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              _sliderRow(
                label: '色相',
                readout: '${_h.round()}°',
                fraction: _h / 360,
                gradient: <Color>[
                  for (final double stop in <double>[
                    0, 60, 120, 180, 240, 300, 360,
                  ])
                    _colorOfHsv(stop, 1, 1),
                ],
                thumbColor: _colorOfHsv(_h, 1, 1),
                onChanged: (double f) => _setHsv(f * 360, _s, _v),
              ),
              _sliderRow(
                label: '饱和度',
                readout: '${(_s * 100).round()}%',
                fraction: _s,
                gradient: <Color>[
                  _colorOfHsv(_h, 0, _v),
                  _colorOfHsv(_h, 1, _v),
                ],
                thumbColor: color,
                onChanged: (double f) => _setHsv(_h, f, _v),
              ),
              _sliderRow(
                label: '明度',
                readout: '${(_v * 100).round()}%',
                fraction: _v,
                gradient: <Color>[
                  Colors.black,
                  _colorOfHsv(_h, _s, 1),
                ],
                thumbColor: color,
                onChanged: (double f) => _setHsv(_h, _s, f),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// A slider whose track is a colour gradient: tap or drag anywhere
/// on the bar to set the fraction. The thumb rides the inset track
/// so it never overflows the ends.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.fraction,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
  });

  final double fraction;
  final List<Color> gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  static const double _inset = 11;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double track = math.max(0, width - _inset * 2);
        double fractionOf(double dx) => track <= 0
            ? 0
            : ((dx - _inset) / track).clamp(0.0, 1.0).toDouble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) =>
              onChanged(fractionOf(d.localPosition.dx)),
          onHorizontalDragStart: (DragStartDetails d) =>
              onChanged(fractionOf(d.localPosition.dx)),
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              onChanged(fractionOf(d.localPosition.dx)),
          child: SizedBox(
            height: 32,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: _inset,
                  right: _inset,
                  top: 9,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                  ),
                ),
                Positioned(
                  left: _inset + track * fraction - _inset,
                  top: 5,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
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
  }
}
