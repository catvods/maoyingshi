import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import 'home_theme.dart';
import 'peek_home_library.dart';
import 'theme_design.dart';
import 'pigeon/b11_home_messages.g.dart';
import 'pigeon/b12_home_a_messages.g.dart';
import 'pigeon/b8_category_messages.g.dart';

/// The RFW themed home: renders one of the ported PeekPro home
/// themes (assets/peek_home/theme_<id>.rfwtxt) in place of the
/// built-in B11 home body, driven by the same host data.
///
/// Data bridge: the B11 shell snapshot supplies the classes (tabs)
/// and the site name, B12 supplies the recommend carousel, and
/// getTabVideos supplies the current tab's items — the same calls
/// the built-in home makes. Everything is flattened into the
/// `data.home.*` shape the themes read.
///
/// Event bridge: the themes' events map onto the existing host
/// actions (openItem -> B8 detail chain, selectType -> tab switch,
/// openSearch/openHistory/openSiteDialog/... on B11HostApi). The
/// inline filter panel is fed by getTabFilters (the tab Class's
/// filters with the effective selection) and selectFilter picks go
/// through setTabFilter into the same host override map the native
/// type-filter dialog writes; showFilterPicker/showCategoryPicker
/// still open that native dialog, and the grid reloads when it
/// closes.
class ThemedHomeView extends StatefulWidget {
  const ThemedHomeView({
    super.key,
    required this.screen,
    required this.epoch,
    required this.onReloadRequest,
  });

  final B11HomeScreen screen;

  /// The B11 home-load epoch; a bump reloads banner + tab data.
  final int epoch;

  /// Asks the owning B11 page to reload its shell snapshot (used
  /// after the site dialog reports a site change).
  final VoidCallback onReloadRequest;

  @override
  State<ThemedHomeView> createState() => _ThemedHomeViewState();
}

class _ThemedHomeViewState extends State<ThemedHomeView> {
  static const LibraryName _coreName = LibraryName(<String>['core', 'widgets']);
  static const LibraryName _peekName = LibraryName(<String>['peek', 'home']);
  static const LibraryName _themeName = LibraryName(<String>['peek', 'theme']);

  static const List<String> _styleCycle = <String>[
    'grid',
    'largeGrid',
    'banner',
    'list',
    'list2',
    'card',
    'textList',
  ];

  final B11HostApi _b11Api = B11HostApi();
  final B12HostApi _b12Api = B12HostApi();
  final B8HostApi _b8Api = B8HostApi();

  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();

  bool _themeReady = false;
  bool _themeFailed = false;
  List<B11FilterGroup> _filterGroups = <B11FilterGroup>[];
  bool _showFilters = true;
  List<B12BannerItem> _recommend = <B12BannerItem>[];
  List<B11TabVideoItem> _items = <B11TabVideoItem>[];
  String _siteKey = '';
  int _tabIndex = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _nextPage = 1;
  String _displayStyle = 'grid';

  /// The active theme's design-layer parameters, parsed from its
  /// leecat meta header in _loadThemeLibrary (theme_design.dart).
  /// Null for themes without a meta header (the PeekPro themes,
  /// whose sources are self-contained). The rendering consumption
  /// lives in build() (page background, title font) and in the
  /// peek library through PeekHomeHooks.designParams (the design
  /// style's poster treatment).
  ThemeDesignParams? _designParams;

  /// Component parameters of a parametric-editor theme, fed into
  /// the data below from its meta. Built-in and plain imported
  /// themes carry no parametric marker, so the data values stay
  /// at the bridge's long-standing defaults for them.
  bool _paramHero = true;
  double? _paramHeroHeight;
  int? _paramGridColumns;
  String _errorMessage = '';
  int _immersiveIndex = 0;
  int _loadSerial = 0;

  /// Immersive palette extracted from the current recommend
  /// poster's pixels (see _syncImmersivePalette). Until extraction
  /// lands — and whenever it fails — these hold the fixed dark
  /// palette the bridge originally shipped.
  static const List<int> _fallbackImmersivePalette = <int>[
    0xFF1A237E,
    0xFF4A148C,
    0xFF0B0B10,
  ];
  int _immersivePrimary = _fallbackImmersivePalette[0];
  int _immersiveSecondary = _fallbackImmersivePalette[1];
  int _immersiveBackground = _fallbackImmersivePalette[2];
  final Map<String, List<int>> _paletteCache = <String, List<int>>{};
  final Set<String> _palettePending = <String>{};

