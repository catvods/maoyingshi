package com.github.maoyingshi.osc.tv.module;

import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class ModuleDefinitionTest {

    @Test
    public void allEightModulesDefined() {
        assertEquals(8, ModuleDefinition.ALL.size());
        Set<String> ids = new HashSet<>();
        for (ModuleDefinition definition : ModuleDefinition.ALL) {
            assertTrue("duplicate id: " + definition.id, ids.add(definition.id));
            assertNotNull(ModuleDefinition.byId(definition.id));
        }
    }

    @Test
    public void loadOrderIsSubsetOfFiles() {
        for (ModuleDefinition definition : ModuleDefinition.ALL) {
            for (String name : definition.loadOrder) {
                assertTrue(definition.id + " loadOrder not in files: " + name,
                        definition.files.contains(name));
            }
        }
    }

    @Test
    public void nativeModulesHaveLoadOrder_lutDoesNot() {
        assertTrue(ModuleDefinition.MPV.loadOrder.size() == 10);
        assertTrue(ModuleDefinition.VLC.loadOrder.size() == 3);
        assertTrue(ModuleDefinition.SHERPA.loadOrder.size() == 1);
        assertTrue(ModuleDefinition.DOVI.loadOrder.size() == 2);
        assertTrue(ModuleDefinition.IJK.loadOrder.size() == 3);
        assertTrue(ModuleDefinition.THUNDER.loadOrder.size() == 2);
        assertTrue(ModuleDefinition.LUT.loadOrder.isEmpty());
        assertTrue(ModuleDefinition.FONTS.loadOrder.isEmpty());
    }

    @Test
    public void thunderLoadsStatFirst() {
        // readelf 实测：libxl_thunder_sdk.so 的 DT_NEEDED 含 libxl_stat.so，
        // stat 必须先预载，否则 thunder_sdk 加载失败。
        assertEquals("libxl_stat.so", ModuleDefinition.THUNDER.loadOrder.get(0));
        assertEquals("libxl_thunder_sdk.so", ModuleDefinition.THUNDER.loadOrder.get(1));
        assertEquals("libxl_stat.so", ModuleDefinition.THUNDER.files.get(0));
        assertEquals("libxl_thunder_sdk.so", ModuleDefinition.THUNDER.files.get(1));
    }

    @Test
    public void fontsModuleIsAssetOnly() {
        assertEquals("NotoSerifSC.ttf", ModuleDefinition.FONTS.files.get(0));
        assertEquals("LXGWWenKaiLite-Regular.ttf", ModuleDefinition.FONTS.files.get(1));
        assertEquals("module-fonts-arm64-v8a-560.zip",
                ModuleDefinition.FONTS.zipName("arm64-v8a", 560));
    }

    @Test
    public void vlcModuleBundlesLibcxxFirst() {
        // Stage 0 实测：libvlc.so 需要 libc++_shared.so，基础包拆走 VLC 后不再自带它，
        // 故 VLC 模块必须自带并先预载。
        assertEquals("libc++_shared.so", ModuleDefinition.VLC.loadOrder.get(0));
        assertEquals("libvlc.so", ModuleDefinition.VLC.loadOrder.get(1));
        assertEquals("libvlcjni.so", ModuleDefinition.VLC.loadOrder.get(2));
    }

    @Test
    public void zipNames() {
        assertEquals("module-mpv-arm64-v8a-560.zip",
                ModuleDefinition.MPV.zipName("arm64-v8a", 560));
        assertEquals("modules-all-arm64-v8a-560.zip",
                ModuleDefinition.totalBundleName("arm64-v8a", 560));
        assertNull(ModuleDefinition.byId("no-such-module"));
    }
}
