package com.studyforread.server.vocabulary;

import java.util.Arrays;

public enum WordCardType {
    LEXEME("lexeme"),
    PRIVATE_SENTENCE("private_sentence");

    private final String databaseValue;

    WordCardType(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static WordCardType fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(cardType -> cardType.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown word card type: " + databaseValue));
    }
}
