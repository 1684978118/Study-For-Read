package com.studyforread.server.study;

import java.util.Arrays;

public enum TranslationRequestType {
    WORD_LOOKUP("word_lookup"),
    PARAGRAPH_TRANSLATION("paragraph_translation"),
    ANNOTATION("annotation");

    private final String databaseValue;

    TranslationRequestType(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static TranslationRequestType fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(requestType -> requestType.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown translation request type: " + databaseValue));
    }
}
