package com.github.maoyingshi.osc.tv.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.github.maoyingshi.osc.tv.R;
import com.github.maoyingshi.osc.tv.utils.Notify;

public class ShortcutReceiver extends BroadcastReceiver {

    public static final String ACTION = ShortcutReceiver.class.getSimpleName();

    @Override
    public void onReceive(Context context, Intent intent) {
        Notify.show(R.string.shortcut);
    }
}