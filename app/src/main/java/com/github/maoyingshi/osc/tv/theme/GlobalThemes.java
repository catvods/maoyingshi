package com.github.maoyingshi.osc.tv.theme;

import android.content.SharedPreferences;

import com.google.android.material.color.utilities.Hct;

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
 * <p>User-authored packages live in {@link UserGlobalThemes} and are
 * resolved alongside the catalog here — {@link #apply},
 * {@link #currentId()} and {@link #nameForId(String)} all recognize
 * their ids — so a user package is indistinguishable from a built-in
 * one once applied. Built-ins themselves are never overwritten: the
 * editor saves into the user store only.
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
        if (entry != null) return entry.name;
        if (UserGlobalThemes.isUserId(id)) {
            UserGlobalThemes.Entry user = UserGlobalThemes.find(id);
            if (user != null) return user.name;
        }
        return "默认";
    }

    /**
     * The package the saved profile currently is: the entry whose
     * profile id the profile carries — a built-in catalog entry or a
     * user package from {@link UserGlobalThemes} — or
     * {@link #CUSTOM_ID} when the profile came from the theme-color
     * editor (a non-catalog preset or hand edits) rather than from
     * this library.
     */
    public static String currentId() {
        ThemeProfile profile = ThemeProfileStore.load();
        if (profile != null && profile.id != null) {
            for (Entry entry : ENTRIES) {
                if (entry.profileId.equals(profile.id)) return entry.id;
            }
            for (UserGlobalThemes.Entry user : UserGlobalThemes.list()) {
                if (UserGlobalThemes.profileIdFor(user.id).equals(profile.id)) return user.id;
            }
        }
        return CUSTOM_ID;
    }

    /**
     * The profile a package stands for: the built profile for a
     * catalog id ("" and unknown ids give the default), or a copy of
     * the stored profile for a user package id (null when that record
     * is gone). The global theme editor reads its form values from
     * this and uses it as the base a save overrides.
     */
    public static ThemeProfile profileFor(String id) {
        if (UserGlobalThemes.isUserId(id)) {
            UserGlobalThemes.Entry user = UserGlobalThemes.find(id);
            return user == null ? null : user.profile.copy();
        }
        Entry entry = find(id);
        if (entry == null) entry = find("");
        return build(entry);
    }

    /**
     * Applies a package: builds its profile, keeps the current
     * light/dark mode unless the package forces one （浅色 / 深色 are
     * appearances, not just palettes), persists it through the store
     * and records the selection. Returns false when the store rejects
     * the profile; the previous profile then stays in effect.
     */
    public static boolean apply(SharedPreferences prefs, String id) {
        if (UserGlobalThemes.isUserId(id)) {
            // A user package applies its stored profile as-is (the
            // palette is the package; only the light/dark mode stays
            // the user's current one, like the non-appearance
            // built-ins), through the same store as every package.
            UserGlobalThemes.Entry user = UserGlobalThemes.find(id);
            if (user != null) {
                ThemeProfile profile = user.profile.copy();
                profile.mode = ThemeProfile.normalizeMode(ThemeProfileStore.load().mode);
                ThemeProfileStore.ApplyResult result = ThemeProfileStore.apply(profile);
                if (!result.success()) return false;
                if (prefs != null) prefs.edit().putString(PREF_KEY, user.id).apply();
                return true;
            }
            // The record is gone: fall through to the default package.
        }
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

    // ------------------------------------------------------------------
    // Four-colour palettes (merged theme library)
    //
    // A merged theme (see the theme library merge) binds a home
    // structure to a LeeCat-meta-shaped palette: 主色 (accent), 背景色
    // (background), 渐变色 (gradient) and 面板色 (surface). Building
    // its profile generates the complete slot sets from the accent
    // seed through the preset machinery, then overrides the slot set
    // of the palette's own mode — dark for a dark palette, light for
    // a light one, by the background's luminance — with the four
    // explicit colours:
    //   主色   -> primary (+ focus, + seed)
    //   背景色 -> surface
    //   渐变色 -> primaryContainer
    //   面板色 -> surfaceContainer (+ surfaceContainerHigh, tone-shifted)
    // The other mode's slots stay seed-generated, so the palette
    // reads coherently in both appearances, and the generated
    // onSurface of the overridden mode stays valid because it was
    // generated for a surface of the same luminance side.
    // ------------------------------------------------------------------

    /** Builds (but does not apply) the profile a four-colour palette stands for. */
    public static ThemeProfile buildPaletteProfile(String profileId, String name,
                                                   String accent, String background,
                                                   String gradient, String surface) {
        int seed = parseColor(accent, 0xFF0B57D0);
        ThemeProfile profile = ThemePresets.completeProfile(
                profileId, name, seed, ThemePaletteStyle.TONAL_SPOT);
        boolean darkPalette = luminance(parseColor(background, 0xFF000000)) < 0.35;
        ThemeProfile.SlotSet slots = profile.slots(darkPalette);
        slots.primary = formatColor(seed);
        slots.focus = slots.primary;
        slots.surface = formatColor(parseColor(background, darkPalette ? 0xFF101418 : 0xFFF7F7F7));
        slots.primaryContainer = formatColor(parseColor(gradient, seed));
        int surfaceColor = parseColor(surface, parseColor(background, 0xFF20242A));
        slots.surfaceContainer = formatColor(surfaceColor);
        slots.surfaceContainerHigh = formatColor(toneShift(surfaceColor, darkPalette ? 6 : -6));
        profile.seedSource = ThemeProfile.SEED_CUSTOM;
        profile.seedColor = formatColor(seed);
        return profile;
    }

    /**
     * Applies a four-colour palette as the saved profile, keeping the
     * current light/dark mode. Returns false when the store rejects
     * the profile; the previous profile then stays in effect.
     */
    public static boolean applyPalette(String profileId, String name,
                                       String accent, String background,
                                       String gradient, String surface) {
        ThemeProfile profile = buildPaletteProfile(profileId, name, accent, background, gradient, surface);
        profile.mode = ThemeProfile.normalizeMode(ThemeProfileStore.load().mode);
        return ThemeProfileStore.apply(profile).success();
    }

    /** Parses "#RRGGBB" / "RRGGBB" / "#AARRGGBB"; the fallback on anything else. */
    public static int parseColor(String hex, int fallback) {
        if (hex == null) return fallback;
        String text = hex.trim();
        if (text.startsWith("#")) text = text.substring(1);
        if (text.length() == 8) text = text.substring(2);
        if (text.length() != 6) return fallback;
        try {
            return 0xFF000000 | Integer.parseInt(text, 16);
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private static String formatColor(int color) {
        return ThemeProfileValidator.formatColor(color);
    }

    private static double luminance(int color) {
        double r = ((color >> 16) & 0xFF) / 255.0;
        double g = ((color >> 8) & 0xFF) / 255.0;
        double b = (color & 0xFF) / 255.0;
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    private static int toneShift(int color, double toneDelta) {
        Hct hct = Hct.fromInt(color);
        double tone = Math.max(0, Math.min(100, hct.getTone() + toneDelta));
        return Hct.from(hct.getHue(), hct.getChroma(), tone).toInt();
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
