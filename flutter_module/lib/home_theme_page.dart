import 'package:material_ui/material_ui.dart';

import 'home_theme.dart';
import 'pigeon/c1_messages.g.dart';

/// The home theme library (route /home-theme): a grid of theme
/// cards mirroring PeekPro's 首页主题 page. Tapping a card applies
/// the theme immediately — the selection persists through the host
/// and the B11 home swaps its body live; the built-in home is the
/// first card （默认主题）.
class HomeThemePage extends StatelessWidget {
  const HomeThemePage({super.key});

  Future<void> _onBack() async {
    try {
      await C1HostApi().closeScreen();
    } catch (_) {
      // The host is gone; nothing to go back to.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: const Text('首页主题'),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: homeThemeId,
        builder: (BuildContext context, String activeId, Widget? child) {
          final HomeThemeEntry active = homeThemeEntry(activeId);
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
              Text(
                '内置主题 · ${homeThemeCatalog.length - 1}',
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
                  for (final HomeThemeEntry entry in homeThemeCatalog)
                    _ThemeCard(
                      entry: entry,
                      active: entry.id == activeId,
                      onTap: () => setHomeThemeId(entry.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '点选即应用，返回首页查看效果。主题只改变首页的样子，不影响站源与播放。',
                style: TextStyle(
                  fontSize: 12,
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

  final HomeThemeEntry entry;
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
                      alignment: Alignment.topRight,
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
