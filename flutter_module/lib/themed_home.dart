import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import 'home_theme.dart';
import 'peek_home_library.dart';
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
/// inline filter panel has no snapshot source yet, so filter events
/// open the native type-filter dialog instead — the same panel the
/// home's tune FAB opens — and the grid reloads when it closes.
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
  List<B12BannerItem> _recommend = <B12BannerItem>[];
  List<B11TabVideoItem> _items = <B11TabVideoItem>[];
  String _siteKey = '';
  int _tabIndex = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _nextPage = 1;
  String _displayStyle = 'grid';
  String _errorMessage = '';
  int _immersiveIndex = 0;
  int _loadSerial = 0;

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
    super.dispose();
  }

  Future<void> _loadThemeLibrary() async {
    try {
      final String text = await rootBundle
          .loadString('assets/peek_home/theme_${homeThemeId.value}.rfwtxt');
      _runtime.update(_themeName, parseLibraryFile(text));
      if (mounted) setState(() => _themeReady = true);
    } catch (_) {
      if (mounted) setState(() => _themeFailed = true);
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
      'filters': <Map<String, Object?>>[],
      'hasFilters': false,
      'showFilters': false,
      'filterPanelHeight': 0.0,
      'immersiveFilterPanelHeight': 0.0,
      'source': <String, Object?>{'name': screen.title},
      'totalLabel': '${_items.length}',
      'hasRecommend': _recommend.isNotEmpty,
      'hasManyClasses': screen.tabs.length > 5,
      'displayStyle': _displayStyle,
      'gridColumns': 3,
      'largeGridColumns': 2,
      'bannerColumns': 2,
      'glassGridColumns': 3,
      'heroHeight': 220.0,
      'wideListRatio': 2.4,
      'textListRatio': 5.5,
      'stickyHeaderHeight': 54.0,
      'immersiveStickyHeaderHeight': 54.0,
      'immersive': <String, Object?>{
        'active': immersiveItem != null,
        'imageUrl': immersiveItem?.picUrl ?? '',
        'primaryColor': 0xFF1A237E,
        'secondaryColor': 0xFF4A148C,
        'backgroundColor': 0xFF0B0B10,
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
      case 'showCategoryPicker':
      case 'showFilterPicker':
        unawaited(_openFilterDialog());
      case 'selectFilter':
        // No inline filter panel yet; selections happen in the
        // native dialog the filter events above open.
        break;
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
    return RemoteWidget(
      runtime: _runtime,
      data: _data,
      widget: const FullyQualifiedWidgetName(_themeName, 'root'),
      onEvent: _onEvent,
    );
  }
}
