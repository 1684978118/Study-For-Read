package com.studyforread.server.study;

import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.study.dto.LexemeLookupResponse;
import com.studyforread.server.study.dto.LookupRequest;
import com.studyforread.server.study.dto.LookupResponse;
import com.studyforread.server.study.provider.LocalFallbackStudyProvider;
import com.studyforread.server.study.provider.LookupProviderResult;
import com.studyforread.server.study.provider.StudyProviderRouter;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.vocabulary.Lexeme;
import com.studyforread.server.vocabulary.LexemeEntryType;
import com.studyforread.server.vocabulary.LexemeRepository;
import com.studyforread.server.vocabulary.LexemeStatus;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StudyService {

    private static final char[] HEX = "0123456789abcdef".toCharArray();
    private static final String PUBLIC_LEXEME_PROVIDER = "public_lexeme";
    private static final String SUPPORTED_SOURCE_LANG = "ja";
    private static final String SUPPORTED_TARGET_LANG = "zh-CN";

    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;
    private final ObjectProvider<LexemeRepository> lexemeRepositoryProvider;
    private final ObjectProvider<TranslationEventRepository> translationEventRepositoryProvider;
    private final StudyProviderRouter studyProviderRouter;

    public StudyService(
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider,
            ObjectProvider<LexemeRepository> lexemeRepositoryProvider,
            ObjectProvider<TranslationEventRepository> translationEventRepositoryProvider) {
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
        this.lexemeRepositoryProvider = lexemeRepositoryProvider;
        this.translationEventRepositoryProvider = translationEventRepositoryProvider;
        this.studyProviderRouter = new StudyProviderRouter(List.of(new LocalFallbackStudyProvider()));
    }

    @Transactional(noRollbackFor = UnsupportedLanguagePairException.class)
    public LookupResponse lookup(UUID userId, LookupRequest request) {
        var user = userAccountRepository().findById(userId).orElseThrow(CurrentUserNotFoundException::new);
        var text = request.text().trim();
        var sourceLang = request.sourceLang().trim();
        var targetLang = request.targetLang().trim();
        var sourceTextHash = sha256Hex(text);
        var sourceTextLength = text.length();

        if (!SUPPORTED_SOURCE_LANG.equals(sourceLang) || !SUPPORTED_TARGET_LANG.equals(targetLang)) {
            saveTranslationEvent(
                    user,
                    sourceLang,
                    targetLang,
                    null,
                    sourceTextHash,
                    sourceTextLength,
                    false,
                    ErrorCode.TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR.name());
            throw new UnsupportedLanguagePairException();
        }

        var normalizedSurface = text.toLowerCase(Locale.ROOT);
        var publicLexeme = lexemeRepository()
                .findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
                        sourceLang,
                        targetLang,
                        normalizedSurface,
                        LexemeEntryType.WORD.databaseValue())
                .filter(lexeme -> lexeme.getStatus() == LexemeStatus.ACTIVE);

        if (publicLexeme.isPresent()) {
            saveTranslationEvent(
                    user,
                    sourceLang,
                    targetLang,
                    PUBLIC_LEXEME_PROVIDER,
                    sourceTextHash,
                    sourceTextLength,
                    true,
                    null);
            return new LookupResponse("lexeme", toResponse(publicLexeme.get()), PUBLIC_LEXEME_PROVIDER, null);
        }

        var providerResult = studyProviderRouter.lookup(text, sourceLang, targetLang, request.context());
        saveTranslationEvent(
                user,
                sourceLang,
                targetLang,
                providerResult.providerName(),
                sourceTextHash,
                sourceTextLength,
                true,
                null);
        return toResponse(providerResult);
    }

    private LookupResponse toResponse(LookupProviderResult providerResult) {
        var providerLexeme = providerResult.lexeme();
        var lexeme = providerLexeme == null
                ? null
                : new LexemeLookupResponse(
                        null,
                        providerLexeme.surface(),
                        providerLexeme.reading(),
                        providerLexeme.entryType(),
                        providerLexeme.partOfSpeech(),
                        providerLexeme.definition(),
                        providerLexeme.shortDefinition());

        return new LookupResponse(
                providerResult.kind(),
                lexeme,
                providerResult.providerName(),
                providerResult.providerMessage());
    }

    private LexemeLookupResponse toResponse(Lexeme lexeme) {
        return new LexemeLookupResponse(
                lexeme.getId(),
                lexeme.getSurface(),
                lexeme.getReading(),
                lexeme.getEntryType().databaseValue(),
                lexeme.getPartOfSpeech(),
                lexeme.getDefinition(),
                lexeme.getShortDefinition());
    }

    private void saveTranslationEvent(
            UserAccount user,
            String sourceLang,
            String targetLang,
            String provider,
            String sourceTextHash,
            int sourceTextLength,
            boolean success,
            String errorCode) {
        translationEventRepository().saveAndFlush(new TranslationEvent(
                user,
                TranslationRequestType.WORD_LOOKUP,
                sourceLang,
                targetLang,
                provider,
                sourceTextHash,
                sourceTextLength,
                success,
                errorCode));
    }

    private UserAccountRepository userAccountRepository() {
        return userAccountRepositoryProvider.getIfAvailable(() -> {
            throw new IllegalStateException("UserAccountRepository is required for lookup");
        });
    }

    private LexemeRepository lexemeRepository() {
        return lexemeRepositoryProvider.getIfAvailable(() -> {
            throw new IllegalStateException("LexemeRepository is required for lookup");
        });
    }

    private TranslationEventRepository translationEventRepository() {
        return translationEventRepositoryProvider.getIfAvailable(() -> {
            throw new IllegalStateException("TranslationEventRepository is required for lookup");
        });
    }

    private String sha256Hex(String value) {
        try {
            var digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            var result = new char[digest.length * 2];
            for (var index = 0; index < digest.length; index++) {
                var current = digest[index] & 0xff;
                result[index * 2] = HEX[current >>> 4];
                result[index * 2 + 1] = HEX[current & 0x0f];
            }
            return new String(result);
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to hash lookup text", exception);
        }
    }

    public static class CurrentUserNotFoundException extends RuntimeException {
    }

    public static class UnsupportedLanguagePairException extends RuntimeException {
    }
}
