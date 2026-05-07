package com.studyforread.server.vocabulary;

import java.util.Arrays;

public enum LexemeEntryType {
    WORD("word"),
    PHRASE("phrase"),
    IDIOM("idiom");

    private final String databaseValue;

    LexemeEntryType(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static LexemeEntryType fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(entryType -> entryType.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown lexeme entry type: " + databaseValue));
    }
}
