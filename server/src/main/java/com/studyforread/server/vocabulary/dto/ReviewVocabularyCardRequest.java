package com.studyforread.server.vocabulary.dto;

import java.time.OffsetDateTime;

public record ReviewVocabularyCardRequest(Boolean known, OffsetDateTime reviewedAt) {
}
