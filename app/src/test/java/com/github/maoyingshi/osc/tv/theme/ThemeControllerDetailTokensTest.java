package com.github.maoyingshi.osc.tv.theme;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;

import org.junit.Test;

/**
 * {@link ThemeController#tokensForDetail(ThemeProfile, ThemeSeed, int, int, boolean)}
 * must resolve the profile's slots for the detail page's own dark/light
 * mode — the stored mode of the profile must not override the explicit
 * choice, and a missing profile must fall back to the frozen palette.
 */
public class ThemeControllerDetailTokensTest {

    @Test
    public void detailTokensUseTheProfileSlotsForTheRequestedMode() {
        ThemeProfile profile = themedProfile();

        ThemeTokens dark = ThemeController.tokensForDetail(profile, ThemeSeed.NONE, 0, 0, true);
        assertEquals(0xFF1A0A12, dark.colorSurface());
        assertEquals(0xFFFF80AB, dark.colorPrimary());
        assertEquals(0xFFF5EDEE, dark.colorOnSurface());
        assertEquals(0xFF000000, dark.colorOnPrimary());
        assertEquals(dark.colorPrimary(), dark.colorFocus());

        ThemeTokens light = ThemeController.tokensForDetail(profile, ThemeSeed.NONE, 0, 0, false);
        assertEquals(0xFFFFF8E1, light.colorSurface());
        assertEquals(0xFF7A1F3D, light.colorPrimary());
        assertEquals(0xFF1A1A1A, light.colorOnSurface());
        assertEquals(0xFFFFFFFF, light.colorOnPrimary());
        assertEquals(light.colorPrimary(), light.colorFocus());
    }

    @Test
    public void explicitModeWinsOverTheProfilesStoredMode() {
        ThemeProfile profile = themedProfile();
        profile.mode = ThemeProfile.MODE_LIGHT;
        ThemeTokens dark = ThemeController.tokensForDetail(profile, ThemeSeed.NONE, 0, 0, true);
        assertEquals(0xFF1A0A12, dark.colorSurface());
        assertEquals(0xFFFF80AB, dark.colorPrimary());
    }

    @Test
    public void nullProfileFallsBackToTheFrozenPalette() {
        assertEquals(ThemeTokens.dark(), ThemeController.tokensForDetail(null, ThemeSeed.NONE, 0, 0, true));
        assertEquals(ThemeTokens.light(), ThemeController.tokensForDetail(null, ThemeSeed.NONE, 0, 0, false));
    }

    @Test
    public void explicitSeedGeneratesAContrastingPaletteInsteadOfReturningTheSeed() {
        int seed = 0xFF0B57D0;
        ThemeTokens tokens = ThemeController.tokensForDetail(
                ThemeProfile.defaultProfile(), ThemeSeed.EXPLICIT, seed, 0, false);
        assertNotEquals(seed, tokens.colorPrimary());
        tokens.requireContrast();
    }

    /** Distinct light/dark slots that already clear every resolver clamp, so the resolved values are exact. */
    private static ThemeProfile themedProfile() {
        ThemeProfile profile = ThemeProfile.defaultProfile();
        profile.light.surface = "#FFF8E1";
        profile.light.surfaceContainer = "#F5EFE0";
        profile.light.surfaceContainerHigh = "#EDE6D6";
        profile.light.primary = "#7A1F3D";
        profile.light.onSurface = "#1A1A1A";
        profile.dark.surface = "#1A0A12";
        profile.dark.surfaceContainer = "#2A1218";
        profile.dark.surfaceContainerHigh = "#3A1A20";
        profile.dark.primary = "#FF80AB";
        profile.dark.onSurface = "#F5EDEE";
        return profile;
    }
}
