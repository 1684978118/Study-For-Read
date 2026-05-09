package com.studyforread.server.admin;

import java.util.Arrays;

public enum AdminStatus {
    ACTIVE("active"),
    DISABLED("disabled");

    private final String databaseValue;

    AdminStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static AdminStatus fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(status -> status.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown admin status: " + databaseValue));
    }
}
