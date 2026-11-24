package com.github.maoyingshi.osc.tv.cache;

public record CacheProtection(boolean allowAutomaticCleanup, boolean allowManualCleanup,
                              boolean requireOwnerIdle, boolean requireAppIdle,
                              long minimumKeepBytes, long minimumKeepFiles,
                              boolean keepIfActiveSession) {
}
