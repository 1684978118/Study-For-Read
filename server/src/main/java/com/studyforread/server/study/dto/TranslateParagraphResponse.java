package com.studyforread.server.study.dto;

public record TranslateParagraphResponse(
        String translatedText,
        String provider,
        boolean cached,
        String message) {
}
