package com.studyforread.server.study.dto;

import java.util.UUID;

public record LexemeLookupResponse(
        UUID id,
        String surface,
        String reading,
        String entryType,
        String partOfSpeech,
        String definition,
        String shortDefinition) {
}
