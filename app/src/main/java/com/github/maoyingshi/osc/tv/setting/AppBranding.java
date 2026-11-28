package com.github.maoyingshi.osc.tv.setting;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.drawable.RoundedBitmapDrawable;
import androidx.core.graphics.drawable.RoundedBitmapDrawableFactory;

import com.github.maoyingshi.osc.tv.R;
import com.github.maoyingshi.osc.tv.api.config.VodConfig;
import com.github.maoyingshi.osc.tv.bean.Config;
import com.github.maoyingshi.osc.tv.flutter.FlutterNav;
import com.github.maoyingshi.osc.tv.utils.ImgUtil;
import com.github.catvod.utils.Prefers;

/** Owns the supported built-in app branding choices: the default icon,
 * the original icon, and 8 cat icons (modes 2..9). */
public final class AppBranding {

    public static final int ICON_CURRENT = 0;
    public static final int ICON_HISTORY = 1;
    public static final int ICON_MINIMAL = 2;
    public static final int ICON_INK = 3;
    public static final int ICON_CLAPPER = 4;
    public static final int ICON_PAPERCUT = 5;
    public static final int ICON_ORIGAMI = 6;
    public static final int ICON_STICKER = 7;
    public static final int ICON_PROJECTOR = 8;
    public static final int ICON_UKIYOE = 9;
    /** Number of built-in icon choices (modes 0..ICON_COUNT - 1). */
    public static final int ICON_COUNT = 10;

    private static final String ICON_KEY = "app_branding_icon";
    private static final String ALIAS_SUFFIX_CURRENT = "Current";
    private static final String ALIAS_SUFFIX_HISTORY = "History";
    private static final int LOGO_RENDER_SIZE = 192;

    private static int cachedLogoMode = -1;
    private static Drawable cachedLogo;

    private AppBranding() {
    }

    /** Unknown mode values intentionally migrate to the default built-in icon. */
    public static int normalizeIconMode(int mode) {
        return mode >= ICON_CURRENT && mode < ICON_COUNT ? mode : ICON_CURRENT;
    }

    /** Launcher-alias suffix per mode (HomeActivity + suffix). */
    static String launcherAliasSuffix(int mode) {
        switch (normalizeIconMode(mode)) {
            case ICON_HISTORY: return ALIAS_SUFFIX_HISTORY;
            case ICON_MINIMAL: return "Minimal";
            case ICON_INK: return "Ink";
            case ICON_CLAPPER: return "Clapper";
            case ICON_PAPERCUT: return "Papercut";
            case ICON_ORIGAMI: return "Origami";
            case ICON_STICKER: return "Sticker";
            case ICON_PROJECTOR: return "Projector";
            case ICON_UKIYOE: return "Ukiyoe";
            case ICON_CURRENT:
            default: return ALIAS_SUFFIX_CURRENT;
        }
    }

    /** Display labels of the extra built-in icons (modes 2..9), in mode order. */
    @NonNull
    public static java.util.List<String> extraIconLabels(@NonNull Context context) {
        java.util.List<String> labels = new java.util.ArrayList<>(ICON_COUNT - 2);
        for (int mode = 2; mode < ICON_COUNT; mode++) {
            labels.add(context.getString(iconLabelResource(mode)));
        }
        return labels;
    }

    @NonNull
    public static String getName(@NonNull Context context) {
        return context.getString(R.string.app_name);
    }

    /**
     * 首页标题优先展示站点/配置自己的名字，只有两者都空时才回落到应用名。
     * 固定返回应用名会让所有站源都显示成「默影视」，看不出当前在哪个源。
     */
    @NonNull
    public static String getDisplayName(@NonNull Context context, @Nullable String homeName, @Nullable String configName) {
        if (homeName != null && !homeName.trim().isEmpty()) return homeName;
        if (configName != null && !configName.trim().isEmpty()) return configName;
        return getName(context);
    }

    public static int getIconMode() {
        return normalizeIconMode(Prefers.getInt(ICON_KEY, ICON_CURRENT));
    }

    public static int getIconMode(@NonNull Context context) {
        return getIconMode();
    }

    public static void putIconMode(int mode) {
        Prefers.getPrefers().edit().putInt(ICON_KEY, normalizeIconMode(mode)).commit();
        cachedLogo = null;
        cachedLogoMode = -1;
    }

    @NonNull
    public static String getSummary(@NonNull Context context) {
        return context.getString(iconLabelResource(getIconMode(context)));
    }

    /**
     * 首帧先落品牌图标，避免闪白；随后若线路配置带 logo 就异步覆盖上去。
     * 只用品牌图标会让配置里自带的线路图标彻底失效。
     */
    public static void applyLogo(@NonNull ImageView view) {
        view.setImageDrawable(logoDrawable(view.getContext()));
        Config config = VodConfig.get().getConfig();
        String logo = config == null ? null : config.getLogo();
        if (logo != null && !logo.trim().isEmpty()) ImgUtil.logo(view, logo);
    }

