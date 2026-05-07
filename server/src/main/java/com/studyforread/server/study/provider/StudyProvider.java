package com.studyforread.server.study.provider;

public interface StudyProvider {

    LookupProviderResult lookup(String text, String sourceLang, String targetLang, String context);

    ParagraphTranslationResult translateParagraph(String text, String sourceLang, String targetLang);

    AnnotationResult annotate(String text, String sourceLang);
}
