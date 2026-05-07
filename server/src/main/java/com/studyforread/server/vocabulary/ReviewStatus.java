package com.studyforread.server.vocabulary;

import java.util.Arrays;

public enum ReviewStatus {
    NEW("new"),
    LEARNING("learning"),
    KNOWN("known");

    private final String databaseValue;

    ReviewStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static ReviewStatus fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(status -> status.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown review status: " + databaseValue));
    }
}
