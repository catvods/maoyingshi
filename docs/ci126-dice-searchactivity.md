# CI #126：DiceFragment 引用已删的 mobile SearchActivity

## 失败

CI run #126（新仓库 xinyonghuu/maoyingshi，分支 b8-flutter-rewrite）在
"Build four release APKs" 失败，唯一一个 Java 错误：

```
DiceFragment.java:34: error: cannot find symbol
  symbol:   class SearchActivity
```

签名步骤已通过，不是密钥问题。

## 原因

DiceFragment 是主分支合并进来的新文件（骰子选片页），主分支上移动端
仍有 `SearchActivity`，所以它直接 `import …ui.activity.SearchActivity`
并在两处回落里调用 `SearchActivity.start(activity, keyword)`。
但本分支的删原生程序（phase 4a）已删掉移动端的 SearchActivity，
现在 `SearchActivity` 只存在于 `app/src/leanback/`。移动端搜索在本分支
统一走 `FlutterNav.openSearch(Activity, String)`（Flutter 搜索页
`ROUTE_SEARCH`，调用方不 finish）。

## 修复

文件：`app/src/mobile/java/com/github/maoyingshi/osc/tv/ui/fragment/DiceFragment.java`

- import：`com.github.maoyingshi.osc.tv.ui.activity.SearchActivity`
  → `com.github.maoyingshi.osc.tv.flutter.FlutterNav`（按包名字母序放
  在 `db.AppDatabase` 之后、`setting.DiceSetting` 之前）。
- `playDirect` 回落（:296）：`SearchActivity.start(requireActivity(), name)`
  → `FlutterNav.openSearch(requireActivity(), name)`。
- `openDetail` 回落（:325）：`SearchActivity.start(requireActivity(), item.getName())`
  → `FlutterNav.openSearch(requireActivity(), item.getName())`。
- 两处提到 SearchActivity 的注释同步改名：类头注释（:71）改为
  "FlutterNav.openSearch 打开 Flutter 搜索页"；`searchFirstByName`
  注释（:302）改为"与 Flutter 搜索页用的同一条 SiteApi.searchContent"。
  仅注释，无行为变化。

## 验证

- `FlutterNav.openSearch(Activity, String)` 存在于
  `app/src/main/java/com/github/maoyingshi/osc/tv/flutter/FlutterNav.java:214`，
  注释明确写着 "Replaces {@code SearchActivity.start(Activity, String)}"，
  参数（Activity, String）与两处调用点逐字对应；移动端分支打开
  C1 `ROUTE_SEARCH` 并 URL 编码 keyword，与原 `SearchActivity.start`
  的行为一致（打开搜索页、不 finish 调用方）。
- 改后 `grep -n SearchActivity DiceFragment.java` 只剩 0 处代码引用
  （import、调用、注释全部清理）。
- 全树核查：`grep -rn SearchActivity app/src/mobile app/src/main` 除
  DiceFragment 外无任何 import 或静态调用；其余命中均为注释文字
  （B2/B4/B8/B9/B12/B13/B17/B18 host impl 的文档注释、FlutterNav 自身
  的 "Replaces …" 注释）或 HkSearchActivity 字符串常量（另一已删的
  Hk 类，反射 fail-soft，与本次编译错误无关），均不影响编译，
  未改动。CI 日志也只报了这 1 个错误，与核查结果一致。
- 本机无 Java/Android/Flutter SDK，无法本地编译；下一次 CI 即为
  编译验证。

## Recovery anchor

- 目标：消除 CI #126 唯一报错，DiceFragment 搜索回落走 FlutterNav。
- 状态：已完成，本地提交待父级推送。
- 下一步：父级推送后看 CI 是否通过 "Build four release APKs"。
