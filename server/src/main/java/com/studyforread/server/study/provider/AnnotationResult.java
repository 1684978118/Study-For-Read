package com.studyforread.server.study.provider;

import java.util.List;

public record AnnotationResult(
        String providerName,
        List<AnnotationTokenResult> tokens) {

    public AnnotationResult {
        tokens = List.copyOf(tokens);
    }
}
