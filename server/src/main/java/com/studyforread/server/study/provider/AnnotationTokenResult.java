package com.studyforread.server.study.provider;

public record AnnotationTokenResult(
        String text,
        String reading,
        String dictionaryForm,
        String partOfSpeech) {
}
