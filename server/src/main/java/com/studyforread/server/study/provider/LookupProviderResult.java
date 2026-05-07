package com.studyforread.server.study.provider;

public record LookupProviderResult(
        String providerName,
        String kind,
        LookupLexemeResult lexeme,
        String providerMessage) {

    public record LookupLexemeResult(
            String surface,
            String reading,
            String entryType,
            String partOfSpeech,
            String definition,
            String shortDefinition) {
    }
}
