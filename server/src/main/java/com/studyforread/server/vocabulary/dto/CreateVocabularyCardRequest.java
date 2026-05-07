package com.studyforread.server.vocabulary.dto;

import java.util.UUID;

public record CreateVocabularyCardRequest(
        String cardType,
        UUID lexemeId,
        String privateSurface,
        String privateDefinition,
        String privateContext,
        String sourceBookFingerprint,
        String sourceBookTitle) {
}
