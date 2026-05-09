package com.studyforread.server.admin.dto;

public record AdminLexemeUpsertRequest(
        String surface,
        String reading,
        String sourceLang,
        String targetLang,
        String entryType,
        String partOfSpeech,
        String definition,
        String shortDefinition,
        String example,
        String status) {
}
