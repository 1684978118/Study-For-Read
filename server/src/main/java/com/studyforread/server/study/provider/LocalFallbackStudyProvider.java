package com.studyforread.server.study.provider;

import java.util.Arrays;

public class LocalFallbackStudyProvider implements StudyProvider {

    private static final String PROVIDER_NAME = "local_fallback";

    @Override
    public LookupProviderResult lookup(String text, String sourceLang, String targetLang, String context) {
        var normalizedText = normalizeText(text);
        return new LookupProviderResult(
                PROVIDER_NAME,
                "lexeme",
                new LookupProviderResult.LookupLexemeResult(
                        normalizedText,
                        null,
                        "word",
                        null,
                        "local fallback definition for " + normalizedText,
                        "local fallback"),
                null);
    }

    @Override
    public ParagraphTranslationResult translateParagraph(String text, String sourceLang, String targetLang) {
        return new ParagraphTranslationResult(
                PROVIDER_NAME,
                "[local fallback translation unavailable]",
                false,
                null);
    }

    @Override
    public AnnotationResult annotate(String text, String sourceLang) {
        var tokens = Arrays.stream(normalizeText(text).split("\\s+"))
                .filter(token -> !token.isBlank())
                .map(token -> new AnnotationTokenResult(token, null, token, null))
                .toList();
        return new AnnotationResult(PROVIDER_NAME, tokens);
    }

    private String normalizeText(String text) {
        if (text == null) {
            return "";
        }
        return text.trim();
    }
}
