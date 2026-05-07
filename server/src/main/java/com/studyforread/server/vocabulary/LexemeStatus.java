package com.studyforread.server.vocabulary;

import java.util.Arrays;

public enum LexemeStatus {
    ACTIVE("active"),
    CANDIDATE("candidate"),
    REJECTED("rejected");

    private final String databaseValue;

    LexemeStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static LexemeStatus fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(status -> status.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown lexeme status: " + databaseValue));
    }
}
