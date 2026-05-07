package com.studyforread.server.study.provider;

public record ParagraphTranslationResult(
        String providerName,
        String translatedText,
        boolean cached,
        String message) {
}
