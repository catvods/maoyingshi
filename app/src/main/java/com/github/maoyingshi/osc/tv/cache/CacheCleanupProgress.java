package com.github.maoyingshi.osc.tv.cache;

public record CacheCleanupProgress(CacheModuleId moduleId, int completedModules,
                                   int totalModules, long bytesBefore, long bytesAfter) {
}
