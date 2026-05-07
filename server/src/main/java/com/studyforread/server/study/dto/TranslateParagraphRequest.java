package com.studyforread.server.study.dto;

public record TranslateParagraphRequest(
        String text,
        String sourceLang,
        String targetLang) {
}
