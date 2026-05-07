package com.studyforread.server.vocabulary.dto;

import java.util.UUID;

public record LexemeSummaryResponse(
        UUID id,
        String surface,
        String reading,
        String definition) {
}
