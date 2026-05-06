package com.studyforread.server.reading;

public enum BookFileType {
    TXT("txt"),
    EPUB("epub");

    private final String databaseValue;

    BookFileType(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static BookFileType fromDatabaseValue(String databaseValue) {
        for (var fileType : values()) {
            if (fileType.databaseValue.equals(databaseValue)) {
                return fileType;
            }
        }
        throw new IllegalArgumentException("Unknown book file type: " + databaseValue);
    }
}
