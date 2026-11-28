package com.github.maoyingshi.osc.tv.ui.helper;

import com.github.maoyingshi.osc.tv.setting.Setting;
import com.github.maoyingshi.osc.tv.theme.ThemeTokens;

public final class TmdbCinemaTheme {

    private TmdbCinemaTheme() {
    }

    public static boolean resolveLight(int detailThemeMode, boolean systemNight) {
        return Setting.resolveTmdbDetailLightTheme(detailThemeMode, systemNight);
    }

    public static Palette palette(boolean light) {
        return light ? light() : dark();
    }

    /**
     * Builds the cinema palette from the active global theme's tokens, so
     * the cinema style's cards follow the theme like the rest of the detail
     * page. The mapping mirrors the detail page's own colour contract: the
     * same surface/container/outline/primary slots, the same fixed alphas the
     * fixed palettes used — only the hue now comes from the theme. Deliberate
     * consequences for the default theme: cinema light loses its fixed warm
     * paper tint (it takes the theme's surface — a warm global theme restores
     * the warmth), accent/play follow the theme primary instead of the old
     * green/bronze, and chipActive follows the theme's success container
     * instead of the old amber (light).
     */
    public static Palette fromTokens(ThemeTokens tokens, boolean light) {
        int surface = tokens.colorSurface();
        int surfaceContainer = tokens.colorSurfaceContainer();
        int surfaceContainerHigh = tokens.colorSurfaceContainerHigh();
        int onSurface = tokens.colorOnSurface();
        return new Palette(
                surface,
                withAlpha(surfaceContainer, light ? 0x99 : 0xC9),
                surfaceContainerHigh,
                light ? withAlpha(surfaceContainer, 0xD9) : withAlpha(surfaceContainerHigh, 0x40),
                withAlpha(tokens.colorSuccessContainer(), light ? 0xFF : 0x66),
                withAlpha(tokens.colorOutline(), light ? 0x33 : 0x24),
                withAlpha(tokens.colorOutline(), light ? 0x66 : 0x42),
                onSurface,
                withAlpha(onSurface, light ? 0xCC : 0xD9),
                tokens.colorOnSurfaceVariant(),
                withAlpha(onSurface, 0xE6),
                tokens.colorPrimary(),
                tokens.colorPrimary(),
                withAlpha(surface, light ? 0xBF : 0xB3),
                withAlpha(light ? surfaceContainer : surfaceContainerHigh, light ? 0xD9 : 0xB3),
                withAlpha(tokens.colorOutline(), 0x33),
                withAlpha(surfaceContainer, light ? 0x1F : 0x26),
                withAlpha(surfaceContainerHigh, light ? 0xD9 : 0x40)
        );
    }

    /** Replaces only the alpha of an opaque theme colour. */
    private static int withAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | ((alpha & 0xFF) << 24);
    }

    private static Palette dark() {
        return new Palette(
                0xFF090B0F,
                0xC914171C,
                0xFF252A32,
                0x40252A32,
                0x664B8F72,
                0x24FFFFFF,
                0x42FFFFFF,
                0xFFFFFFFF,
                0xD9FFFFFF,
                0x99FFFFFF,
                0xE6FFFFFF,
                0xFF8FE7B6,
                0xFF2DBA76,
                0xB3090B0F,
                0xB314202A,
                0x33FFFFFF,
                0x26FFFFFF,
                0x40000000
        );
    }

    private static Palette light() {
        return new Palette(
                0xFFEBE3DA,
                0x99FFFFFF,
                0xFFF6F1EA,
                0xD9FFFFFF,
                0xFFFFE9CC,
                0x33806E5F,
                0x66806E5F,
                0xFF12202D,
                0xCC1D2A38,
                0x991D2A38,
                0xE61D2A38,
                0xFFA8702F,
                0xFFB7802F,
                0xBFEBE3DA,
                0xD9FFFFFF,
                0x33806E5F,
                0x1F1D2A38,
                0xD9FFFFFF
        );
    }

    public record Palette(int background, int panel, int control, int chip, int chipActive, int line, int lineStrong,
                          int primary, int secondary, int muted, int body, int accent, int play, int backdropShade,
                          int card, int cardStroke, int imagePlaceholder, int ratingChip) {
    }
}