  @override
  void initState() {
    super.initState();
    _runtime.update(_coreName, createCoreWidgets());
    _runtime.update(_peekName, createPeekHomeWidgets());
    PeekHomeHooks.onGridEndReached = _loadMore;
    PeekHomeHooks.onCarouselPage = (int index) {
      if (index != _immersiveIndex && index < _recommend.length) {
        _immersiveIndex = index;
        _pushData();
        _syncImmersivePalette();
      }
    };
    unawaited(_loadThemeLibrary());
    unawaited(_loadAll());
  }

  @override
  void didUpdateWidget(ThemedHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.epoch != widget.epoch ||
        oldWidget.screen.title != widget.screen.title) {
      _tabIndex = 0;
      unawaited(_loadAll());
    }
  }

  @override
  void dispose() {
    if (PeekHomeHooks.onGridEndReached == _loadMore) {
      PeekHomeHooks.onGridEndReached = null;
    }
    PeekHomeHooks.onCarouselPage = null;
    PeekHomeHooks.titleFontFamily = null;
    PeekHomeHooks.designParams = null;
    super.dispose();
  }

  Future<void> _loadThemeLibrary() async {
    try {
      final String text = await loadThemeText(homeThemeId.value);
      _readDesignParams(text);
      _runtime.update(_themeName, parseLibraryFile(text));
      if (mounted) setState(() => _themeReady = true);
    } catch (_) {
      if (mounted) setState(() => _themeFailed = true);
    }
  }

  /// Reads the theme's design-layer parameters out of its leecat
  /// meta header. Every meta-carrying theme contributes its
  /// design style, title font and hero switch (the design layer's
  /// own consumption); the data-field injections stay exclusive
  /// to parametric editor themes, whose materialized sources are
  /// generic templates that branch on the data (layout ->
  /// displayStyle, heroHeight and gridColumns verbatim) — the
  /// built-in templates embody their layout in their source.
  void _readDesignParams(String text) {
    final ThemeDesignParams? params = ThemeDesignParams.fromSource(text);
    _designParams = params;
    PeekHomeHooks.designParams = params;
    PeekHomeHooks.titleFontFamily = params?.titleFontFamily;
    if (params == null) return;
    if (params.hero != null) _paramHero = params.hero!;
    if (!params.parametric) return;
    final String? layout = params.layout;
    if (layout != null) {
      _displayStyle = switch (layout) {
        'landscape' => 'banner',
        'compact' => 'list',
        _ => 'grid',
      };
    }
    _paramHeroHeight = params.heroHeight;
    if (params.gridColumns != null) {
      _paramGridColumns = params.gridColumns!.clamp(2, 4);
    }
  }

  Future<void> _loadAll() async {
    final int serial = ++_loadSerial;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final B12BannerScreen banner = await _b12Api.getBanner();
      if (!mounted || serial != _loadSerial) return;
      _recommend = banner.items;
      _immersiveIndex = 0;
    } catch (_) {
      if (!mounted || serial != _loadSerial) return;
      _recommend = <B12BannerItem>[];
    }
    _syncImmersivePalette();
    await _loadPage(1, serial);
  }

  Future<void> _loadPage(int page, [int? serial]) async {
    final B11HomeScreen screen = widget.screen;
    if (screen.tabs.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _items = <B11TabVideoItem>[];
        });
        _pushData();
      }
      return;
    }
    final int mySerial = serial ?? _loadSerial;
    final B11HomeTab tab = screen.tabs[_tabIndex.clamp(0, screen.tabs.length - 1)];
    if (page == 1) {
      try {
        final B11TabFilters filters =
            await _b11Api.getTabFilters(tab.typeId, tab.typeJson);
        if (mounted && mySerial == _loadSerial) {
          _filterGroups = filters.groups;
        }
      } catch (_) {
        if (mounted && mySerial == _loadSerial) {
          _filterGroups = <B11FilterGroup>[];
        }
      }
    }
    B11TabVideos? videos;
    try {
      videos = await _b11Api.getTabVideos(tab.typeId, tab.typeJson, page);
    } catch (_) {
      videos = null;
    }
    if (!mounted || mySerial != _loadSerial) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (videos != null && videos.errorMessage.isEmpty) {
        _siteKey = videos.siteKey;
        _nextPage = videos.nextPage;
        _hasMore = videos.hasMore;
        _errorMessage = '';
        if (page == 1) {
          _items = videos.items;
        } else {
          _items = <B11TabVideoItem>[..._items, ...videos.items];
        }
      } else if (page == 1) {
        _errorMessage = videos?.errorMessage ?? '';
        _items = <B11TabVideoItem>[];
        _hasMore = false;
      }
    });
    _pushData();
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    unawaited(_loadPage(_nextPage));
  }

  /// Points the immersive palette at the current recommend item:
  /// a cached extraction applies at once; a fresh one is kicked
  /// off and applied when it lands if that poster is still the
  /// immersive one. With no poster — or when extraction fails —
  /// the fixed fallback palette stays, exactly what the bridge
  /// fed before real extraction existed.
  void _syncImmersivePalette() {
    if (_recommend.isEmpty) {
      _applyImmersivePalette(_fallbackImmersivePalette);
      return;
    }
    final B12BannerItem item =
        _recommend[_immersiveIndex.clamp(0, _recommend.length - 1)];
    final String url = item.picUrl;
    if (url.isEmpty) {
      _applyImmersivePalette(_fallbackImmersivePalette);
      return;
    }
    final List<int>? cached = _paletteCache[url];
    if (cached != null) {
      _applyImmersivePalette(cached);
      return;
    }
    if (!_palettePending.add(url)) return;
    unawaited(() async {
      final List<int>? palette = await _extractPalette(url);
      _palettePending.remove(url);
      if (palette != null) _paletteCache[url] = palette;
      if (!mounted || _recommend.isEmpty) return;
      final B12BannerItem current =
          _recommend[_immersiveIndex.clamp(0, _recommend.length - 1)];
      if (current.picUrl != url) return;
      _applyImmersivePalette(palette ?? _fallbackImmersivePalette);
    }());
  }

  void _applyImmersivePalette(List<int> palette) {
    if (_immersivePrimary == palette[0] &&
        _immersiveSecondary == palette[1] &&
        _immersiveBackground == palette[2]) {
      return;
    }
    _immersivePrimary = palette[0];
    _immersiveSecondary = palette[1];
    _immersiveBackground = palette[2];
    _pushData();
  }

  /// Extracts [primary, secondary, background] ARGB values from a
  /// poster: decode it, downscale to 24x24, and read the pixels —
  /// primary is the dominant colour bucket, secondary the most
  /// saturated populous bucket with a distinct hue, background
  /// the dominant colour darkened toward black. Pure dart:ui
  /// work; no palette package. Null on any failure.
  Future<List<int>?> _extractPalette(String url) async {
    final ui.Image? image = await _loadNetworkImage(url)
        .timeout(const Duration(seconds: 15), onTimeout: () => null);
    if (image == null) return null;
    try {
      const int size = 24;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.low,
      );
      final ui.Image small =
          await recorder.endRecording().toImage(size, size);
      final ByteData? bytes =
          await small.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) return null;
      return _paletteFromPixels(bytes, size * size);
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _loadNetworkImage(String url) {
    final Completer<ui.Image?> completer = Completer<ui.Image?>();
    final ImageStream stream =
        NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  List<int>? _paletteFromPixels(ByteData bytes, int pixelCount) {
    final Uint8List data = bytes.buffer.asUint8List();
    // 4x4x4 RGB buckets, each [count, rSum, gSum, bSum].
    final List<List<int>> buckets =
        List<List<int>>.generate(64, (_) => <int>[0, 0, 0, 0]);
    int opaque = 0;
    for (int i = 0; i < pixelCount; i++) {
      final int offset = i * 4;
      if (data[offset + 3] < 125) continue;
      final int r = data[offset];
      final int g = data[offset + 1];
      final int b = data[offset + 2];
      final List<int> bucket =
          buckets[((r >> 6) << 4) | ((g >> 6) << 2) | (b >> 6)];
      bucket[0]++;
      bucket[1] += r;
      bucket[2] += g;
      bucket[3] += b;
      opaque++;
    }
    if (opaque == 0) return null;
    List<int> bucketColor(int index) {
      final List<int> bucket = buckets[index];
      return <int>[
        (bucket[1] / bucket[0]).round(),
        (bucket[2] / bucket[0]).round(),
        (bucket[3] / bucket[0]).round(),
      ];
    }

    int dominant = 0;
    for (int i = 1; i < buckets.length; i++) {
      if (buckets[i][0] > buckets[dominant][0]) dominant = i;
    }
    final List<int> primary = bucketColor(dominant);
    final double primaryHue = _hue(primary[0], primary[1], primary[2]);
    int secondaryIndex = -1;
    double bestScore = -1;
    for (int i = 0; i < buckets.length; i++) {
      if (i == dominant || buckets[i][0] == 0) continue;
      final List<int> color = bucketColor(i);
      double hueDiff =
          (_hue(color[0], color[1], color[2]) - primaryHue).abs();
      if (hueDiff > 180) hueDiff = 360 - hueDiff;
      if (hueDiff < 24) continue;
      final double score =
          buckets[i][0] * (0.3 + _saturation(color[0], color[1], color[2]));
      if (score > bestScore) {
        bestScore = score;
        secondaryIndex = i;
      }
    }
    final List<int> secondary =
        secondaryIndex >= 0 ? bucketColor(secondaryIndex) : primary;
    final List<int> background = <int>[
      (primary[0] * 0.30).round(),
      (primary[1] * 0.30).round(),
      (primary[2] * 0.30).round(),
    ];
    int argb(List<int> color) =>
        0xFF000000 | (color[0] << 16) | (color[1] << 8) | color[2];
    return <int>[argb(primary), argb(secondary), argb(background)];
  }

  double _hue(int r, int g, int b) {
    final double rf = r / 255;
    final double gf = g / 255;
    final double bf = b / 255;
    final double max = math.max(rf, math.max(gf, bf));
    final double min = math.min(rf, math.min(gf, bf));
    final double delta = max - min;
    if (delta == 0) return 0;
    if (max == rf) return 60 * (((gf - bf) / delta) % 6);
    if (max == gf) return 60 * (((bf - rf) / delta) + 2);
    return 60 * (((rf - gf) / delta) + 4);
  }

  double _saturation(int r, int g, int b) {
    final int max = math.max(r, math.max(g, b));
    final int min = math.min(r, math.min(g, b));
    if (max == 0) return 0;
    return (max - min) / max;
  }

  /// The themes pass the icon value straight into Icon(icon: ...)
  /// with fontFamily: "MaterialIcons" as a sibling argument, so the
  /// data value must be the bare code point, not an IconData map.
  int _iconData(IconData icon) => icon.codePoint;

  void _pushData() {
    if (!mounted) return;
    final B11HomeScreen screen = widget.screen;
    final bool landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final B12BannerItem? immersiveItem = _recommend.isEmpty
        ? null
        : _recommend[_immersiveIndex.clamp(0, _recommend.length - 1)];
    _data.update('home', <String, Object?>{
      'home': <String, Object?>{
        'recommend': <Map<String, Object?>>[
          for (int i = 0; i < _recommend.length; i++)
            <String, Object?>{
              'index': i,
              'name': _recommend[i].name,
              'pic': _recommend[i].picUrl,
              'remarks': _recommend[i].remarks,
              'titleLogo': '',
            },
        ],
      },
      'items': <Map<String, Object?>>[
        for (int i = 0; i < _items.length; i++)
          <String, Object?>{
            'index': i,
            'name': _items[i].name,
            'pic': _items[i].picUrl,
            'remarks': _items[i].remarks,
            'year': _items[i].year,
            'rankLabel': '${i + 1}',
            'indexLabel': (i + 1).toString().padLeft(2, '0'),
            'selected': false,
          },
      ],
      'classes': <Map<String, Object?>>[
        for (int i = 0; i < screen.tabs.length; i++)
          <String, Object?>{
            'typeId': screen.tabs[i].typeId,
            'typeName': screen.tabs[i].typeName,
            'selected': i == _tabIndex,
          },
      ],
      'filters': <Map<String, Object?>>[
        for (final B11FilterGroup group in _filterGroups)
          <String, Object?>{
            'key': group.key,
            'name': group.name,
            'canExpand': false,
            'options': <Map<String, Object?>>[
              for (final B11FilterOption option in group.options)
                <String, Object?>{
                  'name': option.name,
                  'value': option.value,
                  'filterKey': group.key,
                  'selected': option.selected,
                },
            ],
          },
      ],
      'hasFilters': _filterGroups.isNotEmpty,
      'showFilters': _showFilters,
      'filterPanelHeight': _filterGroups.length * 39.0 + 10.0,
      'immersiveFilterPanelHeight': _filterGroups.length * 39.0 + 10.0,
      'source': <String, Object?>{'name': screen.title},
      'totalLabel': '${_items.length}',
      'hasRecommend': _paramHero && _recommend.isNotEmpty,
      'hasManyClasses': screen.tabs.length > 5,
      'displayStyle': _displayStyle,
      'gridColumns': _paramGridColumns ?? 3,
      'largeGridColumns': 2,
      'bannerColumns': 2,
      'glassGridColumns': _paramGridColumns ?? 3,
      'heroHeight': _paramHeroHeight ?? 220.0,
      'wideListRatio': 2.4,
      'textListRatio': 5.5,
      // The pinned header must reserve the filter panel's height
      // too: with only the classes row (54) the panel paints over
      // the first poster row instead of pushing the grid down.
      'stickyHeaderHeight':
          54.0 + (_showFilters ? _filterGroups.length * 39.0 + 10.0 : 0.0),
      'immersiveStickyHeaderHeight':
          54.0 + (_showFilters ? _filterGroups.length * 39.0 + 10.0 : 0.0),
      'immersive': <String, Object?>{
        'active': immersiveItem != null,
        'imageUrl': immersiveItem?.picUrl ?? '',
        'primaryColor': _immersivePrimary,
        'secondaryColor': _immersiveSecondary,
        'backgroundColor': _immersiveBackground,
      },
      'icons': <String, Object?>{
        'search': _iconData(Icons.search),
        'history': _iconData(Icons.history),
        'favorite': _iconData(Icons.favorite_border),
        'filter': _iconData(Icons.tune),
        'layout': _iconData(Icons.grid_view),
        'refresh': _iconData(Icons.refresh),
        'expand': _iconData(Icons.expand_more),
        'api': _iconData(Icons.dns),
        'open': _iconData(Icons.open_in_new),
        'push': _iconData(Icons.send),
        'source': _iconData(Icons.swap_horiz),
      },
      'loading': _loading,
      'errorMessage': _errorMessage,
      'isLandscape': landscape,
    });
  }

  int _eventIndex(Map<String, Object?> arguments) {
    final Object? value = arguments['index'];
    return value is num ? value.toInt() : -1;
  }

  Future<void> _openItem(int index) async {
    if (index < 0 || index >= _items.length) return;
    final B11TabVideoItem item = _items[index];
    final B11HomeScreen screen = widget.screen;
    if (screen.tabs.isEmpty) return;
    final B11HomeTab tab = screen.tabs[_tabIndex.clamp(0, screen.tabs.length - 1)];
    if (item.isFolder) {
      try {
        await _b11Api.openTabCategory(item.id, tab.typeJson);
      } catch (_) {
        // The host navigation failed; the grid stays as it was.
      }
      return;
    }
    try {
      await _b8Api.openCategoryItem(
        _siteKey,
        item.id,
        item.name,
        item.rawPic,
        item.isFolder,
        item.isAction,
        item.action,
        -1,
        '',
        -1,
      );
    } catch (_) {
      // The host navigation failed; the grid stays as it was.
    }
  }

  /// One inline filter pick: record it host-side (the same
  /// override map the native dialog writes), then reload the tab's
  /// first page; _loadPage refetches the groups so the panel shows
  /// the new selection.
  Future<void> _applyFilter(String key, String value) async {
    final B11HomeScreen screen = widget.screen;
    if (screen.tabs.isEmpty) return;
    final B11HomeTab tab =
        screen.tabs[_tabIndex.clamp(0, screen.tabs.length - 1)];
    try {
      await _b11Api.setTabFilter(tab.typeId, key, value);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _loadSerial++;
    setState(() {
      _loading = true;
      _items = <B11TabVideoItem>[];
    });
    _pushData();
    await _loadPage(1);
  }

  Future<void> _openFilterDialog() async {
    try {
      final B11TypeFilterState state =
          await _b11Api.openTypeFilterDialog(_tabIndex);
      if (!mounted) return;
      if (state.selectedTabIndex >= 0 &&
          state.selectedTabIndex < widget.screen.tabs.length) {
        _tabIndex = state.selectedTabIndex;
      }
      _loadSerial++;
      setState(() => _loading = true);
      await _loadPage(1);
    } catch (_) {
      // The dialog failed to open; the themed home stays as it was.
    }
  }

  void _onEvent(String name, Map<String, Object?> arguments) {
    switch (name) {
      case 'openItem':
        unawaited(_openItem(_eventIndex(arguments)));
      case 'longPressItem':
        final int index = _eventIndex(arguments);
        if (index >= 0 && index < _items.length) {
          final B11TabVideoItem item = _items[index];
          if (!item.isFolder && !item.isAction) {
            unawaited(() async {
              try {
                await _b8Api.searchCategoryItem(item.name, -1, '', -1);
              } catch (_) {
                // The host navigation failed; the grid stays as it was.
              }
            }());
          }
        }
      case 'openRecommend':
        final int index = _eventIndex(arguments);
        if (index >= 0) {
          unawaited(() async {
            try {
              await _b12Api.openBannerItem(index);
            } catch (_) {
              // The host navigation failed; the home stays as it was.
            }
          }());
        }
      case 'selectType':
        final Object? typeId = arguments['typeId'];
        final int index = widget.screen.tabs
            .indexWhere((B11HomeTab tab) => tab.typeId == typeId);
        if (index >= 0 && index != _tabIndex) {
          _tabIndex = index;
          _loadSerial++;
          setState(() {
            _loading = true;
            _items = <B11TabVideoItem>[];
          });
          _pushData();
          unawaited(_loadPage(1));
        }
      case 'openSearch':
        unawaited(() async {
          try {
            await _b11Api.openSearch();
          } catch (_) {}
        }());
      case 'openHistory':
        unawaited(() async {
          try {
            await _b11Api.openHistory();
          } catch (_) {}
        }());
      case 'openFavorite':
        unawaited(() async {
          try {
            await _b11Api.openMenuItem('keep');
          } catch (_) {}
        }());
      case 'openPush':
        unawaited(() async {
          try {
            await _b11Api.openLinkDialog();
          } catch (_) {}
        }());
      case 'refresh':
        unawaited(_loadAll());
      case 'toggleFilters':
        _showFilters = !_showFilters;
        _pushData();
      case 'showCategoryPicker':
      case 'showFilterPicker':
        unawaited(_openFilterDialog());
      case 'selectFilter':
        final Object? filterKey = arguments['key'];
        final Object? filterValue = arguments['value'];
        if (filterKey is String && filterValue is String) {
          unawaited(_applyFilter(filterKey, filterValue));
        }
      case 'showSourcePicker':
        unawaited(() async {
          try {
            final bool changed = await _b11Api.openSiteDialog();
            if (changed) widget.onReloadRequest();
          } catch (_) {}
        }());
      case 'showApiConfigPicker':
        unawaited(() async {
          try {
            await _b11Api.openBottomBarItem('setting');
          } catch (_) {}
        }());
      case 'showDisplayStylePicker':
        final int next =
            (_styleCycle.indexOf(_displayStyle) + 1) % _styleCycle.length;
        setState(() => _displayStyle = _styleCycle[next]);
        _pushData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_themeFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('主题加载失败'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setHomeThemeId(''),
              child: const Text('恢复默认主题'),
            ),
          ],
        ),
      );
    }
    if (!_themeReady) {
      return const Center(child: CircularProgressIndicator());
    }
    Widget view = RemoteWidget(
      runtime: _runtime,
      data: _data,
      widget: const FullyQualifiedWidgetName(_themeName, 'root'),
      onEvent: _onEvent,
    );
    final ThemeDesignParams? params = _designParams;
    if (params != null) {
      // The design layer's page base: the meta's background pair
      // painted behind the whole themed home. The RFW templates
      // never paint a page background — their surfaces are
      // translucent tints written against this base; without it
      // they floated on the app's light surface and washed out
      // (a dark theme's cream text on light-grey chips).
      final BoxDecoration? background = params.backgroundDecoration;
      if (background != null) {
        view = DecoratedBox(decoration: background, child: view);
      }
      // The title font as the themed subtree's ambient font:
      // template texts specify colour/size/weight but no family,
      // so they inherit this; the library's caption widgets set
      // the same family explicitly through the hook.
      final String? fontFamily = params.titleFontFamily;
      if (fontFamily != null) {
        view = DefaultTextStyle(
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(fontFamily: fontFamily),
          child: view,
        );
      }
    }
    return view;
  }
}
