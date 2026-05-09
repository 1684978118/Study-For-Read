package com.studyforread.server.admin;

import java.util.Arrays;

public enum AdminRole {
    ADMIN("admin"),
    OPERATOR("operator");

    private final String databaseValue;

    AdminRole(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static AdminRole fromDatabaseValue(String databaseValue) {
        return Arrays.stream(values())
                .filter(role -> role.databaseValue.equals(databaseValue))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown admin role: " + databaseValue));
    }
}
