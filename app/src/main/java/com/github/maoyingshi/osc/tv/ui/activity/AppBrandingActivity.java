package com.github.maoyingshi.osc.tv.ui.activity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.widget.LinearLayoutCompat;
import androidx.viewbinding.ViewBinding;

import com.github.maoyingshi.osc.tv.R;
import com.github.maoyingshi.osc.tv.databinding.ActivityAppBrandingBinding;
import com.github.maoyingshi.osc.tv.flutter.C1ScreenActivity;
import com.github.maoyingshi.osc.tv.setting.AppBranding;
import com.github.maoyingshi.osc.tv.ui.base.BaseActivity;
import com.github.maoyingshi.osc.tv.utils.Util;

public class AppBrandingActivity extends BaseActivity {

    private ActivityAppBrandingBinding mBinding;
    private int selectedIconMode;
    private final LinearLayoutCompat[] optionContainers = new LinearLayoutCompat[AppBranding.ICON_COUNT];
    private final TextView[] optionLabels = new TextView[AppBranding.ICON_COUNT];

    public static void start(Activity activity) {
        // B8 B15: mobile opens the Flutter branding page (leanback guard
        // keeps TV native). Neither caller is finished here: a C1 caller
        // (B5 personal settings page) must stay alive — C1 is singleTop,
        // start() reuses it via onNewIntent, and finishing it would drop
        // the user to the launcher (see docs/b8-crash-singletop-fix.md);
        // a native caller keeps native behavior (the branding page covers
        // the top, back returns to the settings page).
        if (!Util.isLeanback()) {
            C1ScreenActivity.start(activity, C1ScreenActivity.ROUTE_BRANDING);
            return;
        }
        activity.startActivity(new Intent(activity, AppBrandingActivity.class));
    }

    @Override
    protected ViewBinding getBinding() {
        return mBinding = ActivityAppBrandingBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void initView(Bundle savedInstanceState) {
        selectedIconMode = AppBranding.getIconMode(this);
        optionContainers[AppBranding.ICON_CURRENT] = mBinding.iconCurrent;
        optionLabels[AppBranding.ICON_CURRENT] = mBinding.iconCurrentText;
        optionContainers[AppBranding.ICON_HISTORY] = mBinding.iconHistory;
        optionLabels[AppBranding.ICON_HISTORY] = mBinding.iconHistoryText;
        optionContainers[AppBranding.ICON_MINIMAL] = mBinding.iconMinimal;
        optionLabels[AppBranding.ICON_MINIMAL] = mBinding.iconMinimalText;
        optionContainers[AppBranding.ICON_INK] = mBinding.iconInk;
        optionLabels[AppBranding.ICON_INK] = mBinding.iconInkText;
        optionContainers[AppBranding.ICON_CLAPPER] = mBinding.iconClapper;
        optionLabels[AppBranding.ICON_CLAPPER] = mBinding.iconClapperText;
        optionContainers[AppBranding.ICON_PAPERCUT] = mBinding.iconPapercut;
        optionLabels[AppBranding.ICON_PAPERCUT] = mBinding.iconPapercutText;
        optionContainers[AppBranding.ICON_ORIGAMI] = mBinding.iconOrigami;
        optionLabels[AppBranding.ICON_ORIGAMI] = mBinding.iconOrigamiText;
        optionContainers[AppBranding.ICON_STICKER] = mBinding.iconSticker;
        optionLabels[AppBranding.ICON_STICKER] = mBinding.iconStickerText;
        optionContainers[AppBranding.ICON_PROJECTOR] = mBinding.iconProjector;
        optionLabels[AppBranding.ICON_PROJECTOR] = mBinding.iconProjectorText;
        optionContainers[AppBranding.ICON_UKIYOE] = mBinding.iconUkiyoe;
        optionLabels[AppBranding.ICON_UKIYOE] = mBinding.iconUkiyoeText;
        updateSelection();
        mBinding.toolbar.setNavigationOnClickListener(v -> finish());
    }

    @Override
    protected void initEvent() {
        for (int mode = 0; mode < AppBranding.ICON_COUNT; mode++) {
            final int iconMode = mode;
            optionContainers[mode].setOnClickListener(v -> selectIcon(iconMode));
        }
        mBinding.cancel.setOnClickListener(v -> finish());
        mBinding.save.setOnClickListener(v -> save());
    }

    private void selectIcon(int mode) {
        selectedIconMode = mode;
        updateSelection();
    }

    private void updateSelection() {
        for (int mode = 0; mode < AppBranding.ICON_COUNT; mode++) {
            setSelected(optionContainers[mode], optionLabels[mode], selectedIconMode == mode);
        }
    }

    private void setSelected(LinearLayoutCompat container, TextView label, boolean selected) {
        container.setSelected(selected);
        label.setTextColor(selected ? getColor(R.color.display_option_bg_selected) : getColor(R.color.white));
    }

    private void save() {
        AppBranding.putIconMode(selectedIconMode);
        AppBranding.applyLauncherIcon(this);
        setResult(RESULT_OK);
        Intent intent = AppBranding.launcherIntent(this)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
        finish();
    }
}
