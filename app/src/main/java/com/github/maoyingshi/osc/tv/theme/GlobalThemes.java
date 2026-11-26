package com.github.maoyingshi.osc.tv.theme;

import android.content.SharedPreferences;

/**
 * Global themes: named whole-app palette packages — the LeeCat-style
 * 全局主题 library that sits next to the home themes. Where a home
 * theme restyles only the home screen's layout, applying a global
 * theme writes one complete {@link ThemeProfile} through
 * {@link ThemeProfileStore}, so every surface that resolves the saved
 * profile follows at once: native screens via
 * {@link ThemeController#applyFromPreferences}, the Flutter shell via
 * the ui_config theme tokens, and the glass bottom bar's accent with
 * them. No parallel state is kept: the profile is the state, and the
 * {@link #PREF_KEY} preference only records which package was applied
 * last.
 *
 * <p>Relationship with the 主题色彩 editor: a global theme is a preset
 * package over the very same profile the editor edits. Applying one
 * overwrites the profile wholesale; editing colors afterwards edits
 * that profile in place, after which {@link #currentId()} no longer
 * matches a package and the selection reads as custom until another
 * package is applied.
 *
 * <p>Palette provenance: the four Lee-named packages （浅色 / 深色 /
 * 亮色主题 / 暖白影院） follow the directions LeeCat's own changelog
 * documents — warm white + orange-gold for 浅色， cool white + blue
 * for 亮色主题， graphite #252A30 light-theme text, and the theme
 * editor's example pair #F5F0E6 / #302C25 for 暖白影院. Lee ships its
 * palettes as binary constants in its AOT snapshot, so the exact
 * slot values here are equivalents generated through this app's own
 * preset machinery, not lifted originals. The remaining packages
 * reuse the built-in {@link ThemePresets} profiles unchanged.
 */
public final class GlobalThemes {

    /** Activity-preferences key recording the last applied package id. */
    public static final String PREF_KEY = "global_theme_id";

    /** {@link #currentId()} value when the saved profile is no package. */
    public static final String CUSTOM_ID = "custom";

    public static final class Entry {
        /** Package id; "" is the built-in default. Mirrored in Dart. */
        public final String id;
        /** Display name. Mirrored in Dart and in the B7 row value. */
        public final String name;
        /** The ThemeProfile.id a profile written by this package carries. */
        public final String profileId;
        /** Mode the package forces, or null to keep the current mode. */
        public final String mode;

        private Entry(String id, String name, String profileId, String mode) {
            this.id = id;
            this.name = name;
            this.profileId = profileId;
            this.mode = mode;
        }
    }

    private static final Entry[] ENTRIES = {
            new Entry("", "默认", "webhtv.local", null),
            new Entry("light-warm", "浅色", "webhtv.global.light-warm", ThemeProfile.MODE_LIGHT),
            new Entry("dark", "深色", "webhtv.global.dark", ThemeProfile.MODE_DARK),
            new Entry("bright", "亮色主题", "webhtv.global.bright", null),
            new Entry("warm-cinema", "暖白影院", "webhtv.global.warm-cinema", null),
            new Entry("ocean", "澄海蓝", ThemePresets.Preset.OCEAN.id, null),
            new Entry("forest", "松林绿", ThemePresets.Preset.FOREST.id, null),
            new Entry("rose", "蔷薇红", ThemePresets.Preset.ROSE.id, null),
            new Entry("wallpaper", "壁纸取色", ThemePresets.Preset.WALLPAPER.id, null),
    };

    private GlobalThemes() {
    }

    public static Entry find(String id) {
        if (id != null) {
            for (Entry entry : ENTRIES) if (entry.id.equals(id)) return entry;
        }
        return null;
    }

    public static String nameForId(String id) {
        if (CUSTOM_ID.equals(id)) return "自定义";
        Entry entry = find(id);
        return entry != null ? entry.name : "默认";
    }

    /**
     * The package the saved profile currently is: the entry whose
     * profile id the profile carries, or {@link #CUSTOM_ID} when the
     * profile came from the theme-color editor (a non-catalog preset
     * or hand edits) rather than from this library.
     */
    public static String currentId() {
        ThemeProfile profile = ThemeProfileStore.load();
        if (profile != null && profile.id != null) {
            for (Entry entry : ENTRIES) {
                if (entry.profileId.equals(profile.id)) return entry.id;
            }
        }
        return CUSTOM_ID;
    }

    /**
     * Applies a package: builds its profile, keeps the current
     * light/dark mode unless the package forces one （浅色 / 深色 are
     * appearances, not just palettes), persists it through the store
     * and records the selection. Returns false when the store rejects
     * the profile; the previous profile then stays in effect.
     */
    public static boolean apply(SharedPreferences prefs, String id) {
        Entry entry = find(id);
        if (entry == null) entry = find("");
        ThemeProfile profile = build(entry);
        profile.mode = entry.mode != null ? entry.mode
                : ThemeProfile.normalizeMode(ThemeProfileStore.load().mode);
        ThemeProfileStore.ApplyResult result = ThemeProfileStore.apply(profile);
        if (!result.success()) return false;
        if (prefs != null) prefs.edit().putString(PREF_KEY, entry.id).apply();
        return true;
    }

    private static ThemeProfile build(Entry entry) {
        ThemeProfile profile;
        switch (entry.id) {
            case "light-warm" -> {
                // Lee 浅色: warm white + orange-gold, graphite text.
                profile = ThemePresets.Preset.AMBER.profile(ThemePaletteStyle.TONAL_SPOT);
                profile.light.surface = "#FBF5EA";
                profile.light.onSurface = "#252A30";
            }
            case "dark" -> profile =
                    ThemePresets.Preset.GRAPHITE.profile(ThemePaletteStyle.NEUTRAL);
            case "bright" -> {
                // Lee 亮色主题: cool-white base, blue accent, graphite text.
                profile = ThemePresets.Preset.OCEAN.profile(ThemePaletteStyle.TONAL_SPOT);
                profile.light.surface = "#F6F9FC";
                profile.light.onSurface = "#252A30";
            }
            case "warm-cinema" -> {
                // Lee 暖白影院: the editor's example warm pair.
                profile = ThemePresets.Preset.AMBER.profile(ThemePaletteStyle.FIDELITY);
                profile.light.surface = "#F5F0E6";
                profile.light.onSurface = "#302C25";
            }
            case "ocean" -> profile = ThemePresets.Preset.OCEAN.profile();
            case "forest" -> profile = ThemePresets.Preset.FOREST.profile();
            case "rose" -> profile = ThemePresets.Preset.ROSE.profile();
            case "wallpaper" -> profile = ThemePresets.Preset.WALLPAPER.profile();
            default -> profile = ThemePresets.Preset.DEFAULT.profile();
        }
        profile.id = entry.profileId;
        profile.name = entry.name;
        return profile;
    }
}
