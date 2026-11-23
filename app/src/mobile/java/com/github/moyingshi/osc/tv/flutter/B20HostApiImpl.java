package com.github.moyingshi.osc.tv.flutter;

import androidx.appcompat.app.AppCompatActivity;

import java.util.ArrayList;
import java.util.List;

/**
 * B8 B20 compatibility stub for the removed Hiker miniapp manager.
 *
 * <p>Main removed the Hiker miniapp engine, its activities and all of
 * its string resources. The generated B20 Pigeon contract and the
 * registrar are still part of the merged tree, so this implementation
 * keeps that contract compiling while returning an empty, idle
 * snapshot for every operation. Removing the now-dead B20 Flutter
 * screen and contract is a separate follow-up task.
 */
public class B20HostApiImpl implements B20Messages.B20HostApi {

    @SuppressWarnings("unused")
    private volatile AppCompatActivity activity;

    public B20HostApiImpl(AppCompatActivity activity) {
        this.activity = activity;
    }

    /** Rebinds this implementation to a new Activity instance. */
    public void rebind(AppCompatActivity activity) {
        this.activity = activity;
    }

    /** Releases the bound Activity when the registrar is unregistered. */
    public void dispose() {
        activity = null;
    }

    @Override
    public B20Messages.B20HkShell getHkShell() {
        return new B20Messages.B20HkShell.Builder()
                .setTitle("")
                .setImportFileLabel("")
                .setImportPasteLabel("")
                .setSyncLabel("")
                .setExportLabel("")
                .setCloudCodeLabel("")
                .setCancelLabel("")
                .setImportLabel("")
                .setRetryLabel("")
                .setPickTitle("")
                .setPickFileLabel("")
                .setPickDirLabel("")
                .setPasteTitle("")
                .setPasteHint("")
                .setCloudTitle("")
                .setCloudHint("")
                .setCloudNote("")
                .setDeleteLabel("")
                .build();
    }

    @Override
    public void getHkScreen(B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public void importPasteJson(String text,
            B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public B20Messages.B20CloudCodePrefill getCloudCodePrefill() {
        return new B20Messages.B20CloudCodePrefill.Builder()
                .setPrefillText("")
                .build();
    }

    @Override
    public void importCloudCodes(String text,
            B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public void syncMiniapps(B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public void requestHkImportPick(String kind) {
        // No picker remains after the Hiker removal.
    }

    @Override
    public void exportMiniapps(List<String> keys,
            B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public void deleteMiniapp(String key,
            B20Messages.Result<B20Messages.B20HkScreen> result) {
        result.success(emptyScreen());
    }

    @Override
    public void openMiniappList(String key) {
        // The native miniapp list activity was removed on main.
    }

    @Override
    public void disposeHk() {
        // No Hiker session or worker remains to dispose.
    }

    private static B20Messages.B20HkScreen emptyScreen() {
        return new B20Messages.B20HkScreen.Builder()
                .setTitle("")
                .setEntries(new ArrayList<>())
                .setEmptyText("")
                .setBusy(false)
                .setLoadErrorText("")
                .setNoticeText("")
                .setDialogErrorText("")
                .setPickState("idle")
                .setPickEpoch(0L)
                .setPickMessage("")
                .build();
    }
}
