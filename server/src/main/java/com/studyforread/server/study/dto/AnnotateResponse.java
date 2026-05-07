package com.studyforread.server.study.dto;

import java.util.List;

public record AnnotateResponse(List<AnnotatedTokenResponse> tokens) {

    public AnnotateResponse {
        tokens = List.copyOf(tokens);
    }
}
