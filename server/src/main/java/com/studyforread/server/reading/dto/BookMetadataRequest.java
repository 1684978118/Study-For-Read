package com.studyforread.server.reading.dto;

public record BookMetadataRequest(
        String title,
        String author,
        String fileType,
        String sourceLang,
        String targetLang,
        int chapterCount) {
}
