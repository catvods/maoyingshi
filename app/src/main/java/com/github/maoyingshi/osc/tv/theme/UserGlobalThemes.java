package com.github.maoyingshi.osc.tv.theme;

import com.github.catvod.utils.Prefers;

import org.json.JSONArray;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * User-authored global themes: whole-app palette packages the user
 * built in the global theme editor, the counterpart of the imported
 * user home themes. Where {@link GlobalThemes} is a fixed catalog of
 * built-in packages, this store keeps the user's own packages as
 * complete {@link ThemeProfile}s (encoded with
 * {@link ThemeProfileCodec}) in one preferences JSON array, so they
 * survive restarts and apply through the exact same pipeline as a
 * built-in package: {@link GlobalThemes#apply} resolves these ids and
 * writes the stored profile through {@link ThemeProfileStore}.
 *
 * <p>Ids are {@code "user-<md5-10>"} generated at creation time and
 * stay stable across edits (an edit replaces the record in place);
 * the profile a record carries bears the id
 * {@code "webhtv.global." + id}, which is how
 * {@link GlobalThemes#currentId()} recognizes the applied package.
 * Built-in packages can never be overwritten through this store —
 * the editor always saves here, as a user package.
 */
public final class UserGlobalThemes {

    public static final String ID_PREFIX = "user-";
    public static final String PROFILE_ID_PREFIX = "webhtv.global.";

    private static final String KEY = "user_global_themes_v1";

    private UserGlobalThemes() {
    }

    public static final class Entry {
        public final String id;
        public final String name;
        public final ThemeProfile profile;

        private Entry(String id, ThemeProfile profile) {
            this.id = id;
            this.profile = profile;
            this.name = profile.displayName();
        }
    }

    public static boolean isUserId(String id) {
        return id != null && id.startsWith(ID_PREFIX);
    }

    public static String profileIdFor(String id) {
        return PROFILE_ID_PREFIX + id;
    }

    /** A fresh id for a new user package. */
    public static String newId(String seedText) {
        try {
            byte[] digest = MessageDigest.getInstance("MD5")
                    .digest((seedText + "|" + System.nanoTime()).getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return ID_PREFIX + sb.substring(0, 10);
        } catch (Exception e) {
            return ID_PREFIX + Long.toString(System.currentTimeMillis(), 36);
        }
    }

    /** All stored user packages, in creation order. Broken records are skipped. */
    public static List<Entry> list() {
        List<Entry> out = new ArrayList<>();
        String raw = Prefers.getString(KEY, "");
        if (raw == null || raw.isBlank()) return out;
        try {
            JSONArray array = new JSONArray(raw);
            for (int i = 0; i < array.length(); i++) {
                JSONObject obj = array.optJSONObject(i);
                if (obj == null) continue;
                String id = obj.optString("id", "");
                if (!isUserId(id)) continue;
                try {
                    ThemeProfile profile = ThemeProfileCodec.parse(obj.optString("profile", ""));
                    out.add(new Entry(id, profile));
                } catch (Exception ignored) {
                    // A record that no longer parses is skipped, never fatal.
                }
            }
        } catch (Exception ignored) {
            // A corrupted store reads as empty; saving again rewrites it.
        }
        return out;
    }

    public static Entry find(String id) {
        if (!isUserId(id)) return null;
        for (Entry entry : list()) if (entry.id.equals(id)) return entry;
        return null;
    }

    /** Creates or replaces a user package; returns the stored entry. */
    public static Entry save(String id, ThemeProfile profile) throws Exception {
        List<Entry> entries = list();
        Entry saved = new Entry(id, profile);
        boolean replaced = false;
        for (int i = 0; i < entries.size(); i++) {
            if (entries.get(i).id.equals(id)) {
                entries.set(i, saved);
                replaced = true;
                break;
            }
        }
        if (!replaced) entries.add(saved);
        persist(entries);
        return saved;
    }

    public static void delete(String id) {
        if (!isUserId(id)) return;
        List<Entry> entries = list();
        if (entries.removeIf(entry -> entry.id.equals(id))) {
            try {
                persist(entries);
            } catch (Exception ignored) {
                // The in-memory list already dropped it for this session.
            }
        }
    }

    /** Channel view of the store: id, name and the preview colors. */
    public static List<Map<String, Object>> listMaps() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Entry entry : list()) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", entry.id);
            map.put("name", entry.name);
            map.put("surface", orEmpty(entry.profile.slots(false).surface));
            map.put("primary", orEmpty(entry.profile.slots(false).primary));
            map.put("darkSurface", orEmpty(entry.profile.slots(true).surface));
            map.put("darkPrimary", orEmpty(entry.profile.slots(true).primary));
            out.add(map);
        }
        return out;
    }

    private static String orEmpty(String value) {
        return value == null ? "" : value;
    }

    private static void persist(List<Entry> entries) throws Exception {
        JSONArray array = new JSONArray();
        for (Entry entry : entries) {
            JSONObject obj = new JSONObject();
            obj.put("id", entry.id);
            obj.put("profile", ThemeProfileCodec.encode(entry.profile));
            array.put(obj);
        }
        Prefers.getPrefers().edit().putString(KEY, array.toString()).apply();
    }
}
