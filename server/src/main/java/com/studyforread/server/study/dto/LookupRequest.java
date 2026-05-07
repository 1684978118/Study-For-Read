package com.studyforread.server.study.dto;

public record LookupRequest(
        String text,
        String sourceLang,
        String targetLang,
        String context) {
}
