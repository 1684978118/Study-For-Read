package com.studyforread.server.study.dto;

public record LookupResponse(
        String kind,
        LexemeLookupResponse lexeme,
        String provider,
        String providerMessage) {
}
