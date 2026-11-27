package com.github.maoyingshi.osc.tv.player.extractor;

import android.net.Uri;
import android.os.SystemClock;

import com.github.maoyingshi.osc.tv.App;
import com.github.maoyingshi.osc.tv.R;
import com.github.maoyingshi.osc.tv.bean.Episode;
import com.github.maoyingshi.osc.tv.exception.ExtractException;
import com.github.maoyingshi.osc.tv.module.ModuleDefinition;
import com.github.maoyingshi.osc.tv.module.ModuleManager;
import com.github.maoyingshi.osc.tv.player.Source;
import com.github.maoyingshi.osc.tv.utils.Download;
import com.github.maoyingshi.osc.tv.utils.ResUtil;
import com.github.maoyingshi.osc.tv.utils.UrlUtil;
import com.github.catvod.utils.Path;
import com.github.catvod.utils.Util;
import com.xunlei.downloadlib.XLTaskHelper;
import com.xunlei.downloadlib.parameter.GetTaskId;
import com.xunlei.downloadlib.parameter.TorrentFileInfo;
import com.xunlei.downloadlib.parameter.XLTaskInfo;

import java.io.File;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.regex.Pattern;

public class Thunder implements Source.Extractor {

    private GetTaskId taskId;

    /** 迅雷模块是否已在本进程内预载成功（.so 一旦载入无法卸载，成功即永久有效）。 */
    private static volatile boolean sLoaded;

    /**
     * 确保迅雷模块已预载：未安装时返回 false，调用方走降级（Parser 直接跳过、
     * fetch 抛模块缺失提示）。XLTaskHelper 首次触碰即加载 native 库，
     * 所以任何 XLTaskHelper.get() 之前都必须先过这一关，否则抛 UnsatisfiedLinkError。
     * 做文件 IO（读 manifest），调用方保证在工作线程执行（播放解析与剧集解析均在后台线程）。
     */
    static boolean ensureLoaded() {
        if (sLoaded) return true;
        boolean loaded = ModuleManager.getInstance(App.get())
                .ensureLoaded(ModuleDefinition.THUNDER);
        if (loaded) sLoaded = true;
        return loaded;
    }

    @Override
    public boolean match(Uri uri) {
        return List.of("magnet", "ed2k").contains(UrlUtil.scheme(uri));
    }

    @Override
    public String fetch(String url) throws Exception {
        if (!ensureLoaded()) {
            throw new ExtractException("磁力/电驴播放需要迅雷模块，请到 设置 → 特色功能 → 模块 下载「迅雷」");
        }
        return url.startsWith("magnet") ? addTorrentTask(Uri.parse(url)) : addThunderTask(url);
    }

    private String addTorrentTask(Uri uri) throws Exception {
        File torrent = new File(uri.getPath());
        File parent = torrent.getParentFile();
        String name = uri.getQueryParameter("name");
        int index = Integer.parseInt(uri.getQueryParameter("index"));
        taskId = XLTaskHelper.get().addTorrentTask(torrent, parent, index);
        for (int i = 0; i < 100; i++) {
            XLTaskInfo info = XLTaskHelper.get().getBtSubTaskInfo(taskId, index).mTaskInfo;
            if (info.mTaskStatus == 3) throw new ExtractException(info.getErrorMsg());
            if (info.mTaskStatus != 0) return XLTaskHelper.get().getLocalUrl(new File(parent, name));
            SystemClock.sleep(100);
        }
        throw new ExtractException(ResUtil.getString(R.string.error_play_timeout));
    }

    private String addThunderTask(String url) {
        File folder = Path.thunder(Util.md5(url));
        taskId = XLTaskHelper.get().addThunderTask(url, folder);
        return XLTaskHelper.get().getLocalUrl(taskId.getSaveFile());
    }

    @Override
    public void stop() {
        if (taskId == null) return;
        XLTaskHelper.get().deleteTask(taskId);
        XLTaskHelper.get().release();
        taskId = null;
    }

    @Override
    public void exit() {
        if (sLoaded) XLTaskHelper.get().release();
    }

    public record Parser(String url) implements Callable<List<Episode>> {

        private static final Pattern PATTERN = Pattern.compile("(magnet|thunder|ed2k):.*");

        public static boolean match(String url) {
            // 先做无 IO 的格式判断，只有真像磁力/种子链接时才查模块状态：
            // 未安装时返回 false，剧集保持原样（单个磁力剧集），点播时 fetch 再报模块缺失；
            // 若这里先返回 true，解析线程会在 XLTaskHelper.get() 上抛 UnsatisfiedLinkError，
            // 导致整页剧集加载失败。
            if (!PATTERN.matcher(url).find() && !isTorrent(url)) return false;
            return ensureLoaded();
        }

        public static Parser get(String url) {
            return new Parser(url);
        }

        private static boolean isTorrent(String url) {
            return !url.startsWith("magnet") && url.split(";")[0].toLowerCase().endsWith(".torrent");
        }

        private Episode create(GetTaskId taskId) {
            return Episode.create(taskId.getFileName(), taskId.getRealUrl());
        }

        private Episode create(TorrentFileInfo info) {
            return Episode.create(info.getFileName(), info.getSize(), info.getPlayUrl());
        }

        @Override
        public List<Episode> call() {
            boolean torrent = isTorrent(url);
            GetTaskId taskId = XLTaskHelper.get().parse(url, Path.thunder(Util.md5(url)));
            if (!torrent && !taskId.getRealUrl().startsWith("magnet")) return Arrays.asList(create(taskId));
            if (torrent && url.startsWith("http")) Download.create(url, taskId.getSaveFile()).get();
            if (!torrent) waitDone(taskId);
            try {
                return XLTaskHelper.get().getTorrentInfo(taskId.getSaveFile()).getMedias().stream().map(this::create).toList();
            } finally {
                XLTaskHelper.get().stopTask(taskId);
            }
        }

        private void waitDone(GetTaskId taskId) {
            for (int i = 0; i < 100; i++) {
                if (XLTaskHelper.get().getTaskInfo(taskId).getTaskStatus() == 2) return;
                SystemClock.sleep(100);
            }
        }
    }
}
