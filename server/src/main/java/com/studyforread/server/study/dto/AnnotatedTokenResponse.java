package com.studyforread.server.study.dto;

public record AnnotatedTokenResponse(
        String text,
        String reading,
        String dictionaryForm,
        String partOfSpeech) {
}
