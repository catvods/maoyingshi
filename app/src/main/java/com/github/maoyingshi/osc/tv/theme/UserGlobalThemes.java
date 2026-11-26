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
                if (KIND_MERGED.equals(obj.optString("kind", ""))) continue;
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
        JSONArray array = loadRawMergedOnly();
        for (Entry entry : entries) {
            JSONObject obj = new JSONObject();
            obj.put("id", entry.id);
            obj.put("profile", ThemeProfileCodec.encode(entry.profile));
            array.put(obj);
        }
        persistRaw(array);
    }

    private static JSONArray loadRaw() {
        String raw = Prefers.getString(KEY, "");
        if (raw == null || raw.isBlank()) return new JSONArray();
        try {
            return new JSONArray(raw);
        } catch (Exception ignored) {
            return new JSONArray();
        }
    }

    /** The merged-theme records of the raw store, kept verbatim. */
    private static JSONArray loadRawMergedOnly() {
        JSONArray raw = loadRaw();
        JSONArray out = new JSONArray();
        for (int i = 0; i < raw.length(); i++) {
            JSONObject obj = raw.optJSONObject(i);
            if (obj != null && KIND_MERGED.equals(obj.optString("kind", ""))) out.put(obj);
        }
        return out;
    }

    private static void persistRaw(JSONArray array) {
        Prefers.getPrefers().edit().putString(KEY, array.toString()).apply();
    }

    // ------------------------------------------------------------------
    // Merged themes
    //
    // Records of the merged theme library: a home structure bound to
    // a four-colour palette plus the parametric editor's component
    // parameters. They share this store's JSON array (kind =
    // "merged") so the app keeps exactly one user-theme store; the
    // palette-package list above skips them, and every write path
    // preserves the other kind's records. The record's profile is
    // the palette profile built at save time (its id is
    // "webhtv.theme." + id, so GlobalThemes.currentId() never
    // mistakes it for a palette package); the editor parameters ride
    // in the "merged" object for re-editing.
    // ------------------------------------------------------------------

    public static final String KIND_MERGED = "merged";
    public static final String PROFILE_ID_PREFIX_MERGED = "webhtv.theme.";

    public static final class MergedEntry {
        public final String id;
        public final String name;
        public final ThemeProfile profile;
        /** Editor parameters: structure, colours and component options. */
        public final JSONObject params;

        private MergedEntry(String id, ThemeProfile profile, JSONObject params) {
            this.id = id;
            this.profile = profile;
            this.params = params;
            this.name = params.optString("name", profile.displayName());
        }

        public String structureSourceId() {
            return params.optString("structureSourceId", "");
        }
    }

    public static String mergedProfileIdFor(String id) {
        return PROFILE_ID_PREFIX_MERGED + id;
    }

    /** All merged-theme records, in creation order. Broken records are skipped. */
    public static List<MergedEntry> listMerged() {
        List<MergedEntry> out = new ArrayList<>();
        JSONArray raw = loadRaw();
        for (int i = 0; i < raw.length(); i++) {
            JSONObject obj = raw.optJSONObject(i);
            if (obj == null || !KIND_MERGED.equals(obj.optString("kind", ""))) continue;
            String id = obj.optString("id", "");
            if (!isUserId(id)) continue;
            JSONObject params = obj.optJSONObject("merged");
            if (params == null) continue;
            try {
                ThemeProfile profile = ThemeProfileCodec.parse(obj.optString("profile", ""));
                out.add(new MergedEntry(id, profile, params));
            } catch (Exception ignored) {
                // A record that no longer parses is skipped, never fatal.
            }
        }
        return out;
    }

    public static MergedEntry findMerged(String id) {
        if (!isUserId(id)) return null;
        for (MergedEntry entry : listMerged()) if (entry.id.equals(id)) return entry;
        return null;
    }

    /** Creates or replaces a merged-theme record; returns the stored entry. */
    public static MergedEntry saveMerged(String id, JSONObject params, ThemeProfile profile) throws Exception {
        JSONArray raw = loadRaw();
        JSONArray out = new JSONArray();
        JSONObject record = new JSONObject();
        record.put("id", id);
        record.put("kind", KIND_MERGED);
        record.put("profile", ThemeProfileCodec.encode(profile));
        record.put("merged", params);
        boolean replaced = false;
        for (int i = 0; i < raw.length(); i++) {
            JSONObject obj = raw.optJSONObject(i);
            if (obj != null && KIND_MERGED.equals(obj.optString("kind", ""))
                    && id.equals(obj.optString("id", ""))) {
                out.put(record);
                replaced = true;
            } else if (obj != null) {
                out.put(obj);
            }
        }
        if (!replaced) out.put(record);
        persistRaw(out);
        return new MergedEntry(id, profile, params);
    }

    public static void deleteMerged(String id) {
        if (!isUserId(id)) return;
        JSONArray raw = loadRaw();
        JSONArray out = new JSONArray();
        boolean changed = false;
        for (int i = 0; i < raw.length(); i++) {
            JSONObject obj = raw.optJSONObject(i);
            if (obj != null && KIND_MERGED.equals(obj.optString("kind", ""))
                    && id.equals(obj.optString("id", ""))) {
                changed = true;
                continue;
            }
            if (obj != null) out.put(obj);
        }
        if (changed) persistRaw(out);
    }

    /** Channel view of the merged records: editor parameters plus preview colours. */
    public static List<Map<String, Object>> mergedMaps() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (MergedEntry entry : listMerged()) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", entry.id);
            map.put("name", entry.name);
            JSONObject p = entry.params;
            map.put("description", p.optString("description", ""));
            map.put("structureSourceId", p.optString("structureSourceId", ""));
            map.put("structureRef", p.optString("structureRef", ""));
            map.put("accent", p.optString("accent", ""));
            map.put("background", p.optString("background", ""));
            map.put("gradient", p.optString("gradient", ""));
            map.put("surface", p.optString("surface", ""));
            map.put("layout", p.optString("layout", "posters"));
            map.put("hero", p.optBoolean("hero", true));
            map.put("heroHeight", p.optDouble("heroHeight", 220.0));
            map.put("gridColumns", p.optInt("gridColumns", 3));
            map.put("cardRadius", p.optDouble("cardRadius", 18.0));
            map.put("floatingNavigation", p.optBoolean("floatingNavigation", true));
            map.put("glassNavigation", p.optBoolean("glassNavigation", false));
            map.put("navigationOpacity", p.optDouble("navigationOpacity", 0.28));
            map.put("titleFont", p.optString("titleFont", "sans"));
            map.put("profileSurface", orEmpty(entry.profile.slots(false).surface));
            map.put("profilePrimary", orEmpty(entry.profile.slots(false).primary));
            out.add(map);
        }
        return out;
    }
}