    /**
     * Resolves the branded logo synchronously so the first frame never shows the other icon.
     * Adaptive icons and vectors are rasterized once because a circular crop cannot clip them.
     */
    @Nullable
    public static Drawable logoDrawable(@NonNull Context context) {
        int mode = getIconMode(context);
        if (cachedLogo != null && cachedLogoMode == mode) return cachedLogo;
        int resource = logoResource(mode);
        Drawable source;
        try {
            // Read the same alias icon that the launcher uses, keeping desktop and in-app branding identical.
            source = context.getPackageManager().getActivityIcon(launcherIntent(context).getComponent());
        } catch (PackageManager.NameNotFoundException ignored) {
            source = ContextCompat.getDrawable(context, resource);
        }
        if (source == null) return null;
        cachedLogo = toCircle(context.getResources(), source);
        cachedLogoMode = mode;
        return cachedLogo;
    }

    static int logoResource(int mode) {
        switch (normalizeIconMode(mode)) {
            case ICON_HISTORY: return R.drawable.ic_launcher_history;
            case ICON_MINIMAL: return R.drawable.ic_launcher_minimal;
            case ICON_INK: return R.drawable.ic_launcher_ink;
            case ICON_CLAPPER: return R.drawable.ic_launcher_clapper;
            case ICON_PAPERCUT: return R.drawable.ic_launcher_papercut;
            case ICON_ORIGAMI: return R.drawable.ic_launcher_origami;
            case ICON_STICKER: return R.drawable.ic_launcher_sticker;
            case ICON_PROJECTOR: return R.drawable.ic_launcher_projector;
            case ICON_UKIYOE: return R.drawable.ic_launcher_ukiyoe;
            case ICON_CURRENT:
            default: return R.mipmap.ic_launcher;
        }
    }

    @NonNull
    private static Drawable toCircle(@NonNull Resources resources, @NonNull Drawable source) {
        Bitmap bitmap = Bitmap.createBitmap(LOGO_RENDER_SIZE, LOGO_RENDER_SIZE, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        source.setBounds(0, 0, LOGO_RENDER_SIZE, LOGO_RENDER_SIZE);
        source.draw(canvas);
        RoundedBitmapDrawable drawable = RoundedBitmapDrawableFactory.create(resources, bitmap);
        drawable.setCircular(true);
        drawable.setAntiAlias(true);
        return drawable;
    }

    public static int iconLabelResource(int mode) {
        switch (normalizeIconMode(mode)) {
            case ICON_HISTORY: return R.string.app_branding_icon_history;
            case ICON_MINIMAL: return R.string.app_branding_icon_minimal;
            case ICON_INK: return R.string.app_branding_icon_ink;
            case ICON_CLAPPER: return R.string.app_branding_icon_clapper;
            case ICON_PAPERCUT: return R.string.app_branding_icon_papercut;
            case ICON_ORIGAMI: return R.string.app_branding_icon_origami;
            case ICON_STICKER: return R.string.app_branding_icon_sticker;
            case ICON_PROJECTOR: return R.string.app_branding_icon_projector;
            case ICON_UKIYOE: return R.string.app_branding_icon_ukiyoe;
            case ICON_CURRENT:
            default: return R.string.app_branding_icon_current;
        }
    }

    public static void applyLauncherIcon(@NonNull Context context) {
        int selected = getIconMode(context);
        String homeActivity = FlutterNav.HOME_ACTIVITY_CLASS;
        for (int mode = 0; mode < ICON_COUNT; mode++) {
            setComponentEnabled(context, launcherAliasClassName(homeActivity, mode), mode == selected);
        }
    }

    static String launcherAliasClassName(@NonNull String homeActivityClassName, int mode) {
        return homeActivityClassName + launcherAliasSuffix(mode);
    }

    @NonNull
    public static Intent launcherIntent(@NonNull Context context) {
        String alias = launcherAliasClassName(FlutterNav.HOME_ACTIVITY_CLASS, getIconMode(context));
        return new Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .setComponent(new ComponentName(context.getPackageName(), alias));
    }

    private static void setComponentEnabled(@NonNull Context context, @NonNull String className, boolean enabled) {
        try {
            context.getPackageManager().setComponentEnabledSetting(
                    new ComponentName(context.getPackageName(), className),
                    enabled ? PackageManager.COMPONENT_ENABLED_STATE_ENABLED : PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP);
        } catch (RuntimeException ignored) {
            // The next app launch retries the alias synchronization.
        }
    }
}
