package com.studyforread.server.user;

import java.util.Arrays;

public enum UserStatus {
    ACTIVE("active"),
    DISABLED("disabled");

    private final String databaseValue;

    UserStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static UserStatus fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(status -> status.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown user status: " + databaseValue));
    }
}
