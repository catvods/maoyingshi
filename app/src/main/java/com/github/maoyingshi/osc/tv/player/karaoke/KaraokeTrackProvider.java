package com.github.maoyingshi.osc.tv.player.karaoke;

import java.util.List;

interface KaraokeTrackProvider {

    List<KaraokeTrackRepository.SearchResult> search(String keyword) throws Exception;
}
