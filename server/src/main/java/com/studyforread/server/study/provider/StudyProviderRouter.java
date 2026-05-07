package com.studyforread.server.study.provider;

import java.util.List;

public class StudyProviderRouter {

    private final List<StudyProvider> providers;

    public StudyProviderRouter(List<StudyProvider> providers) {
        if (providers == null || providers.isEmpty()) {
            this.providers = List.of(new LocalFallbackStudyProvider());
            return;
        }
        this.providers = List.copyOf(providers);
    }

    public LookupProviderResult lookup(String text, String sourceLang, String targetLang, String context) {
        return primaryProvider().lookup(text, sourceLang, targetLang, context);
    }

    public ParagraphTranslationResult translateParagraph(String text, String sourceLang, String targetLang) {
        return primaryProvider().translateParagraph(text, sourceLang, targetLang);
    }

    public AnnotationResult annotate(String text, String sourceLang) {
        return primaryProvider().annotate(text, sourceLang);
    }

    private StudyProvider primaryProvider() {
        return providers.getFirst();
    }
}
