package com.github.maoyingshi.osc.tv.utils;

public final class SearchSourceVisibility {

    private SearchSourceVisibility() {
    }

    public static boolean shouldShow(boolean hasVisibleResults) {
        return hasVisibleResults;
    }
}
